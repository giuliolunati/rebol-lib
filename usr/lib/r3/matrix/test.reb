import clean-path %/data/sdext2/kbox/usr/src/rebol-lib/matrix/matrix.so

print-log: func[m] [
	for y 1 m/y 1 [
		for x 1 m/x 1 [
			prin to integer! log-10 1e-99 + abs m/([x y]) prin "^-"
		]
		print ","
	]
]
randomize: func [
		"Fill v with random values in ]a,b]"
		v [vector!]
		a [number!] "min"
		b [number!] "max"
	][
	for i 1 length? v 1 [ v/(i): a + random b - a ]
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
;; MAIN ;; 
random/seed 555
A: make vector! [decimal! 64 [4 4]]
randomize A -1.0 1.0
A: A + A/t
Q: 1 + make vector![decimal! 64 [4 4]]
print "Q:"
probe Q
print "A:"
probe A
m: copy A
print "Q:"
probe diagonalize A Q
print "A:"
print-log A
print-log Q * m * Q/t - A
; vim: set syn=rebol sw=2 ts=2 sts=2:
