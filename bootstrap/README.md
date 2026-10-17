# Stage 0

This directory is a frozen copy of cprime written in plain C: chibicc
plus the c′ v0.1 patches, before the compiler was ported to c′. Any C
compiler can build it, and it is only used to build the real compiler
(`../*.dcdx`) the first time.

```
stage 0   bootstrap/*.c   built by $(CC)     stage0/cprime
stage 1   *.dcdx          built by stage 0   ./cprime
stage 2   *.dcdx          built by stage 1   stage2/cprime
```

`make fixpoint` compiles the compiler's source with all three stages and
checks that the assembly is identical.

## The one rule

The compiler's source may only use c′ features that **stage 0
understands**. Stage 0 implements c′ v0.1 (see `../SPEC.md`).

To use a new feature in the compiler's own source, first add it to the
compiler without using it, then rebuild stage 0 from a C compiler that
supports it. Since stage 0 can't be regenerated from c′, do this by
applying the same change to `bootstrap/*.c`, which is plain C. Keep
stage 0 changes minimal: it only has to compile `../*.dcdx`.

Don't edit these files for any other reason.
