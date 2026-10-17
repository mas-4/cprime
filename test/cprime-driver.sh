#!/bin/bash
# c' tests that need the driver: file extensions, C interop, and
# programs that must be rejected with a specific error.
cprime=$1
tmp=`mktemp -d /tmp/cprime-test-XXXXXX`
trap 'rm -rf $tmp' INT TERM HUP EXIT

check() {
  if [ $? -eq 0 ]; then
    echo "testing $1 ... passed"
  else
    echo "testing $1 ... failed"
    exit 1
  fi
}

# expect_error <name> <message> : compile stdin as c', expect failure
expect_error() {
  cat > $tmp/err.dcdx
  if $cprime -c -o $tmp/err.o $tmp/err.dcdx 2> $tmp/err.txt; then
    echo "testing $1 ... failed (compiled, but should not have)"
    exit 1
  fi
  grep -q "$2" $tmp/err.txt
  check "$1"
}

S='struct S { int x; int get(void); };'

# Extensions: .dcdx is canonical, .cpr is accepted, -x cprime forces it.
echo "$S int S.get(void) { return ego.x; } int main() { struct S s = {3}; return s.get() - 3; }" > $tmp/a.dcdx
$cprime -o $tmp/a $tmp/a.dcdx && $tmp/a
check '.dcdx'

cp $tmp/a.dcdx $tmp/a.cpr
$cprime -o $tmp/a $tmp/a.cpr && $tmp/a
check '.cpr'

$cprime -x cprime -o $tmp/a - < $tmp/a.dcdx && $tmp/a
check '-x cprime'

echo 'int main() { return __CPRIME__; }' > $tmp/m.dcdx
$cprime -o $tmp/m $tmp/m.dcdx; [ $? -eq 0 ] && { $tmp/m; [ $? -eq 1 ]; }
check '__CPRIME__'

# .c files are plain C: c' syntax is rejected and __CPRIME__ is unset.
cp $tmp/a.dcdx $tmp/a.c
! $cprime -c -o $tmp/a.o $tmp/a.c 2> /dev/null
check '.c is plain C'

echo '#ifdef __CPRIME__
#error
#endif' > $tmp/n.c
$cprime -c -o $tmp/n.o $tmp/n.c
check '__CPRIME__ unset in .c'

# C interop: methods are plain C functions named Tag__method.
cat > $tmp/lib.dcdx <<EOF
struct Vec { int x, y; int sum(void); };
int Vec.sum(void) { return ego.x + ego.y; }
EOF
cat > $tmp/main.c <<EOF
struct Vec { int x, y; };
int Vec__sum(struct Vec *v);
int main() { struct Vec v = {2, 3}; return Vec__sum(&v) - 5; }
EOF
$cprime -o $tmp/interop $tmp/lib.dcdx $tmp/main.c && $tmp/interop
check 'C calls c'"'"' method'

# The same object file links with gcc-compiled C.
$cprime -c -o $tmp/lib.o $tmp/lib.dcdx && cc -o $tmp/interop2 $tmp/main.c $tmp/lib.o && $tmp/interop2
check 'gcc links c'"'"' object'

# Errors
echo "$S int S.nope(void) { return 0; }" | expect_error 'undeclared method' 'no such method'
echo "$S long S.get(void) { return 0; }" | expect_error 'mismatched method' 'conflicting types for method'
echo "$S int S.get(void);" | expect_error 'out-of-line decl' 'only be declared inside its struct'
echo 'struct S { int x; int x(void); };' | expect_error 'field/method clash' 'same name as a field'
echo 'struct S { int f(void); int f(void); };' | expect_error 'duplicate method' 'duplicate method'
echo 'struct { int f(void); } s;' | expect_error 'untagged struct' 'must have a tag'
echo 'union U { int f(void); };' | expect_error 'method in union' 'only allowed in structs'
echo 'void g(void) { struct L { int f(void); }; }' | expect_error 'local struct' 'at file scope'
echo "$S int S.get(void) { int ego = 1; return ego; }" | expect_error 'ego shadowed' "'ego' is reserved"
echo 'struct T { int f(int a); }; int T.f(int ego) { return 0; }' | expect_error 'ego param' "'ego' is reserved"
echo "$S int S.get(void) { return x; }" | expect_error 'no implicit ego' 'undefined variable'

# A struct converts only to the same struct, so returning ego (a
# pointer) where the struct is expected is an error, not garbage.
echo 'struct P { int x; struct P self(void); }; struct P P.self(void) { return ego; }' | expect_error 'return ego by value' "pointer to the struct, so it needs a '\*'"
echo 'struct P { int x; struct P self(void); }; struct P P.self(void) { return *ego; }' > $tmp/self.dcdx
$cprime -c -o $tmp/self.o $tmp/self.dcdx
check 'return *ego by value'
echo 'struct A { int x; }; struct B { int x; }; void f(void) { struct A a; struct B b = {1}; a = b; }' | expect_error 'struct assignment' 'incompatible type in assignment'
echo 'struct A { int x; }; void g(struct A a); void f(struct A *p) { g(p); }' | expect_error 'struct argument' 'incompatible type in argument'
echo 'struct A { int x; }; int f(struct A a) { return a; }' | expect_error 'struct to int' 'incompatible type in return'
echo "$S int f(void) { struct S s; return s.get; }" | expect_error 'uncalled method' 'must be called'
echo "$S int f(struct S **pp) { return pp.x; }" | expect_error 'one level of deref' 'not a struct'
echo "$S int f(struct S s) { return s.get(1); }" | expect_error '() means (void)' 'too many arguments'

echo OK
