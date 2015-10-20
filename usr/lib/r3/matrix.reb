REBOL [
	Title: "Matrix"
	Type: 'module
	Name: 'matrix
	Exports: [
	]
	Author: "giuliolunati@gmail.com"
	Version: 0.1.0
]
tim: 0:0:0
print-log: func[m] [
	for y 1 m/y 1 [
		for x 1 m/x 1 [
			prin to integer! log-10 1e-99 + abs m/([x y]) prin "^-"
		]
		print ","
	]
]
swap: function [m a b /row /col] [
	if a = b return m
	cols: m/x rows: m/y
	unless col [ for x 1 cols 1 [ ;swap rows
			t: m/([x a]) m/([x a]): m/([x b]) m/([x b]): t
	] ]
	unless row [ for y 1 rows 1 [ ;swap cols
			t: m/([a y]) m/([a y]): m/([b y]) m/([b y]): t
	] ]
	m
]
diagonalize1: function[m eps n] [
	dims: m/x
	assert [dims = m/y]
	b: copy m
	q: tri-form/symm b
	for x 1 dims 1 [ for y 1 dims 1 [
	 if any[x + 1 < y  x - 1 > y] [m/([x y]): 0]
	] ]
	for i 1 dims - 1 1 [
		m/([i i + 1]): m/([i + 1 i]) + m/([i i + 1]) / 2
	]
	k: dims
	forever [
		while [k > 1] [
			if all[
				(abs m/([k k])) * eps <= abs m/([k - 1 k])
				(abs m/([k - 1 k - 1])) * eps <= abs m/([k - 1 k])
			] [break]
			-- k
		]
		if k = 1 [break]
		t: m/([k k])
		for i 1 k 1 [m/([i i]): m/([i i]) - t]
		for i 1 k - 1 1 [
			c: m/([i i])   s: m/([i i + 1])
			if 0 = r: square-root c * c + (s * s) [continue]
			c: c / r   s: s / r
			for j 1 dims 1 [
				a: q/([j i])   b: q/([j i + 1])
				q/([j i]): a * c + (b * s)
				q/([j i + 1]): a * s - (b * c)
			]
			if i > 1 [
				m/([i - 1 i]): m/([i - 1 i]) * c + (z * s)
			]
			a: m/([i i + 1])   b: m/([i + 1 i + 1])
			m/([i i + 1]): a * c + (b * s)
			m/([i + 1 i + 1]): a * s - (b * c)
			if i + 2 <= k [
				b: m/([i + 1 i + 2])
				z: b * s
				m/([i + 1 i + 2]): 0 - b * c
			]
			b: m/([i i + 1])
			m/([i i]): r * c + (b * s)
			m/([i i + 1]): r * s - (b * c)
			m/([i + 1 i + 1]): 0 - (m/([i + 1 i + 1]) * c)
		]
		for i 1 k 1 [m/([i i]): m/([i i]) + t]
		if (-- n = 1) [break]
	]
	for i 1 dims - 1 1 [
		m/([i + 1 i]): m/([i i + 1])
	]
	q
]
svd: function[m eps n] [
	b: copy m
	either m/y > m/x [ ; portrait
		c: m/t * m
		r: diagonalize1 c eps n
		m: m * r/t
		l: tri-form/upper m
		l * m
	] [ ; landscape
		c: m * m/t 
		l: diagonalize1 c eps n
		m: l * m
		r: tri-form/lower m
	]
	reduce [l r]
]
norm: function[m i] [
	t: 0
	for j 1 m/y 1 [v: m/([i j]) t: v * v + t]
	square-root t
]
randomize: func [
		"Fill v with random values in ]a,b]"
		v [vector!]
		a [number!] "min"
		b [number!] "max"
	][
	for i 1 length? v 1 [ v/(i): a + random b - a ]
]
solve: function [A B] [
	s: make vector! reduce['decimal! 64 [B/x A/x]]
	transform-matrix/also A B
	for y (min A/x A/y) 1 -1 [
		for i y A/x 1 [
			if A/([i y]) = 0 [continue]
			for x 1 B/x 1 [
				t: B/([x y])
				for j (i + 1) A/x 1 [
					t: t - ( s/([x j]) * A/([j y]) )
				]
				s/([x i]): t / A/([i y])
			]
			break
		]
	]
	s
]

;;; MAIN ;;;
random/seed 555
args: system/options/args
x: to integer! args/1
m: make vector! [decimal! 64 [x x]]
randomize m -1.0 1
m: m + m/t
print "lower"
t: copy m
q: transform-matrix/lower t
print-log m * q - t
print "upper"
t: copy m
q: transform-matrix t
print-log q * m - t
print "symm"
t: copy m
q: transform-matrix/symm t
print-log q * t * q/t - m
print "hupp"
t: copy m
q: transform-matrix/hessenberg t
print-log q * t * q/t - m
print "hlow"
t: copy m
q: transform-matrix/hessenberg/lower t
print-log q * t * q/t - m
quit
b: make vector! [decimal! 64 [3 dim + 2]]
randomize b -1.0 1
s: solve m b
print-log s print""
print-log m * s - b
quit
print t1: dt[q: transform-matrix/hessenberg m1]
if dim > 7 [quit]
print-log m1
print []
print-log q/t * m1 * q - m
; vim: set syn=rebol ts=2 sw=2 sts=2:
