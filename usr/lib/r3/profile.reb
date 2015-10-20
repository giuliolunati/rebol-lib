timer: func['t 'f vars code] [
	code: reduce[to set-word! t t '- 'stats/timer 'also 'apply f vars code vars to set-word! t t '+ 'stats/timer]
	func vars code
]
test: timer t1 func [n] [ 
	loop n [n]
	return 987
]
t1: 0
print source test
print test to integer! system/options/args/1
print t1
; vim: set syn=rebol sw=2 ts=2 sts=2:
