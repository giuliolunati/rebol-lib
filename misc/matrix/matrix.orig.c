#include <stdio.h>
#include "sys-core.h"
#include "reb-ext.h"
#include "reb-lib.h"

const char *init_block =
"REBOL [\n"
	"Title: {Linear Algebra Extension Module}\n"
	"Name: matrix\n"
	"Type: module\n"
	"Exports: [transpose lq qr]\n"
"]\n"
"transpose: command [" // 0
	"m [vector!]"
"]"
"lq: command [" // 1
	"{Transform M to lower triangular form by right multiplication with orthogonal matrix. Q is also multiplied.}"
	"M [vector!]"
	"Q [vector!]"
"]"

"qr: func ["
		"{Transform M to upper triangular form by left multiplication with orthogonal matrix. Q is also multiplied.}"
		"M [vector!] "
		"Q [vector!] "
	"]["
	"transpose M transpose Q "
	"lq M Q "
	"transpose M transpose Q "
"]"

;
RL_LIB *RL = NULL;
RXIEXT const char *RX_Init(int opts, RL_LIB *lib) {
	RL = lib;
	if (!CHECK_STRUCT_ALIGN) {
		printf ( "CHECK_STRUCT_ALIGN failed\n" );
		return 0;
	}
	return init_block;
}

#define BUF_LEN 1024
REBYTE buf[BUF_LEN];

void memrot(REBYTE *start, REBCNT len, REBINT shift) {
	REBYTE *to, *p;
	REBINT c, l, r;

	if(shift == 0 || len == 0) return;

	while (1) {
		c = abs(shift) % len;
		if (c == 0) return;
		if (c + c < len) shift = (shift > 0 ? c : -c);
		else {
			c = len - c;
			shift = (shift > 0 ? -c : c);
		}
		if (c <= BUF_LEN) {
			if (shift < 0) {
				memcpy(buf, start + len - c, c);
				memmove(start + c, start, len - c);
				memcpy(start, buf, c);
			} else { // shift > 0
				memcpy(buf, start, c);
				memmove(start, start + c, len - c);
				memcpy(start + len - c, buf, c);
			}
			return;
		}
		l = BUF_LEN;
		r = len % c;

		if (shift < 0) {
			p = start;
			while (c > 0) {
				if (c < l) l = c;
				memcpy(buf, start + len - c, l);
				for (to = start + len - c; to + shift >= p; to += shift) {
					memcpy(to, to + shift, l);
				}
				memcpy(to, buf, l);
				c -= l; p+=l;
			}
			if (r == 0) return;
			len = r - shift;
		} else { // shift > 0
			p = start + len;
			while (c > 0) {
				if (c < l) l = c;
				memcpy(buf, start + c - l , l);
				for (to = start + c - l; to + shift + l <= p; to += shift) {
					memcpy(to, to + shift, l);
				}
				memcpy(to, buf, l);
				c -= l; p -= l;
			}
			if (r == 0) return;
			start += len - shift -r; len = shift + r;
		}
	}
}

void merge_rows(REBYTE *start, REBINT x1, REBINT x2, REBINT y0) {
	REBINT y1, y2;

	if (y0 < 2) return;
	y1 = floor(y0 / 2);
	y2 = y0 - y1;

	memrot( start + x1 * y1,
			x1 * y2 + x2 * y1,
			x1 * y2
	);
	merge_rows(start, x1, x2, y1);
	merge_rows(start + (x1 + x2) * y1, x1, x2, y2);
}

void split_rows(REBYTE *start, REBINT x1, REBINT x2, REBINT y0) {
	REBINT y1, y2;

	if (y0 < 2) return;
	y1 = floor(y0 / 2);
	y2 = y0 - y1;

	split_rows(start, x1, x2, y1);
	split_rows(start + (x1 + x2) * y1, x1, x2, y2);
	memrot( start + x1 * y1,
			x1 * y2 + x2 * y1,
			x2 * y1
	);
}

void transpose(REBYTE *start, REBINT x, REBINT y, REBINT z) {
	REBINT i, j, r;
	REBYTE *a, *b;

	if (x == 1 || y == 1) return;
	if (x < y) {
		r = y % x;
		for (i = r; i < y; i += x) {
			transpose(start + i * x * z, x, x, z);
		}
		transpose(start + r * x * z, x, (y - r) / x, z * x);
		if (r > 0) {
			transpose(start, x, r, z);
			merge_rows(start, r * z, (y - r) * z, x);
		}
		return;
	} else if (y < x) {
		r = x % y;
		if (r > 0) {
			split_rows(start, r * z, (x - r) * z, y);
			transpose(start, r, y, z);
		}
		transpose(start + r * y * z , (x - r) / y, y, z * y);
		for (i = r; i < x; i += y) {
			transpose(start + i * y * z, y, y, z);
		}
		return;
	} else { // x0 == y0
		for (i = 0; i < x - 1; i++) {
			for (j = i + 1; j < y; j++) {
				a = start + (j * x + i) * z;
				b = start + (i * x + j) * z;
				r = z;
				while (r > BUF_LEN) {
					memcpy(buf, a, BUF_LEN);
					memcpy(a, b, BUF_LEN);
					memcpy(b, buf, BUF_LEN);
					a += BUF_LEN;
					b += BUF_LEN;
					r -= BUF_LEN;
				}
				memcpy(buf, a, r);
				memcpy(a, b, r);
				memcpy(b, buf, r);
			}
		}
	}
	return;
}

REBDEC norm(REBDEC *data, REBINT start, REBINT end, REBINT step) {
	REBDEC v, t = 0;
	REBINT i;
	for (i = start; i < end; i += step) t += data[i] * data[i];
	return sqrt(t);
}

void *reflect_matrix(REBSER *mser, REBCNT im, REBDEC *v, REBCNT iv,  REBCNT mode)
/*
**		Apply to mser reflection of versor v.
**		- to cols (left mul) mode = 1
**		- to rows (right mul) mode = 2
**		- to both (2-side mul) mode = 3
**		im: 1st nonzero col/row of mser
**		iv: 1st nonzero entry of v
**		Modify mser in place.
*/
{
	REBCNT rows = VECT_ROWS(mser);
	REBCNT cols = mser->tail / rows;
	REBCNT x, y;
	REBDEC t, *m;
	m = (REBDEC*) mser->data;

	if (mode != 2) { // left mul
		for (x = im; x < cols; x++) {
			t = 0;
			for (y = iv; y < rows; y++) {
				t += m[x + cols * y] * v[y];
			}
			t *= 2;
			for (y = iv; y < rows; y++) {
				m[x + cols * y] -= t * v[y];
			}
		}
	}
	if (mode != 1) { // right mul
		for (y = im; y < rows; y++) {
			t = 0;
			for (x = iv; x < cols; x++) {
				t += m[x + cols * y] * v[x];
			}
			t *= 2;
			for (x = iv; x < cols; x++) {
				m[x + cols * y] -= t * v[x];
			}
		}
	}
}

REBDEC precision() {
	REBDEC p = 0.5;
	while (1 + p > 1) p /= 2;
	return p;
}

REBSER *lower_triangular_matrix(REBSER *mser, REBSER *qser)
/*
**		Tranform matrix M to lower triangular L:  M = Lq
**		Modify M in place.
**		Return orthogonal transform matrix q.
*/
{
#define M(x,y) m[(x)+cols*(y)]
	REBCNT rows = VECT_ROWS(mser);
	REBCNT cols = mser->tail / rows;
	REBCNT d = 0; // subdiagonal
	REBCNT i, x, y;
	REBDEC t, v, *m, *q, *u, eps = 10 * precision();

	m = (REBDEC*)mser->data;
	u = (REBDEC*)malloc(cols * sizeof(REBDEC));
	if (rows != VECT_ROWS(qser)) return;
	q = (REBDEC*)qser->data;

	for (x = 0; x < cols && x < rows; x++) {
		if (x + d < cols) {
			t = norm(m, x + d + cols * x, cols * (x + 1), 1);
			if (t > x * eps * norm(m, x * cols, cols * (x + 1), 1)) {
				u[x + d] = M(x + d, x) - t;
				for (y = x + d + 1; y < cols; y++) u[y] = M(y, x);
				v = norm(u, x + d, cols, 1);
				if (v > 0) {
					for (y = x + d; y < cols; y++) u[y] /= v;
					reflect_matrix(qser, 0, u, x + d, 2);
					reflect_matrix(mser, x + 1, u, x + d, 2);
				}
				for (i = x + d + 1; i < cols; i++) M(i, x) = 0;
				M(x + d, x) = t;
			} else {
				for (i = x + d + 1; i < cols; i++) M(i, x) = 0;
				M(x + d, x) = 0;
				d--;
			}
		}
	}
	if(u) free(u); u=NULL;
	return qser;
#undef M
}

RXIEXT int RX_Call(int cmd, RXIFRM *frm, void *data){
switch (cmd) {
case 0: { // transpose
	REBSER *m = RXA_SERIES(frm,1);
	REBINT x, y, z;
	y = VECT_ROWS(m);
	x = m->tail / y;
	z = VECT_TYPE(m) & 3;
	switch (z) {
		case 0: z = 1; break;
		case 1: z = 2; break;
		case 2: z = 4; break;
		case 3: z = 8; break;
	}
	transpose(m->data, x, y, z);
	m->size = (m->size & 0xFF) | x << 8; 
	break; }
case 1: { // lq
	REBSER *m = RXA_SERIES(frm,1);
	REBSER *q = RXA_SERIES(frm,2);
	lower_triangular_matrix(m,q);
	break; }
default: return RXR_NO_COMMAND;
}};
