REBOL [
	Title: "BackTrace"
	Purpose: ""
	Name: 'bt
	Type: 'module
	Exports: [ bt ]
	Author: "giuliolunati@gmail.com"
	Version: 0.1.0
]

bt-rule: [
	insert ((bt/push))
	any [
		to ['| | block! | 'into]
		[
			and block! into bt-rule
			| and 'into insert (ok: (traces ok)) skip
			| insert ((bt/epop)) skip insert ((cls))
		]
	]
	to end insert ((bt/epop) | ok: (traces ok bt/pop) fail )
]
bt: object [
	stack: make block! 16
	init: does [clear stack push]
	push: does [
		append/only stack make string! 16
	]
	pop: does [take/last stack]
	epop: does [emit pop]
	cls: does [clear last stack]
	emit: func[s] [
		repend last stack s
	]
	collect: function [rules [block!]] [
		parse rules bt-rule
		rules
	]
	init
]
;; vim: set syn=rebol sw=2 ts=2 sts=2:
