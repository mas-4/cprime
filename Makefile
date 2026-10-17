CFLAGS=-std=c11 -g -fno-common -Wall -Wno-switch

SRCS=$(wildcard *.c)
OBJS=$(SRCS:.c=.o)

TEST_SRCS=$(wildcard test/*.c)
TESTS=$(TEST_SRCS:.c=.exe) test/cprime.exe

# Stage 1

cprime: $(OBJS)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

$(OBJS): chibicc.h

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

test-all: test test-stage2

# Stage 2

stage2/cprime: $(OBJS:%=stage2/%)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

stage2/%.o: cprime %.c
	mkdir -p stage2/test
	./cprime -c -o $(@D)/$*.o $*.c

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

# Misc.

clean:
	rm -rf cprime tmp* $(TESTS) test/*.s test/*.exe stage2
	find * -type f '(' -name '*~' -o -name '*.o' ')' -exec rm {} ';'

.PHONY: test clean test-stage2
