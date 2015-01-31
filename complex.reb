complex: func[x] [to complex! x]
complex?: func[x] [all[utype? x x/utype = 'complex!]] 
complex!: make utype! [
	utype: 'complex!
	re: im: 0
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
	.mold: func[x] [
		ajoin ["complex[" x/re #" " x/im #"]"]
	]
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
	;; utype-methods
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
			e: exp im r: 1 / e 
			to complex! [
				(cosine/radians re) * (r + e) / 2 
				(sine/radians re) * (r - e) / 2
			]
		] [ ; degrees
			e: exp im * 0.017453292519943295 ; pi/180
			r: 1 / e 
			to complex! [
				(cosine re) * (r + e) / 2 
				(sine re) * (r - e) / 2
			]
		]
	]
	.divide: func[a b] [ any [
		if number? b [complex[a/re / b a/im / b]]
		a * b/conj / b/abs2
	] ]
	.exp: func[x] [
		(to complex! [
			cosine/radians im sine/radians im
		]) * exp re
	]
	.log-e: func[x] [to complex! [
		(log-e x/abs2) / 2
		x/arg/radians
	] ]
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
			e: exp im r: 1 / e 
			to complex! [
				(sine/radians re) * (r + e) / 2
				(cosine/radians re) * (e - r) / 2
			]
		] [ ; degrees
			e: exp im * 0.017453292519943295 ; pi/180
			r: 1 / e 
			to complex! [
				(sine re) * (r + e) / 2
				(cosine re) * (e - r) / 2
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
]
i!: to complex![0 1]
;;; DEMO
demo: func[code] [
	if string? code [return print code]
	print [">>" mold/only code]
	print ["==" do code]
]
demos: func[block /local b] [
	foreach b block [demo b]
]
;;; MAIN
demos [
	"^/MAKE & TO:"
	[a: make complex! [re: 1 im: 2]]
	[a: to complex! [1 2]]
	[a: complex[1 2]]
	[r: make complex! [re: 2.5]]
	[r: to complex! 2.5]
	[r: complex 2.5]
	[b: complex[3 -2]]
	"^/FORM & MOLD:"
	[form reduce [a b]]
	[mold/only reduce [a b]]
	"^/ARITHMETICS:"
	[c: a + 2]
	[2 + a]
	[c - 2]
	[2 - c]
	[c: a + b]
	[c - b]
	[c: a * 2]
	[2 * a]
	[c / 2]
	[c: 2 / a]
	[c * a]
	[c: a * b]
	[c / b]
	"^/FUNCTIONS:"
	[c: a/arg]
	[a/arg/radians]
	[tangent c]
	[a/abs2]
	[c: absolute a]
	[c * c]
	[c: exp a]
	[log-e c]
	[c: square-root a]
	[c * c]
	[b: cosine a]
	[c: sine a]
	[b * b + (c * c)]
	[a: 1 + i!]
	[b: arccosine a]
	[c: arcsine a]
	[b + c]
	[b: tangent complex[5 7]]
	[arctangent b]
]
; vim: set syn=rebol ts=2 sw=2 sts=2:
