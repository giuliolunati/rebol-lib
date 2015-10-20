REBOL [
	Title: "Demo for vector-matrix"
	Type: 'script
	Author: "giuliolunati@gmail.com"
	Version: 0.1.0
]

demo: func[code /local t] [
	foreach t code [
		either block? t [
			print [">>" mold/only t]
			print ["==" reduce t]
		] [print t]
	]
]
;;; MAIN
demo [
	[mold m: make vector! [decimal! 64 8x8]]
	[for x 1 8 1 [ for y x 8 1 [
			m/([x y]): m/([y x]): random 10.0
		] m]
	]
	[m: qr m]
	[quit]
	"=== CONSTRUCTION ==="
	"^/int32 zeros:"
	[mold make vector! 10]
	"^/matrix:"
	[mold make vector! [decimal! 64 3x2 [.1 .2]]]
	[mold v: make vector! [decimal! 64 3x2 [1 2 3 4 5 6 7 8]]]
	[mold v/size]
	[mold v/x]
	[mold v/y]
	"^/implicit rows number:"
	[mold make vector! [decimal! 64 3 [.1 .2 .3 .4 .5]]]
	"^/can use vars for bits, size and data:"
	[bits: 64 size: 3 data: [.1 .2 .3 .4 .5]]
	[mold make vector! [decimal! bits size data]]
]
; vim: set syn=rebol ts=2 sw=2 sts=2:
