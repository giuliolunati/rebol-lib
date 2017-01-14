#include <stdio.h>
#include "sys-core.h"
#include "reb-ext.h"
#include "reb-lib.h"

#define BUF_LEN 1024
REBYTE buf[BUF_LEN];
void memrot(REBYTE *start, REBCNT len, REBINT shift) {
	REBYTE *to, *p;
	REBINT c, l, r;
	if (((shift == 0) || (len == 0))) return ;
	while (1) {
		c = (abs(shift) % len);
		if ((c == 0)) return ;
		if (((c + c) < len)) shift = ((shift > 0) ? c : -c); else  {
			c = (len - c);
			shift = ((shift > 0) ? -c : c);
		}
		if ((c <= BUF_LEN))  {
			if ((shift < 0))  {
				memcpy(buf, ((start + len) - c), c);
				memmove((start + c), start, (len - c));
				memcpy(start, buf, c);
			} else  {
				memcpy(buf, start, c);
				memmove(start, (start + c), (len - c));
				memcpy(((start + len) - c), buf, c);
			}
			return ;
		}
		l = BUF_LEN;
		r = (len % c);
		if ((shift < 0))  {
			p = start;
			while ((c > 0)) {
				if ((c < l)) l = c;
				memcpy(buf, ((start + len) - c), l);
				for (to = ((start + len) - c); ((to + shift) >= p); to += shift) memcpy(to, (to + shift), l);
				memcpy(to, buf, l);
				c -= l;
				p += l;
			}
			if ((r == 0)) return ;
			len = (r - shift);
		} else  {
			p = (start + len);
			while ((c > 0)) {
				if ((c < l)) l = c;
				memcpy(buf, ((start + c) - l), l);
				for (to = ((start + c) - l); (((to + shift) + l) <= p); to += shift) memcpy(to, (to + shift), l);
				memcpy(to, buf, l);
				c -= l;
				p -= l;
			}
			if ((r == 0)) return ;
			start += ((len - shift) - r);
			len = (shift + r);
		}
	}
}

void merge_rows(REBYTE *start, REBINT x1, REBINT x2, REBINT y0) {
	REBINT y1, y2;
	if ((y0 < 2)) return ;
	y1 = floor((y0 / 2));
	y2 = (y0 - y1);
	memrot(((x1 * y1) + start), ((x1 * y2) + (x2 * y1)), (x1 * y2));
	merge_rows(start, x1, x2, y1);
	merge_rows((((x1 + x2) * y1) + start), x1, x2, y2);
}

void split_rows(REBYTE *start, REBINT x1, REBINT x2, REBINT y0) {
	REBINT y1, y2;
	if ((y0 < 2)) return ;
	y1 = floor((y0 / 2));
	y2 = (y0 - y1);
	split_rows(start, x1, x2, y1);
	split_rows((((x1 + x2) * y1) + start), x1, x2, y2);
	memrot(((x1 * y1) + start), ((x1 * y2) + (x2 * y1)), (x2 * y1));
}

void transpose(REBYTE *start, REBINT x, REBINT y, REBINT z) {
	REBINT i, j, r;
	REBYTE *a, *b;
	if (((x == 1) || (y == 1))) return ;
	if ((x < y))  {
		r = (y % x);
		for (i = r; (i < y); i += x)  {
			transpose((((i * x) * z) + start), x, x, z);
		}
		transpose((((r * x) * z) + start), x, ((y - r) / x), (z * x));
		if ((r > 0))  {
			transpose(start, x, r, z);
			merge_rows(start, (r * z), ((y - r) * z), x);
		}
		return ;
	} else if ((y < x))  {
		r = (x % y);
		if ((r > 0))  {
			split_rows(start, (r * z), ((x - r) * z), y);
			transpose(start, r, y, z);
		}
		transpose((((r * y) * z) + start), ((x - r) / y), y, (z * y));
		for (i = r; (i < x); i += y)  {
			transpose((((i * y) * z) + start), y, y, z);
		}
		return ;
	} else  {
		for (i = 0; i < (x - 1); i++)  {
			for (j = (i + 1); (j < y); j++)  {
				a = ((((j * x) + i) * z) + start);
				b = ((((i * x) + j) * z) + start);
				r = z;
				while ((r > BUF_LEN)) {
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
	return ;
}

REBDEC norm(REBDEC *data, REBINT start, REBINT end, REBINT step) {
	REBDEC v, t = 0;
	REBINT i;
	for (i = start; (i < end); i += step) t += (data[i] * data[i]);
	return sqrt(t);
}

void *reflect_matrix(REBSER *mser, REBCNT im, REBDEC *v, REBCNT iv, REBCNT mode) {
	REBCNT rows = VECT_ROWS(mser);
	REBCNT cols = (mser->tail / rows);
	REBCNT x, y;
	REBDEC t, *m;
	m = (REBDEC*)(mser->data);
	if ((mode != 2))  {
		for (x = im; (x < cols); x++)  {
			t = 0;
			for (y = iv; (y < rows); y++)  {
				t += (m[cols * y + x] * v[y]);
			}
			t *= 2;
			for (y = iv; (y < rows); y++)  {
				m[cols * y + x] -= (t * v[y]);
			}
		}
	}
	if ((mode != 1))  {
		for (y = im; (y < rows); y++)  {
			t = 0;
			for (x = iv; (x < cols); x++)  {
				t += (m[cols * y + x] * v[x]);
			}
			t *= 2;
			for (x = iv; (x < cols); x++)  {
				m[cols * y + x] -= (t * v[x]);
			}
		}
	}
}

REBDEC precision() {
	REBDEC p = 0.5;
	while (((1 + p) > 1))p /= 2;
	return p;
}

REBSER* hessenberg_matrix(REBSER *M, REBSER *Q, REBCNT symm) {
	REBCNT rows = VECT_ROWS(M);
	REBCNT cols = (M->tail / rows);
	REBCNT d = 0;
	REBCNT x, y;
	REBDEC t, u, *m, *q, *v;
	if ((cols != rows)) return NULL;
	d = 1;
	m = (REBDEC*)(M->data);
	v = (REBDEC*)(malloc(cols));
	if ((VECT_ROWS(Q) != rows)) return NULL;
	q = (REBDEC*)(Q->data);
#define m(x, y) m[(x)+cols*(y)]
	for (x = 0; x < cols; x++)  {
		if (((x + d) < (cols - 1)))  {
			u = norm(m, (((cols * x) + x) + d), ((x + 1) * cols), 1);
			v[x + d] = (m((x + d), x) - u);
			for (y = ((x + d) + 1); (y < cols); y++) v[y] = m(y, x);
			t = norm(v, (x + d), cols, 1);
			if ((t > 0))  {
				for (y = (x + d); (y < cols); y++) v[y] /= t;
				reflect_matrix(Q, 0, v, (x + d), 1);
				if (symm) reflect_matrix(M, x, v, (x + d), 3); else  {
					reflect_matrix(M, (x + 1), v, (x + d), 2);
					reflect_matrix(M, 0, v, (x + d), 1);
				}
			}
			m((x + d), x) = u;
			for (y = ((x + d) + 1); (y < cols); y++) m(y, x) = 0;
		}
	}
#undef m
	return Q;
}

REBSER* diagonalize_matrix(REBSER *M, REBSER *Q, REBCNT symm) {
	REBINT dims = (M->tail / VECT_ROWS(M));
	REBINT i, j, k, cols;
	REBDEC a, b, t, u, *m, *q, *v, c, s, r, z, eps = (10 * precision());
	if ((hessenberg_matrix(M, Q, 1) == NULL)) return NULL;
	m = (REBDEC*)(M->data);
	q = (REBDEC*)(Q->data);
#define m(x, y) m[(x) + dims * (y)]
#define q(x, y) q[(x) + dims * (y)]
	k = (dims - 1);
	while (1)  {
		while ((k > 0)) {
			if (((fabs(m(k, k)) * eps) <= fabs(m((k - 1), k))) && ((fabs(m((k - 1), (k - 1))) * eps) <= fabs(m((k - 1), k))))  {
				break;
			}
			k--;
		}
		if ((k == 0))  {
			break;
		}
		t = m(k, k);
		for (i = 0; i < (k + 1); i++)  {
			m(i, i) = (m(i, i) - t);
		}
		for (i = 0; i < k; i++)  {
			c = m(i, i);
			s = m(i, (i + 1));
			r = sqrt(((c * c) + (s * s)));
			if ((r == 0)) continue;
			c = (c / r);
			s = (s / r);
			for (j = 0; j < dims; j++)  {
				a = q(j, i);
				b = q(j, (i + 1));
				q(j, i) = ((a * c) + (b * s));
				q(j, (i + 1)) = ((a * s) - (b * c));
			}
			if ((i > 0))  {
				m((i - 1), i) = ((m((i - 1), i) * c) + (z * s));
			}
			a = m(i, (i + 1));
			b = m((i + 1), (i + 1));
			m(i, (i + 1)) = ((a * c) + (b * s));
			m((i + 1), (i + 1)) = ((a * s) - (b * c));
			if (((i + 2) <= k))  {
				b = m((i + 1), (i + 2));
				z = (b * s);
				m((i + 1), (i + 2)) = ((0 - b) * c);
			}
			b = m(i, (i + 1));
			m(i, i) = ((r * c) + (b * s));
			m(i, (i + 1)) = ((r * s) - (b * c));
			m((i + 1), (i + 1)) = ((0 - m((i + 1), (i + 1))) * c);
		}
		for (i = 0; i < (k + 1); i++)  {
			m(i, i) = (m(i, i) + t);
		}
	}
	for (i = 0; i < dims; i++)  {
		m((i + 1), i) = m(i, (i + 1));
	}
#undef m
#undef q
	return Q;
}

REBSER *lower_triangular_matrix(REBSER *mser, REBSER *qser) {
#define M(x, y) m[(x)+cols*(y)]
	REBCNT rows = VECT_ROWS(mser);
	REBCNT cols = (mser->tail / rows);
	REBCNT d = 0;
	REBCNT i, x, y;
	REBDEC t, v, *m, *q, *u, eps = (10 * precision());
	m = (REBDEC*)(mser->data);
	u = (REBDEC*)(malloc((cols * sizeof(REBDEC))));
	if ((rows != VECT_ROWS(qser))) return ;
	q = (REBDEC*)(qser->data);
	for (x = 0; ((x < cols) && (x < rows)); x++)  {
		if (((x + d) < cols))  {
			t = norm(m, (((cols * x) + x) + d), ((x + 1) * cols), 1);
			if ((((x * eps) * norm(m, (x * cols), ((x + 1) * cols), 1)) < t))  {
				u[x + d] = (M((x + d), x) - t);
				for (y = ((x + d) + 1); (y < cols); y++) u[y] = M(y, x);
				v = norm(u, (x + d), cols, 1);
				if ((v > 0))  {
					for (y = (x + d); (y < cols); y++) u[y] /= v;
					reflect_matrix(qser, 0, u, (x + d), 2);
					reflect_matrix(mser, (x + 1), u, (x + d), 2);
				}
				for (i = ((x + d) + 1); (i < cols); i++) M(i, x) = 0;
				M((x + d), x) = t;
			} else  {
				for (i = ((x + d) + 1); (i < cols); i++) M(i, x) = 0;
				M((x + d), x) = 0;
				d--;
			}
		}
	}
	if (u) free(u);
	u = NULL;
	return qser;
#undef M
}


const char *init_block =
"REBOL [\n"
"    Title: \"Linear Algebra Extension Module\"\n"
"    Name: matrix\n"
"    Type: module\n"
"    Exports: [interpolation hessenberg transpose lq qr linsolve diagonalize]\n"
"]\n"
"transpose: command [\n"
"    m [vector!]\n"
"]\n"
"lq: command [\n"
"    {Transform M to lower triangular form by right multiplication with orthogonal matrix. Q is also multiplied.}\n"
"    M [vector!]\n"
"    Q [vector!]\n"
"]\n"
"qr: func [\n"
"    {Transform M to upper triangular form by left multiplication with orthogonal matrix. Q is also multiplied, and returned.}\n"
"    M [vector!]\n"
"    Q [vector!]\n"
"] [\n"
"    transpose M transpose Q\n"
"    lq M Q\n"
"    transpose M transpose Q\n"
"    Q\n"
"]\n"
"hessenberg: command [\n"
"    M [vector!] Q [vector!]\n"
"]\n"
"diagonalize: command [\n"
"    {Transform a symmetric matrix M to diagonal form D = qMq' q is orthogonal Modify M in Q place: M => D, Q => qQ Return modified Q.}\n"
"    M [vector!] Q [vector!]\n"
"]\n"
"linsolve: function [\n"
"    {Solves A * x = B. If over-determinated, solves min-squares problem. If under-determinated, returns the min-norm solution. NOTE: modify A and B.}\n"
"    A B\n"
"    /t \"Solves x * A = B, that is A/t * x/t = B/t\"\n"
"] [\n"
"    s: make vector! reduce ['decimal! 64\n"
"        either t [[A/y B/y]] [[B/x A/x]]\n"
"    ]\n"
"    unless t [transpose A transpose B]\n"
"    lq A B\n"
"    for x (min A/x A/y) 1 -1 [\n"
"        for i x A/y 1 [\n"
"            if A/([x i]) = 0 [continue]\n"
"            for y 1 B/y 1 [\n"
"                t: B/([x y])\n"
"                for j (i + 1) A/y 1 [\n"
"                    t: t - (A/([x j])\n"
"                        * s/(either t [[j y]] [[y j]])\n"
"                    )\n"
"                ]\n"
"                s/(either t [[i y]] [[y i]]): t / A/([x i])\n"
"            ]\n"
"            break\n"
"        ]\n"
"    ]\n"
"    s\n"
"]\n"
"interpolate: function [\n"
"    {Interpolates data with a linear combination of functions. Retutns coefficients.\n"
"^-^-Example: linear regression:\n"
"^-^-data: [[x0 y0] ...] functions: [ 1 [x]] }\n"
"    data [block!] {Each data is a number y or a couple [x y] or a triple [x y weight]}\n"
"    functions [block!] \"Each term is a 1-ary function or a block\"\n"
"] [\n"
"    A: make vector! [decimal! 64 [length? functions length? data]]\n"
"    B: make vector! reduce ['decimal! 64 [1 length? data]]\n"
"    forall functions [\n"
"        if block? functions/1 [functions/1: function [x] functions/1]\n"
"    ]\n"
"    forall data [\n"
"        i: index? data\n"
"        case [\n"
"            number? data/1 [x: i y: data/1 w: 1]\n"
"            2 = length? data/1 [x: data/1/1 y: data/1/2 w: 1]\n"
"            true [set [x y w] data/1]\n"
"        ]\n"
"        B/(i): y\n"
"        repeat j A/x [A/([j i]): functions/(j) x]\n"
"    ]\n"
"    print A\n"
"    print B\n"
"    linsolve A B\n"
"]";
RXIEXT const char *RX_Init(int opts, RL_LIB *lib) {
		RL = lib;
		if (!CHECK_STRUCT_ALIGN) {
			printf ( "CHECK_STRUCT_ALIGN failed\n" );
			return 0;
		}
		return init_block;
}
RL_LIB *RL = NULL;
RXIEXT int RX_Call(int cmd, RXIFRM *frm, void *data){
switch (cmd) {
case 0: { // transpose
	REBSER *m;
	m = RXA_SERIES(frm, 1);
	REBINT x, y, z;
	y = VECT_ROWS(m);
	x = (m->tail / y);
	z = (VECT_TYPE(m) & 3);
	switch (z) {
	case 0 :
		z = 1;
		break;
	case 1 :
		z = 2;
		break;
	case 2 :
		z = 4;
		break;
	case 3 :
		z = 8;
		break;
	}

	transpose(m->data, x, y, z);
	m->size = ((x << 8) | (m->size & 255));
	break;
}
case 1: { // lq
	REBSER *m = RXA_SERIES(frm, 1);
	REBSER *q = RXA_SERIES(frm, 2);
	lower_triangular_matrix(m, q);
	RXA_SERIES(frm, 1) = q;
	return RXR_VALUE;
	break;
}
case 2: { // hessenberg
	REBSER *m = RXA_SERIES(frm, 1);
	REBSER *q = RXA_SERIES(frm, 2);
	hessenberg_matrix(m, q, 1);
	RXA_SERIES(frm, 1) = q;
	return RXR_VALUE;
	break;
}
case 3: { // diagonalize
	REBSER *m = RXA_SERIES(frm, 1);
	REBSER *q = RXA_SERIES(frm, 2);
	diagonalize_matrix(m, q, 1);
	RXA_SERIES(frm, 1) = q;
	return RXR_VALUE;
	break;
}
default: return RXR_NO_COMMAND;
}};
