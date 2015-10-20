REBOL [
	Title: "demo for 'fraction module"
	Type: 'script
	Author: "Giulio Lunati"
	Author-email: giuliolunati@gmail.com
]

import 'fraction

demo: func[code /local t] [
	foreach t code [
		either block? t [
			print [">>" mold/only t]
			print ["==" reduce t]
		] [print t]
	]
]
demo [
	"^/## MAKE, TO, SIMPLIFY ##"
	[f: make fraction! [num: 50 den: 80]]
	[fraction? 0.1]
	"'simplify' acts in-place:"
	[f/simplify  f]
	"'to fraction!' automatically simplify:"
	[to fraction! [50 80]]
	"'fraction x y' is an alias for 'to fraction! [x y]':"
	[f: fraction 50 80]
	[g: fraction 8 13]
	"^/## TYPE CHECK ##"
	"'type?' returns word! :"
	[type? f]
	[type? type? f]
	[fraction? f]
	"^/## ARITHMETIC ##"
	[f + g]
	[f - g]
	[f * g]
	[f / g]
	"'invert' is not in-place:"
	[f/invert f]
	"order:"
	[minimum f g]
	[maximum f g]
	[f < g]
	[f >= g]
	"^/## FRACTIONS & NUMBERS ##"
	[pi]
	[f: to fraction! pi]
	[to decimal! f]
	[to integer! f]
	"approximant fractions:"
	[f: approx-fraction pi 1]
	[pi - to decimal! f]
	[f: approx-fraction pi 0.01]
	[pi - to decimal! f]
	[f: approx-fraction pi 0.0001]
	[pi - to decimal! f]
]
; vim: set syn=rebol ts=2 sw=2 sts=2:
