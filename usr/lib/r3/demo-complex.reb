REBOL [
	Title: "Demo for 'complex module"
	Type: 'script
	Require: 'complex
	Author: "giuliolunati@gmail.com"
	Version: 0.1.0
]

import 'complex

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
