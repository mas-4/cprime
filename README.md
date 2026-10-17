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
x86-64 Linux.

```sh
make            # builds ./cprime
make test       # C and c′ test suites
make test-all   # also self-hosts and reruns the tests with stage 2
```

```sh
./cprime -o shapes examples/shapes.dcdx && ./shapes
```

`cprime` is also a working C compiler: `.c` files are compiled as plain C.

## Where the code is

Every c′ change is tagged `[c']` in the source:

- `parse.c`: method declarations (`struct_members`, `declare_methods`),
  definitions (`method`), calls (`method_call`) and `.`/`->` (`postfix`).
- `main.c`: file extensions, `-x cprime` and `__CPRIME__`.
- `test/cprime.dcdx` and `test/cprime-driver.sh`: the c′ tests.

The original chibicc README is in [README.chibicc.md](README.chibicc.md).
chibicc is MIT-licensed; see [LICENSE](LICENSE).
