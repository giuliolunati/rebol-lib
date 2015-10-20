#include <stdio.h>
/***********************************************************************
**
**  REBOL [R3] Language Interpreter and Run-time Environment
**
**  Copyright 2012 REBOL Technologies
**  REBOL is a trademark of REBOL Technologies
**
**  Licensed under the Apache License, Version 2.0 (the "License");
**  you may not use this file except in compliance with the License.
**  You may obtain a copy of the License at
**
**  http://www.apache.org/licenses/LICENSE-2.0
**
**  Unless required by applicable law or agreed to in writing, software
**  distributed under the License is distributed on an "AS IS" BASIS,
**  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
**  See the License for the specific language governing permissions and
**  limitations under the License.
**
************************************************************************
**
**  Module:  t-vector.c
**  Summary: vector datatype
**  Section: datatypes
**  Author:  Carl Sassenrath
**  Notes:
**
***********************************************************************/

#include "sys-core.h"

// Encoding Format:
//		stored in series->size for now
//		[d d d d   d d d d   0 0 0 0   t s b b]

// Encoding identifiers:
enum {
	VTSI08 = 0,
	VTSI16,
	VTSI32,
	VTSI64,

	VTUI08,
	VTUI16,
	VTUI32,
	VTUI64,

	VTSF08,		// not used
	VTSF16,		// not used
	VTSF32,
	VTSF64,
};

static REBCNT bit_sizes[4] = {8, 16, 32, 64};

REBU64 f_to_u64(float n) {
	union {
		REBU64 u;
		REBDEC d;
	} t;
	t.d = n;
	return t.u;
}
		
#define BUF_LEN 1024
REBYTE buf[BUF_LEN];

REBU64 get_vect(REBCNT bits, REBYTE *data, REBCNT n)
{
	switch (bits) {
	case VTSI08:
		return (REBI64) ((char*)data)[n];

	case VTSI16:
		return (REBI64) ((short*)data)[n];

	case VTSI32:
		return (REBI64) ((long*)data)[n];

	case VTSI64:
		return (REBI64) ((i64*)data)[n];

	case VTUI08:
		return (REBU64) ((unsigned char*)data)[n];

	case VTUI16:
		return (REBU64) ((unsigned short*)data)[n];

	case VTUI32:
		return (REBU64) ((unsigned long*)data)[n];

	case VTUI64:
		return (REBU64) ((i64*)data)[n];

	case VTSF08:
	case VTSF16:
	case VTSF32:
		return f_to_u64(((float*)data)[n]);
	
	case VTSF64:
		return ((REBU64*)data)[n];
	}

	return 0;
}

void set_vect(REBCNT bits, REBYTE *data, REBCNT n, REBI64 i, REBDEC f) {
	switch (bits) {

	case VTSI08:
		((char*)data)[n] = (char)i;
		break;

	case VTSI16:
		((short*)data)[n] = (short)i;
		break;

	case VTSI32:
		((long*)data)[n] = (long)i;
		break;

	case VTSI64:
		((i64*)data)[n] = (i64)i;
		break;

	case VTUI08:
		((unsigned char*)data)[n] = (unsigned char)i;
		break;

	case VTUI16:
		((unsigned short*)data)[n] = (unsigned short)i;
		break;

	case VTUI32:
		((unsigned long*)data)[n] = (unsigned long)i;
		break;

	case VTUI64:
		((i64*)data)[n] = (u64)i;
		break;

	case VTSF08:
	case VTSF16:
	case VTSF32:
		((float*)data)[n] = (float)f;
		break;

	case VTSF64:
		((double*)data)[n] = f;
		break;
	}
}


void Set_Vector_Row(REBSER *ser, REBVAL *blk)
{
	REBCNT idx = VAL_INDEX(blk);
	REBCNT len = VAL_LEN(blk);
	REBVAL *val;
	REBCNT n = 0;
	REBCNT bits = VECT_TYPE(ser);
	union {REBI64 i; REBDEC d;} v;
	REBI64 i = 0;
	REBDEC f = 0;
	REBSER *src;
	REBCNT srcbits;
	REBCNT rows = VECT_ROWS(ser);

	if (IS_BLOCK(blk)) {
		val = VAL_BLK_DATA(blk);

		for (; NOT_END(val); val++) {
			if (IS_INTEGER(val)) {
				i = VAL_INT64(val);
				if (bits > VTUI64) f = (REBDEC)(i);
			}
			else if (IS_DECIMAL(val)) {
				f = VAL_DECIMAL(val);
				if (bits <= VTUI64) i = (REBINT)(f);
			}
			else Trap_Arg(val);
			set_vect(bits, ser->data, n++, i, f);
			if (n >= ser->tail) break;
		}
	} else if IS_VECTOR(blk) {
		// vector type conversion / crop / extend
		src = VAL_SERIES(blk);
		srcbits = VECT_TYPE(src);
		if (srcbits <= VTUI64) { // from integer
			for (i=VAL_INDEX(blk),n=0;
					i < src->tail;
					i++, n ++) {
				if (n >= ser->tail) break;
				v.i = get_vect(srcbits, src->data, i);
				set_vect(bits, ser->data, n, v.i, (REBDEC)v.i);
			}
		} else { // from decimal
			for (i=VAL_INDEX(blk),n=0;
					i < src->tail;
					i++, n ++) {
				if (n >= ser->tail) break;
				v.i = get_vect(srcbits, src->data, i);
				set_vect(bits, ser->data, n, (REBINT)v.d, v.d);
			}
		}
	} else {
		REBYTE *data = VAL_BIN_DATA(blk);
		for (; len > 0; len--, idx++) {
			set_vect(bits, ser->data, n++, (REBI64)(data[idx]), f);
		}
	}
}


/***********************************************************************
**
*/	REBSER *Make_Vector_Block(REBVAL *vect)
/*
**		Convert a vector to a block.
**
***********************************************************************/
{
	REBCNT len = VAL_LEN(vect);
	REBYTE *data = VAL_SERIES(vect)->data;
	REBCNT type = VECT_TYPE(VAL_SERIES(vect));
	REBSER *ser = Make_Block(len);
	REBCNT n;
	REBVAL *val;

	if (len > 0) {
		val = BLK_HEAD(ser);
		for (n = VAL_INDEX(vect); n < VAL_TAIL(vect); n++, val++) {
			VAL_SET(val, (type >= VTSF08) ? REB_DECIMAL : REB_INTEGER);
			VAL_INT64(val) = get_vect(type, data, n); // can be int or decimal
		}
	}

	SET_END(val);
	ser->tail = len;

	return ser;
}


/***********************************************************************
**
*/	REBINT Compare_Vector(REBVAL *v1, REBVAL *v2)
/*
***********************************************************************/
{
	REBCNT l1 = VAL_LEN(v1);
	REBCNT l2 = VAL_LEN(v2);
	REBCNT len = MIN(l1, l2);
	REBCNT n;
	REBU64 i1;
	REBU64 i2;
	REBYTE *d1 = VAL_SERIES(v1)->data;
	REBYTE *d2 = VAL_SERIES(v2)->data;
	REBCNT b1 = VECT_TYPE(VAL_SERIES(v1));
	REBCNT b2 = VECT_TYPE(VAL_SERIES(v2));

	if (
		(b1 >= VTSF08 && b2 < VTSF08)
		|| (b2 >= VTSF08 && b1 < VTSF08)
	) Trap0(RE_NOT_SAME_TYPE);

	for (n = 0; n < len; n++) {
		i1 = get_vect(b1, d1, n + VAL_INDEX(v1));
		i2 = get_vect(b2, d2, n + VAL_INDEX(v2));
		if (i1 != i2) break;
	}

	if (n != len) {
		if (i1 > i2) return 1;
		return -1;
	}

	return l1 - l2;
}

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

/***********************************************************************
**
*/	void Shift_Vector(REBSER *vect, REBINT shift, REBINT start, REBINT end)
/*
***********************************************************************/
{
	REBINT bytes = VECT_TYPE(vect) & 3;
	switch (bytes) {
		case 0: bytes = 1; break;
		case 1: bytes = 2; break;
		case 2: bytes = 4; break;
		case 3: bytes = 8; break;
	}
	memrot(vect->data + (start - 1) * bytes, (end - start + 1) * bytes, shift * bytes);
}

/***********************************************************************
**
*/	void Shuffle_Vector(REBVAL *vect, REBFLG secure)
/*
***********************************************************************/
{
	REBCNT n;
	REBCNT k;
	REBU64 swap;
	REBYTE *data = VAL_SERIES(vect)->data;
	REBCNT type = VECT_TYPE(VAL_SERIES(vect));
	REBCNT idx = VAL_INDEX(vect);

	// We can do it as INTS, because we just deal with the bits:
	if (type == VTSF32) type = VTUI32;
	else if (type == VTSF64) type = VTUI64;

	for (n = VAL_LEN(vect); n > 1;) {
		k = idx + (REBCNT)Random_Int(secure) % n;
		n--;
		swap = get_vect(type, data, k);
		set_vect(type, data, k, get_vect(type, data, n + idx), 0);
		set_vect(type, data, n + idx, swap, 0);
	}
}

/***********************************************************************
**
*/	REBSER *Transpose_Matrix(REBSER *vect)
/*
***********************************************************************/
{
	REBCNT f, t;
	REBU64 swap;
	REBYTE *data = vect->data;
	REBYTE *to;
	REBCNT type = VECT_TYPE(vect);
	REBCNT rows = VECT_ROWS(vect);
	REBCNT cols = vect->tail / rows;
	REBINT bits = type & 3;
	REBSER *tr;

	switch (bits) {
		case 0: bits =  8; break;
		case 1: bits = 16; break;
		case 2: bits = 32; break;
		case 3: bits = 64; break;
 	}
	tr = Make_Vector(
		(type >> 2) & 1, // unsigned?
		(type >> 3) & 1, // decimal?
		bits, rows, cols
	);
	to = tr->data;

	// We can do it as INTS, because we just deal with the bits:
	if (type == VTSF32) type = VTUI32;
	else if (type == VTSF64) type = VTUI64;
	cols*=rows;
	for (f=t=0; f < vect->tail; f++, t+=rows) {
		if (t>=cols) t+=1-cols;
		set_vect(type, to, t, get_vect(type, data, f), 0);
	}
	return tr;
}

REBDEC norm(REBDEC *data, REBINT start, REBINT end, REBINT step) {
	REBDEC v, t = 0;
	REBINT i;
	for (i = start; i < end; i += step) t += data[i] * data[i];
	return sqrt(t);
}

/***********************************************************************
**
*/	void *Reflect_Matrix(REBSER *mser, REBCNT im, REBSER *vser, REBCNT iv,  REBCNT mode)
/*
**		Apply to mser reflection of versor vser.
**		- to cols (left mul) mode = 1
**		- to rows (right mul) mode = 2
**		- to both (2-side mul) mode = 3
**		im: 1st nonzero col/row of mser
**		iv: 1st nonzero entry of vser
**		Modify mser in place.
**
***********************************************************************/
{
	REBCNT rows = VECT_ROWS(mser);
	REBCNT cols = mser->tail / rows;
	REBCNT x, y;
	REBDEC t, *m, *v;
	m = (REBDEC*) mser->data;
	v = (REBDEC*) vser->data;

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


/***********************************************************************
**
*/	REBSER *Lower_Triangular_Matrix(REBSER *mser, REBSER *qser)
/*
**		Tranform matrix M to lower triangular L:  M = Lq
**		Modify M in place.
**		Return orthogonal transform matrix q.
**
***********************************************************************/
{
#define M(x,y) m[(x)+cols*(y)]
	REBSER *vser;
	REBCNT rows = VECT_ROWS(mser);
	REBCNT cols = mser->tail / rows;
	REBCNT d = 0; // subdiagonal
	REBCNT i, x, y;
	REBDEC t, v, *m, *q, *u, eps = 10 * precision();

	m = (REBDEC*)mser->data;
	vser = Make_Vector(0, 1, 64, cols, 1);
	u = (REBDEC*)vser->data;
	if (qser) {
		if (qser->tail != VECT_ROWS(qser) * cols)
				Trap0(RE_VECTOR_DIMENSION);
		q = (REBDEC*)qser->data;
	} else {
		qser = Make_Vector(0, 1, 64, cols, cols);
		q = (REBDEC*)qser->data;
		for (x = y = 0; x < cols ; x++, y += cols + 1) q[y] = 1.0;
	}

	for (x = 0; x < cols && x < rows; x++) {
		if (x + d < cols) {
			t = norm(m, x + d + cols * x, cols * (x + 1), 1);
			if (t > x * eps * norm(m, x * cols, cols * (x + 1), 1)) {
				u[x + d] = M(x + d, x) - t;
				for (y = x + d + 1; y < cols; y++) u[y] = M(y, x);
				v = norm(u, x + d, cols, 1);
				if (v > 0) {
					for (y = x + d; y < cols; y++) u[y] /= v;
					Reflect_Matrix(qser, 0, vser, x + d, 2);
					Reflect_Matrix(mser, x + 1, vser, x + d, 2);
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
	return qser;
#undef M
}


/***********************************************************************
**
*/	REBSER *Hessenberg_Matrix(REBSER *mser, REBSER *qser, REBCNT symm)
/*
**		Tranform matrix M to:
**		- lower hessenberg H = qMq' (symm = 0)
**		- symm. tridiagonal D = qMq' (symm != 0)
**		Modify M in place.
**		Return orthogonal transform matrix q.
**
***********************************************************************/
{
#define M(x,y) m[(x)+cols*(y)]
	REBSER *vser;
	REBCNT rows = VECT_ROWS(mser);
	REBCNT cols = mser->tail / rows;
	REBCNT d = 0; // subdiagonal
	REBCNT x, y;
	REBDEC t, u, *m, *q, *v;

	if (cols != rows) Trap0(RE_VECTOR_DIMENSION);
	d = 1;
	m = (REBDEC*)mser->data;
	vser = Make_Vector(0, 1, 64, cols, 1);
	v = (REBDEC*)vser->data;
	if (qser) {
		if (VECT_ROWS(qser) != rows)
			Trap0(RE_VECTOR_DIMENSION);
		q = (REBDEC*)qser->data;
	} else {
		qser = Make_Vector(0, 1, 64, cols, cols);
		q = (REBDEC*)qser->data;
		for (x = y = 0; x < cols; x++, y += cols + 1) q[y] = 1.0;
	}
	for (x = 0; x < cols; x++) {
		if (x + d < cols - 1) {
			u = norm(m, x + d + cols * x, cols * (x + 1), 1);
			v[x + d] = M(x + d, x) - u;
			for (y = x + d + 1; y < cols; y++) v[y] = M(y, x);
			t = norm(v, x + d, cols, 1);
			if (t > 0) {
				for (y = x + d; y < cols; y++) v[y] /= t;
				Reflect_Matrix(qser, 0, vser, x + d, 2);
				if (symm)
					Reflect_Matrix(mser, x, vser, x + d, 3);
				else {
					Reflect_Matrix(mser, x + 1, vser, x + d, 2);
					Reflect_Matrix(mser, 0, vser, x + d, 1);
				}
			}
			M(x + d, x) = u;
			for (y = x + d + 1; y < cols; y++) M(y, x) = 0;
		}
	}
	return qser;
#undef M
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

/***********************************************************************
**
*/	void *Transpose_Matrix_In_Place(REBSER *m)
/*
***********************************************************************/
{
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
}


/***********************************************************************
**
*/	void Set_Vector_Value(REBVAL *var, REBSER *series, REBCNT index)
/*
***********************************************************************/
{
	REBYTE *data = series->data;
	REBCNT bits = VECT_TYPE(series);

	var->data.integer = get_vect(bits, data, index);
	if (bits >= VTSF08) SET_TYPE(var, REB_DECIMAL);
	else SET_TYPE(var, REB_INTEGER);
}


/***********************************************************************
**
*/	REBSER *Make_Vector(REBINT sign, REBINT type, REBINT bits, REBINT cols, REBINT rows)
/*
**		type: the datatype
**		sign: signed or unsigned
**		rows: number of dimensions
**		bits: number of bits per unit (8, 16, 32, 64)
**		cols: columns of matrix
**
***********************************************************************/
{
	REBCNT len;
	REBSER *ser;

	len = cols * rows;
	if (len > 0x7fffffff) return 0;
	ser = Make_Series(len+1, bits/8, TRUE); // !!! can width help extend the len?
	LABEL_SERIES(ser, "make vector");
	CLEAR(ser->data, len*bits/8);
	ser->tail = len;  // !!! another way to do it?

	// Store info about the vector (could be moved to flags if necessary):
	switch (bits) {
	case  8: bits = 0; break;
	case 16: bits = 1; break;
	case 32: bits = 2; break;
	case 64: bits = 3; break;
	}
	ser->size = (rows << 8) | (type << 3) | (sign << 2) | bits;

	return ser;
}

/***********************************************************************
**
*/	REBVAL *Make_Vector_Spec(REBVAL *bp, REBVAL *value)
/*
**	Make a vector from a block spec.
**
**     make vector! [integer! 32 100]
**     make vector! [decimal! 64 100]
**     make vector! [unsigned integer! 32]
**     Fields:
**          signed:     signed, unsigned
**    		datatypes:  integer, decimal
**    		dimensions: 1 - N
**    		bitsize:    1, 8, 16, 32, 64
**    		cols:       integer units
**    		init:		block of values
**
***********************************************************************/
{
	REBINT type = -1; // 0 = int,    1 = float
	REBINT sign = -1; // 0 = signed, 1 = unsigned
	REBINT rows = -1;
	REBINT bits = 32;
	REBINT cols = -1;
	REBINT len = -1;
	REBSER *vect;
	REBVAL *iblk = 0;
	REBVAL v;

	// UNSIGNED
	if (IS_WORD(bp) && VAL_WORD_CANON(bp) == SYM_UNSIGNED) { 
		sign = 1;
		bp++;
	}

	// INTEGER! or DECIMAL!
	if (IS_WORD(bp)) {
		if (VAL_WORD_CANON(bp) == (REB_INTEGER+1)) // integer! symbol
			type = 0;
		else if (VAL_WORD_CANON(bp) == (REB_DECIMAL+1)) { // decimal! symbol
			type = 1;
			if (sign > 0) return 0;
		}
		else return 0;
		bp++;
	}

	if (type < 0) type = 0;
	if (sign < 0) sign = 0;

	// BITS
	if (IS_WORD(bp)) v = *Get_Var(bp);
	else v = *bp;
	if (IS_INTEGER(&v)) {
		bits = Int32(&v);
		if (
			(bits == 32 || bits == 64)
			||
			(type == 0 && (bits == 8 || bits == 16))
		) bp++;
		else return 0;
	} else return 0;

	// SIZE
	if (IS_WORD(bp)) v = *Get_Var(bp);
	else v = *bp;
	if (IS_INTEGER(&v)) {
		cols = Int32(&v);
		if (cols < 0) return 0;
		bp++;
	} else {
		if (IS_BLOCK(&v)) {
			Reduce_Block(VAL_SERIES(&v), 0, 0);
			MT_Pair(&v, DS_TOP, REB_PAIR);
			DSP--;
		}
		if (IS_PAIR(&v)) {
			cols = VAL_PAIR_X(&v);
			rows = VAL_PAIR_Y(&v);
			if (cols < 0 || rows < 0) return 0;
			bp++;
		}
	}

	// Initial data:
	if (IS_WORD(bp)) v = *Get_Var(bp);
	else v = *bp;
	if (IS_BLOCK(&v) || IS_VECTOR(&v) || IS_BINARY(&v)) {
		len = VAL_LEN(&v);
		if (IS_BINARY(&v) && type == 1) return 0;
		iblk = &v;
		bp++;
	} else if (IS_VECTOR(value)) len = VAL_LEN(value);

	// Index offset:
	if (IS_INTEGER(&v)) {
		VAL_INDEX(value) = (Int32s(&v, 1) - 1);
		bp++;
	}
	else VAL_INDEX(value) = 0;

	if (NOT_END(bp)) return 0;

	if (cols < 0) cols = (len < 0 ? 0 : len);
	if (len < cols) len = cols;
	if (rows < 0) rows = (len + cols - 1) / cols;
	vect = Make_Vector(sign, type, bits, cols, rows);
	if (!vect) return 0;

	if (iblk) Set_Vector_Row(vect, iblk);
	// conversion: make VECTOR SPEC
	else if (IS_VECTOR(value)) Set_Vector_Row(vect, value);

	SET_TYPE(value, REB_VECTOR);
	VAL_SERIES(value) = vect;
	// index set earlier

	return value;
}


/***********************************************************************
**
*/	REBFLG MT_Vector(REBVAL *out, REBVAL *data, REBCNT type)
/*
***********************************************************************/
{
	if (Make_Vector_Spec(data, out)) return TRUE;
	return FALSE;
}


/***********************************************************************
**
*/	REBINT CT_Vector(REBVAL *a, REBVAL *b, REBINT mode)
/*
***********************************************************************/
{
	REBINT n = Compare_Vector(a, b);  // needs to be expanded for equality
	if (mode >= 0) {
		return n == 0;
	}
	if (mode == -1) return n >= 0;
	return n > 0;
}


/***********************************************************************
**
*/	REBINT PD_Vector(REBPVS *pvs)
/*
***********************************************************************/
{
	REBSER *vect;
	REBINT n;
	REBINT rows;
	REBINT bits;
	REBYTE *vp;
	REBI64 i;
	REBDEC f;
	REBVAL *val, *sel;

	val = pvs->value;
	sel = pvs->select;
	vect = VAL_SERIES(val);

	switch VAL_TYPE(sel) {
	case REB_INTEGER:
	case REB_DECIMAL:
		n = Int32(sel);
		break;
	case REB_BLOCK: // vect/([x y]) , pick vect [x y] 
		Reduce_Block(VAL_SERIES(sel), 0, 0);
		MT_Pair(sel, DS_TOP, REB_PAIR);
		DSP--;
	case REB_PAIR: // vect/2x3
		n = (VAL_PAIR_Y_INT(sel) - 1);
		n	*= vect->tail / VECT_ROWS(vect);
		n	+= VAL_PAIR_X_INT(sel);
		break;
	case REB_WORD:
		switch (VAL_WORD_CANON(sel)) {
			case SYM_SIZE:
				VAL_SET(pvs->store, REB_PAIR);
				VAL_PAIR_X(pvs->store) = vect->tail / VECT_ROWS(vect);
				VAL_PAIR_Y(pvs->store) = VECT_ROWS(vect);
				return PE_USE;
			case SYM_T:
				vect = Transpose_Matrix(vect);
				VAL_SET(pvs->store, REB_VECTOR);
				VAL_SERIES(pvs->store) = vect;
				VAL_INDEX(pvs->store) = 0;
				return PE_USE;
			case SYM_X:
				if (pvs->setval == 0) {
					VAL_SET(pvs->store, REB_INTEGER);
					VAL_INT64(pvs->store) = vect->tail / VECT_ROWS(vect);
					return PE_USE;
				}
				if (IS_INTEGER(pvs->setval)) {
					i = VAL_INT64(pvs->setval);
					if (i <= 0 ) return PE_BAD_SET;
					i = vect->tail / i;
					vect->size = (vect->size & 0xFF) | i << 8; 
					return PE_OK;
				}
				return PE_BAD_SET;
			case SYM_Y:
				if (pvs->setval == 0) {
					VAL_SET(pvs->store, REB_INTEGER);
					VAL_INT64(pvs->store) = VECT_ROWS(vect);
					return PE_USE;
				}
				if (IS_INTEGER(pvs->setval)) {
					i = VAL_INT64(pvs->setval);
					vect->size = (vect->size & 0xFF) | i << 8; 
					return PE_OK;
				}
				return PE_BAD_SET;
		}
	default:
		return PE_BAD_SELECT;
	}

	n += VAL_INDEX(pvs->value);
	vp   = vect->data;
	bits = VECT_TYPE(vect);

	if (pvs->setval == 0) {

		// Check range:
		if (n <= 0 || (REBCNT)n > vect->tail) return PE_NONE;

		// Get element value:
		pvs->store->data.integer = get_vect(bits, vp, n-1); // 64 bits
		if (bits < VTSF08) {
			SET_TYPE(pvs->store, REB_INTEGER);
		} else {
			SET_TYPE(pvs->store, REB_DECIMAL);
		}

		return PE_USE;
	}

	//--- Set Value...
	TRAP_PROTECT(vect);

	if (n <= 0 || (REBCNT)n > vect->tail) return PE_BAD_RANGE;

	if (IS_INTEGER(pvs->setval)) {
		i = VAL_INT64(pvs->setval);
		if (bits > VTUI64) f = (REBDEC)(i);
	}
	else if (IS_DECIMAL(pvs->setval)) {
		f = VAL_DECIMAL(pvs->setval);
		if (bits <= VTUI64) i = (REBINT)(f);
	}
	else return PE_BAD_SET;

	set_vect(bits, vp, n-1, i, f);

	return PE_OK;
}


/***********************************************************************
**
*/	REBTYPE(Vector)
/*
***********************************************************************/
{
	REBVAL *value = D_ARG(1);
	REBVAL *arg = D_ARG(2);
	REBVAL val;
	REBINT type;
	REBCNT cols, rows, cows, i, x, y;
	REBSER *vect;
	REBSER *ser, *ser1, *ser2;
	REBDEC *a, *b, *c, v;

	type = Do_Series_Action(action, value, arg);
	if (type >= 0) return type;

	vect = VAL_SERIES(value); // not valid for MAKE or TO

	// Check must be in this order (to avoid checking a non-series value);
	if (action >= A_TAKE && action <= A_SORT && IS_PROTECT_SERIES(vect))
		Trap0(RE_PROTECTED);

	switch (action) {

	case A_PICK:
		Pick_Path(value, arg, 0);
		return R_TOS;

	case A_POKE:
		Pick_Path(value, arg, D_ARG(3));
		return R_ARG3;

	case A_MAKE:
		// CASE: make vector! 100
		if (IS_INTEGER(arg) || IS_DECIMAL(arg)) {
			cols = Int32s(arg, 0);
			if (cols < 0) goto bad_make;
			ser = Make_Vector(0, 0, 32, cols, 1);
			SET_VECTOR(value, ser);
			break;
		}

	case A_TO:
		// CASE: make vector! [...]
		if (IS_BLOCK(arg) && Make_Vector_Spec(VAL_BLK_DATA(arg), value)) break;
		goto bad_make;

	case A_LENGTHQ:
		//bits = 1 << (vect->size & 3);
		SET_INTEGER(D_RET, vect->tail);
		return R_RET;

	case A_COPY:
		ser = Copy_Series(vect);
		ser->size = vect->size; // attributes
		SET_VECTOR(value, ser);
		break;

	case A_RANDOM:
		if (D_REF(2) || D_REF(4)) Trap0(RE_BAD_REFINES); // /seed /only
		Shuffle_Vector(value, D_REF(3));
		return R_ARG1;

	case A_ADD:
	case A_SUBTRACT:
		if (! IS_VECTOR(arg) && ! IS_INTEGER(arg) && ! IS_DECIMAL(arg)) Trap_Action(VAL_TYPE(value), action);
		if (IS_VECTOR(arg) && (
				VAL_LEN(arg) != VAL_LEN(value)
				|| VAL_ROWS(arg) != VAL_ROWS(value)
		) ) Trap0(RE_VECTOR_DIMENSION);
		rows = VECT_ROWS(vect);
		cols = vect->tail / rows;
		ser = Make_Vector(0, 1, 64, cols, rows);
		Set_Vector_Row(ser, value);
		if (IS_VECTOR(arg)) {
			vect = VAL_SERIES(arg);
			ser2 = Make_Vector(0, 1, 64, vect->tail, 1);
			Set_Vector_Row(ser2, arg);
			if (action == A_ADD) { 
				for (a = (REBDEC*)ser->data, b = (REBDEC*)ser2->data, i=0;
						i < ser->tail && i < ser2->tail;
						i++, a++, b++) {*a += *b;}
			} else if (action == A_SUBTRACT) {
				for (a = (REBDEC*)ser->data, b = (REBDEC*)ser2->data, i=0;
						i < ser->tail && i < ser2->tail;
						i++, a++, b++) {*a -= *b;}
			}
		} else { // arg is number
			if (IS_INTEGER(arg)) v = VAL_INT64(arg);
			else if (IS_DECIMAL(arg)) v = VAL_DECIMAL(arg);
			if (action == A_SUBTRACT) v = -v;
			for (a = (REBDEC*)ser->data, i=0;
					i < rows && i < cols;
					i++, a += cols + 1) *a += v;
		}
		SET_VECTOR(value, ser);
		break;

	case A_MULTIPLY:
		if (! IS_VECTOR(arg) && ! IS_INTEGER(arg) && ! IS_DECIMAL(arg)) Trap_Action(VAL_TYPE(value), action);
		rows = VECT_ROWS(vect);
		cows = vect->tail / rows;
		if (IS_VECTOR(arg)) {
			vect = VAL_SERIES(arg);
			if (cows != (VECT_ROWS(vect))) Trap0(RE_VECTOR_DIMENSION);
			cols = vect->tail / cows;
			ser2 = Make_Vector(0, 1, 64, cols, cows);
			Set_Vector_Row(ser2, arg);
			ser = Make_Vector(0, 1, 64, cols, rows);
		}
		vect = VAL_SERIES(value);
		ser1 = Make_Vector(0, 1, 64, cows, rows);
		Set_Vector_Row(ser1, value);
		if (IS_VECTOR(arg)) {
			for (y=0; y<rows; y++) for (x=0; x<cols; x++) {
				a = (REBDEC*)ser1->data + (y * cows);
				b = (REBDEC*)ser2->data + x;
				c = (REBDEC*)ser->data + x + (y * cols);
				v = 0;
				for (i=0; i<cows; i++, a++, b+=cols)
					v += (*a)*(*b);
				*c = v;
			}
			SET_VECTOR(value, ser);
		} else { // arg is number
			if (IS_INTEGER(arg)) v = VAL_INT64(arg);
			else if (IS_DECIMAL(arg)) v = VAL_DECIMAL(arg);
			for (a = (REBDEC*)ser1->data, i=0;
					i <	vect->tail;
					i++, a++) *a *= v;
			SET_VECTOR(value, ser1);
		}
		break;

	default:
		Trap_Action(VAL_TYPE(value), action);
	}

	*D_RET = *value;
	return R_RET;

bad_make:
	Trap_Make(REB_VECTOR, arg);
	DEAD_END;
}


/***********************************************************************
**
*/	void Mold_Vector(REBVAL *value, REB_MOLD *mold, REBFLG molded)
/*
***********************************************************************/
{
	REBSER *vect = VAL_SERIES(value);
	REBYTE *data = vect->data;
	REBCNT bits  = VECT_TYPE(vect);
	REBCNT rows  = VECT_ROWS(vect);
	REBCNT cols;
	REBCNT len;
	REBCNT n;
	REBCNT c;
	REBCNT w;
	union {REBU64 i; REBDEC d;} v;
	REBYTE buf[32];
	REBYTE l;

	if (GET_MOPT(mold, MOPT_MOLD_ALL)) {
		len = VAL_TAIL(value);
		n = 0;
	} else {
		len = VAL_LEN(value);
		n = VAL_INDEX(value);
	}

	cols = (len + rows - 1) / rows;

	if (molded) {
		REBCNT type = (bits >= VTSF08) ? REB_DECIMAL : REB_INTEGER;
		Pre_Mold(value, mold);
		if (!GET_MOPT(mold, MOPT_MOLD_ALL)) Append_Byte(mold->series, '[');
		if (bits >= VTUI08 && bits <= VTUI64) Append_Bytes(mold->series, "unsigned ");
		if (rows == 1) Emit(mold, "N I I [", type+1, bit_sizes[bits & 3], len);
		else  Emit(mold, "N I IxI [", type+1, bit_sizes[bits & 3], cols, rows);

		if (len) New_Indented_Line(mold);
	}

	c = 0;
	w = (rows > 1 ? cols : 0);
	for (; n < vect->tail; n ++) {
		v.i = get_vect(bits, data, n);
		if (bits < VTSF08) {
			l = Emit_Integer(buf, v.i);
		} else {
			l = Emit_Decimal(buf, v.d, 0, '.', mold->digits);
		}
		Append_Bytes_Len(mold->series, buf, l);

		if (w && (++c >= w) && (n+1 < vect->tail)) {
			New_Indented_Line(mold);
			c = 0;
		}
		else Append_Byte(mold->series, ' '); 
	}

	if (len) mold->series->tail--; // remove final space

	if (molded) {
		if (len) New_Indented_Line(mold);
		Append_Byte(mold->series, ']');
		if (!GET_MOPT(mold, MOPT_MOLD_ALL)) {
			Append_Byte(mold->series, ']');
		}
		else {
			Post_Mold(value, mold);
		}
	} 
}
