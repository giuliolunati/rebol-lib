REBOL [
	Title: "fraction utype"
	Type: 'module
	Name: 'fraction
	Exports: [
		approx-fraction
		fraction
		fraction!
		fraction?
	]
	Author: "Giulio Lunati"
	Author-email: giuliolunati@gmail.com
	Note: "require utype! implementation as in https://github.com/giuliolunati/rebol/tree/utype"
	Demo: %demo-fraction.reb
]

; prototype
fraction!: make utype! [
	; data
	num: 0 den: 1
	; methods
	invert: does [fraction den num]
	simplify: func[/local t] [
		t: gcd num den
		num: num / t
		den: den / t
		make utype! self
	]
	; utype methods
	.methods: object[
		; TYPE & CONVERSION
		.typeq: does ['fraction!]
		.to: func[target source /local n d n0 d0 t s] [
			if target == decimal!
			[	return source/num / source/den ]
			if target == integer!
			[	return to integer! source/num / source/den ]
			if fraction? source [return source]
			if block? source [
				source: reduce source
				either all [integer? source/1 integer? source/2]
				[ n: source/1 d: source/2 ]
				[ source: source/1 / source/2 ]
			]
			if decimal? source [return approx-fraction source 0]
			if integer? source [n: source d: 1]
			n: make fraction! [num: n den: d]
			n/simplify
		]
		; FORM & MOLD
		.form: func[x] [ajoin[x/num "/" x/den]]
		.mold: func[x] [ajoin["fraction " x/num " " x/den]]
		; ARITHMETIC
		.add: func[x y /local d] [
			d: gcd x/den y/den
			fraction
				(y/den / d * x/num) + (x/den / d * y/num)
				x/den / d * y/den
		]
		.divide: func[x y] [x * y/invert]
		.multiply: func[x y /local a b] [
			a: gcd x/num y/den
			b: gcd x/den y/num
			fraction
				x/num / a * y/num / b
				x/den / b * y/den / a
		]
		.negate: func[x] [fraction negate x/num x/den]
		.subtract: func[x y] [x + negate y]
		; COMPARISON
		.compare: func[x y mode] [
			if mode = 2 [return x/num = y/num and (x/den = y/den)]
			if fraction? x [x: to decimal! x]
			if fraction? y [y: to decimal! y]
			if mode >= 0 [return x = y]
			if mode = -1 [return x >= y]
			if mode = -2 [return x > y]
		]
	]
]
; constructor
fraction: func[x y] [to fraction! reduce[x y]]
; type check
fraction?: func[x] [(type? x) = 'fraction!]
; auxiliary functions
approx-fraction: func [
		x
		err
		/show
		/local n n0 d d0 t s
	] [
	n0: d: 0 d0: n: 1 s: x
	loop 50 [
		t: to integer! round/down s
		set[n0 n] reduce[n n * t + n0]
		set[d0 d] reduce[d d * t + d0]
		if show [print [fraction n d  n / d - x]]
		if (absolute n / d - x) <= err [break]
		if t = s [break]
		s: 1 /(s - t)
	]
	fraction n d
]
gcd: func[x [integer!] y [integer!] /local t] [
	while [y != 0] [t: x // y x: y y: t]
	x
]
; vim: set syn=rebol ts=2 sw=2 sts=2:
