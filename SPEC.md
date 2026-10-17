# c′ (c-prime) language specification — v0.1

c′ is C11 plus three things:

1. `.` and `->` are interchangeable.
2. Structs can declare **methods**.
3. Inside a method, **`ego`** is a pointer to the receiver.

That's the whole language. Everything else is C as implemented by
chibicc (C11 plus common GNU extensions).

## Source files

| Extension | Meaning |
|---|---|
| `.dcdx` | c′ source (canonical: c′ = dc/dx) |
| `.cpr` | c′ source (alias) |
| `.c` | plain C; c′ features are rejected |

`-x cprime` forces c′ mode, for example for stdin. When compiling c′,
the preprocessor defines `__CPRIME__` to `1`.

c′ has no header extension. Headers are `.h`, and the language they're
parsed as is the language of the file that includes them. A header
shared with plain C can guard method declarations with
`#ifdef __CPRIME__`. Methods don't affect struct layout, so both
languages see the same struct.

## 1. `.` and `->`

`a.b` and `a->b` mean the same thing:

- If `a` is a struct or union, access member `b` of it.
- If `a` is a pointer to (or an array of) a struct or union,
  dereference it once, then access `b`.

Dereferencing is exactly **one level**. If `pp` is `struct S **`,
`pp.x` is an error.

## 2. Methods

### Declaration

A function declarator inside a struct declares a method:

```c
struct Vec {
  float x, y;
  float len(void);
  void scale(float k);
  static inline float dot(struct Vec *o);
};
```

- Methods take no space and don't affect layout or `sizeof`.
- A struct with methods must have a tag and be declared at file scope.
- Unions can't have methods.
- A method can't share a name with a field, and there is no overloading.
- An empty parameter list `()` means `(void)`, as in C23.
- `static` and `inline` on a method declaration apply to the lowered
  function.

### Definition

Methods are defined at file scope with `Tag.name`:

```c
float Vec.len(void) { return sqrtf(ego.x * ego.x + ego.y * ego.y); }
```

- `Tag` can be the struct tag or a typedef name for the struct.
- The signature must match the declaration in the struct.
- A method must be declared in its struct before it's defined.
  `Tag.name(...);` without a body is an error.

### Calls

`x.m(args)` and `x->m(args)` call method `m`. The receiver is passed as
`ego`:

- If `x` is a pointer to the struct, `ego` is `x`.
- If `x` is a struct lvalue (a variable, a member, `*p`, an array
  element or a compound literal), `ego` is `&x`.
- If `x` is a temporary struct (a call's return value, or the result of
  `=` or `?:`), it is stored in a hidden temporary and `ego` points
  there. This allows chains like `s.slice(1, 4).trim().eq(t)`. The
  temporary lives at least until the end of the full expression, as in
  C11; don't keep `ego` past the call.

A method name can only be called, not used as a value. To get a function
pointer, use the lowered name (below).

## 3. `ego`

Inside a method body, `ego` is a `struct Tag *` pointing at the
receiver.

- Members are always reached explicitly with `ego.x`. A bare `x` never
  means `ego.x`.
- `ego` is reserved only inside method bodies, where it can't be used as
  a parameter or local name. Everywhere else it's an ordinary
  identifier, so existing C code that uses `ego` still compiles.

## ABI: lowering to C

Every method is an ordinary C function:

```
Tag.name(T1 a, T2 b) -> R      lowers to      R Tag__name(struct Tag *ego, T1 a, T2 b)
x.name(a, b)                   lowers to      Tag__name(&x, a, b)
```

The symbol always uses the struct **tag**, even when the method is
defined through a typedef name. C code can declare and call `Tag__name`
directly, and c′ object files link with gcc- or clang-compiled C.

Don't name your own C functions `Tag__method` for a struct that has that
method.

## Relationship to C

c′ is a strict superset of C11: every valid C program is a valid c′
program with the same meaning. Each c′ feature is a construct that is a
constraint violation in C (a method declarator in a struct, `.` on a
pointer, `Tag.name` at file scope), and `ego` is only reserved inside
method bodies, which C doesn't have.

## Open questions

- Is `ego` a `struct Tag *const`? (chibicc doesn't enforce `const` at all.)
- A method-value syntax such as `&Vec.len` for taking a method's address.
- Method definitions inside the struct body.
- Static ("class") methods with no `ego`.
- Platforms other than x86-64 Linux, probably through a backend that
  emits C.
