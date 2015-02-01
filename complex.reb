REBOL [
	Title: "Complex utype"
	Type: 'module
	Name: 'complex
	Exports: [
		complex
		complex?
		complex!
		i!
	]
	Author: "giuliolunati@gmail.com"
	Version: 0.1.0
	Note: "require utype! implementation as in https://github.com/giuliolunati/rebol/tree/utype"
	Demo: %demo-complex.reb
]

complex: func[x] [to complex! x]
complex?: func[x] [all[utype? x x/utype = 'complex!]]
complex!: make utype! [
	utype: 'complex!
	re: im: 0
	abs2: func[] [re * re + (im * im)]
	arg: func[/radians /local r] [
		either (absolute re) > absolute im
		[r: arctangent im / re]
		[r: 90 - arctangent re / im]
		if im + re < 0 [r: r - 180]
		if r + 180 <= 0 [r: r + 360]
		either/only radians 
			r / 180 * pi
			r
	]
	conj: func[] [to complex! [re negate im]] ; conjugate
	.methods: object [;; utype-methods
		.absolute: func[a] [square-root a/abs2]
		.add: func[a b /local r] [ any [
			attempt[to complex! [
				a/re + b/re a/im + b/im
			] ]
			(to complex! a) + (to complex! b)
		] ]
		.arccosine: func[x /radians /local r] [
			r: x + square-root (x * x - 1)
			r: i! * log-e r
			either/only radians r r * 180 / pi
		]
		.arcsine: func[x /radians /local r] [
			r: x + square-root (x * x - 1)
			r: pi / 2 - (i! * log-e r)
			either/only radians r r * 180 / pi
		]
		.arctangent: func[x /radians /local r] [
			r: square-root (i! - x) / (i! + x)
			r: negate i! * log-e r
			either/only radians r r * 180 / pi
		]
		.cosine: func[x /radians /local e r] [
			either radians [
				e: exp x/im r: 1 / e 
				to complex! [
					(cosine/radians x/re) * (r + e) / 2 
					(sine/radians x/re) * (r - e) / 2
				]
			] [ ; degrees
				e: exp x/im * 0.017453292519943295 ; pi/180
				r: 1 / e 
				to complex! [
					(cosine x/re) * (r + e) / 2 
					(sine x/re) * (r - e) / 2
				]
			]
		]
		.divide: func[a b] [ any [
			if number? b [complex[a/re / b a/im / b]]
			a * b/conj / b/abs2
		] ]
		.exp: func[x] [
			(to complex! [
				cosine/radians x/im sine/radians x/im
			]) * exp x/re
		]
		.form: func[x] [ ajoin[
			either x/re = 0 [] [x/re] 
			either x/im = 0 
			[ either x/re = 0 [0] [] ]
			[ ajoin[
				either x/im > 0 ["+"] []
				case [
					x/im = 1 ["i"]
					x/im = -1 ["-i"]
					true ajoin[x/im "i"]
				]
			] ]
		] ]
		.log-e: func[x] [to complex! [
			(log-e x/abs2) / 2
			x/arg/radians
		] ]
		.mold: func[x] [
			ajoin ["complex[" x/re #" " x/im #"]"]
		]
		.multiply: func[a b] [ any [
			attempt [to complex![
				a/re * b/re - (a/im * b/im)
				a/im * b/re + (a/re * b/im)
			] ]
			(to complex! a) * (to complex! b)
		] ]
		.negate: func[x] [complex[negate x/re negate x/im]]
		.sine: func[x /radians /local e r] [
			either radians [
				e: exp x/im r: 1 / e 
				to complex! [
					(sine/radians x/re) * (r + e) / 2
					(cosine/radians x/re) * (e - r) / 2
				]
			] [ ; degrees
				e: exp x/im * 0.017453292519943295 ; pi/180
				r: 1 / e 
				to complex! [
					(sine x/re) * (r + e) / 2
					(cosine x/re) * (e - r) / 2
				]
			]
		]
		.square-root: func[a] [exp (log-e a) / 2]
		.subtract: func[a b] [any [
			attempt [to complex! [a/re - b/re a/im - b/im]]
			(to complex! a) - (to complex! b)
		] ]
		.tangent: func[x /radians] [
			either radians [
				(sine/radians x) / (cosine/radians x)
			] [ ; degrees
				(sine x) / (cosine x)
			]
		]
		.to: func[x spec /local r] [
			if complex? spec [return spec]
			r: make complex! []
			case [
				block? spec [
					spec: reduce spec
					r/re: spec/1
					r/im: spec/2
				]
				number? spec [r/re: spec]
			]
			r
		]
	]
]
i!: to complex![0 1]
; vim: set syn=rebol ts=2 sw=2 sts=2:
