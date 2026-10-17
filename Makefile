CFLAGS=-std=c11 -g -fno-common -Wall -Wno-switch

SRCS=$(wildcard *.dcdx)
OBJS=$(SRCS:.dcdx=.o)

TEST_SRCS=$(wildcard test/*.c)
TESTS=$(TEST_SRCS:.c=.exe) test/cprime.exe

# cprime is written in c'. It is built in stages:
#
#   stage 0  bootstrap/*.c  built by $(CC)     a frozen C copy of cprime
#   stage 1  *.dcdx         built by stage 0   ./cprime
#   stage 2  *.dcdx         built by stage 1   ./stage2/cprime
#
# `make fixpoint` checks that stage 0, 1 and 2 all compile the
# compiler's own source to identical assembly.

all: cprime

# Stage 0

BOOT_SRCS=$(wildcard bootstrap/*.c)
BOOT_OBJS=$(BOOT_SRCS:bootstrap/%.c=stage0/%.o)

stage0/cprime: $(BOOT_OBJS)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)
	ln -sfn ../include stage0/include

stage0/%.o: bootstrap/%.c bootstrap/chibicc.h
	@mkdir -p stage0
	$(CC) $(CFLAGS) -c -o $@ $<

# Stage 1

cprime: $(OBJS) stage0/cprime
	./stage0/cprime -o $@ $(OBJS) $(LDFLAGS)

$(OBJS): %.o: %.dcdx cprime.h stage0/cprime
	./stage0/cprime -c -o $@ $<

test/%.exe: cprime test/%.c
	./cprime -Iinclude -Itest -c -o test/$*.o test/$*.c
	$(CC) -pthread -o $@ test/$*.o -xc test/common

test/%.exe: cprime test/%.dcdx
	./cprime -Iinclude -Itest -c -o test/$*.o test/$*.dcdx
	$(CC) -pthread -o $@ test/$*.o -xc test/common

test: $(TESTS)
	for i in $^; do echo $$i; ./$$i || exit 1; echo; done
	test/driver.sh ./cprime
	test/cprime-driver.sh ./cprime

test-all: test test-stage2 fixpoint

# Stage 2

stage2/cprime: $(OBJS:%=stage2/%)
	./cprime -o $@ $^ $(LDFLAGS)
	ln -sfn ../include stage2/include

stage2/%.o: cprime %.dcdx cprime.h
	@mkdir -p stage2/test
	./cprime -c -o $(@D)/$*.o $*.dcdx

stage2/test/%.exe: stage2/cprime test/%.c
	mkdir -p stage2/test
	./stage2/cprime -Iinclude -Itest -c -o stage2/test/$*.o test/$*.c
	$(CC) -pthread -o $@ stage2/test/$*.o -xc test/common

stage2/test/%.exe: stage2/cprime test/%.dcdx
	mkdir -p stage2/test
	./stage2/cprime -Iinclude -Itest -c -o stage2/test/$*.o test/$*.dcdx
	$(CC) -pthread -o $@ stage2/test/$*.o -xc test/common

test-stage2: $(TESTS:test/%=stage2/test/%)
	for i in $^; do echo $$i; ./$$i || exit 1; echo; done
	test/driver.sh ./stage2/cprime
	test/cprime-driver.sh ./stage2/cprime

# Fixed point: every stage must compile the compiler identically.

fixpoint: stage0/cprime cprime stage2/cprime
	@mkdir -p tmp-fixpoint
	@# `.file` lines name each stage's own include/ symlink, so skip them.
	@for f in $(SRCS); do \
	  for i in 0 1 2; do \
	    cc=./stage$$i/cprime; [ $$i = 1 ] && cc=./cprime; \
	    $$cc -S -o - $$f | grep -v '^  \.file ' > tmp-fixpoint/$$f.$$i.s || exit 1; \
	  done; \
	  cmp -s tmp-fixpoint/$$f.0.s tmp-fixpoint/$$f.1.s && \
	  cmp -s tmp-fixpoint/$$f.1.s tmp-fixpoint/$$f.2.s && \
	  echo "fixpoint $$f ... ok" || { echo "fixpoint $$f ... DIFFERS"; exit 1; }; \
	done
	@rm -rf tmp-fixpoint

# Misc.

clean:
	rm -rf cprime tmp* $(TESTS) test/*.s test/*.exe stage0 stage2
	find * -type f '(' -name '*~' -o -name '*.o' ')' -exec rm {} ';'

.PHONY: all test test-all test-stage2 fixpoint clean
