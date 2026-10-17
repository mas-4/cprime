# c′ (c-prime)

The derivative of C: C plus the smallest possible class implementation.

```c
struct Rect {
  int w, h;
  int area(void);
};

int Rect.area(void) { return ego.w * ego.h; }

int main(void) {
  struct Rect r = {3, 4}, *p = &r;
  return r.area() + p.area();   // `.` and `->` are interchangeable
}
```

- Structs can declare methods. The receiver is `ego`, and members are
  always accessed explicitly as `ego.x`.
- `.` and `->` are interchangeable and dereference one level of pointer.
- A method is a plain C function: `Rect.area` is `Rect__area(struct Rect *ego)`,
  so c′ and C link together freely.

c′ files use `.dcdx` (dc/dx, the derivative of C) or `.cpr`. See
[SPEC.md](SPEC.md) for the full language.

## Build

c′ is a fork of [chibicc](https://github.com/rui314/chibicc) and targets
x86-64 Linux. The compiler is **written in c′** and builds itself:

```sh
make            # stage 0 (C, built by cc) builds ./cprime from the c′ source
make test       # C and c′ test suites
make test-all   # also builds stage 2 with ./cprime, reruns the tests,
                # and checks all three stages compile the compiler identically
```

```sh
./cprime -o shapes examples/shapes.dcdx && ./shapes
```

`cprime` is also a working C compiler: `.c` files are compiled as plain C.
c′ is a strict superset of C, so any C file can be renamed to `.dcdx` and
still compile with the same meaning.

See [bootstrap/README.md](bootstrap/README.md) for how the bootstrap works.

## Install

```sh
sudo make install                 # /usr/local/bin/cprime
make install PREFIX=~/.local      # ~/.local/bin/cprime, no sudo
```

This installs the `cprime` binary and its headers (in `lib/cprime/include`
under the prefix). `make uninstall` with the same `PREFIX` removes them.
Packagers can set `DESTDIR`. The binary finds its headers relative to
itself, so an installed prefix can be moved, and symlinking `./cprime`
from a checkout into your `PATH` works too.

## Where the code is

The compiler's source is c′: `Token`, `Type`, `HashMap` and
`StringArray` have methods (`tok.equal("(")`, `ty.is_integer()`,
`map.get(key)`), and the code uses `.` for every member access.

- `parse.dcdx`: method declarations (`struct_members`, `declare_methods`),
  definitions (`method`), calls (`method_call`) and `.`/`->` (`postfix`).
  The c′ language features are tagged `[c']`.
- `main.dcdx`: file extensions, `-x cprime` and `__CPRIME__`.
- `test/cprime.dcdx` and `test/cprime-driver.sh`: the c′ tests.
- `bootstrap/`: stage 0, a frozen C copy of the compiler.

## Written in c′

- cprime itself.
- [skyblue](https://github.com/mas-4/skyblue), a static site generator
  structured like a small compiler (lexer, parser, renderer).

The original chibicc README is in [README.chibicc.md](README.chibicc.md).
chibicc is MIT-licensed; see [LICENSE](LICENSE).
