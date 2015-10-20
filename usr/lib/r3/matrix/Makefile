R3 = ../../rebol/make/r3

matrix.so: matrix.c Makefile
	gcc -I ../../rebol/src/include $< -ldl -lm -lc -o $@ -shared -Wl,--no-undefined

.PHONY: test clean

matrix.c: matrix.reb Makefile ../recode.reb
	$(R3) make-c.reb $$PWD/$< > $@

test: matrix.so
	$(R3) test.reb

clean:
	rm matrix.so matrix.c
