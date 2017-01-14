REBOL [
	Title: "HTML utils for Ren/C"
	Type: 'module
	Name: 'html
	Exports: [
		split-html
	]
	Author: "giuliolunati@gmail.com"
	Version: 0.1.1
]

;=== RULES === 
	!?: charset "!?"
	alpha!: charset [#"A" - #"Z" #"a" - #"z"]
	hexa!: charset [#"A" - #"F" #"a" - #"f" #"0" - #"9"]
	num!: charset [#"0" - #"9"]
	space!: charset " ^/^-^M "
	spacer!: [and string! into[any space!]] 
	mark!: charset "<&"
	quo1!: charset {'\}
	quo2!: charset {"\}
	name!: use [w1 w+] [
		w1: charset [ "ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz" #"^(C0)" - #"^(D6)" #"^(D8)" - #"^(F6)" #"^(F8)" -#"^(02FF)" #"^(0370)" - #"^(037D)" #"^(037F)" - #"^(1FFF)" #"^(200C)" - #"^(200D)" #"^(2070)" - #"^(218F)" #"^(2C00)" - #"^(2FEF)" #"^(3001)" - #"^(D7FF)" #"^(f900)" - #"^(FDCF)" #"^(FDF0)" - #"^(FFFD)" ]
		w+: charset [ "-.0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz" #"^(B7)" #"^(C0)" -#"^(D6)" #"^(D8)" - #"^(F6)" #"^(F8)" - #"^(037D)" #"^(037F)" - #"^(1FFF)" #"^(200C)" - #"^(200D)" #"^(203F)" - #"^(2040)" #"^(2070)" - #"^(218F)" #"^(2C00)" - #"^(2FEF)" #"^(3001)" - #"^(D7FF)" #"^(f900)" - #"^(FDCF)" #"^(FDF0)" - #"^(FFFD)" ]
		[w1 any w+]
	]
;=== FUNCTIONS === 

;; from 'text module
unquote-string: function [
		{Remove \ escape and " quotes}
		s
	] [
	parse s [ any [
		to #"\" remove skip skip
	] ]
	copy/part next s back tail s
]

split-html: function [data [string!]] [
	a: b: k: n: t: v: _
	ret: make block! 32
	emit: func [x /local t] [
		if x = "" [return _]
		if char? x [x: to string! x]
		if string? x [
			t: last ret
			if string? t [return append t x]
		]
		append/only ret x
	]
	entity!: [ #"&"
		[	#"#"
			[	#"x" copy t some hexa! (
					emit do [ ajoin[{"^^(} t {)"}] ]
				)
			|	copy t some num! (
					emit to char! to integer! t
				)
			]
		| copy t some alpha! (
				emit switch/default t [
					"nbsp" [#"^(a0)"]
				] ajoin[#"&" t #";"]
			)
		]
		opt #";"
	]
	value!:
		[	copy v [
			#"'" any [to quo1! #"\" skip] thru #"'"
			|
			#"^"" any [to quo2! #"\" skip] thru #"^""
			] (v: unquote-string v)
		|	copy v to [space! | #">"]
		]
	attribs!: [ (a: _)
		any [some space!
			copy k name! (v: true )
			opt [any space! #"=" any space! value!]
			(	unless a [a: make block! 8]
				k: to word! k
				if k = 'style [
					b: make block! 8
					parse probe v [ any [
						any space
						copy n name! any space! #":" any space
						copy k to [#";" | end] opt #";"
						(	
							repend b [to word! n k]
						)
					]	]
					k: 'style v: b
				] 
				repend a [k v]
			)
		]
		any space!
	]
	comment!: ["!--" thru "--"]
	!tag!: [#"!" to #">"]
	?tag!: [#"?" to #">"]
	atag!: [
		#"<" copy t name! attribs! opt #"/" #">"
		(emit to word! t if a [emit a])
	]
	ztag!: [
		"</" copy t name! #">"
		(emit to refinement! t)
	]
	data-tag!: [
		and copy t ["<script"|"<style"]
		atag! (insert t "</" append t #">")
		copy t to t (emit t) ztag!
	]
	html!: [ any [
			copy t to mark! (emit t)
			[	#"<" copy t [comment! | !tag!] #">"
				(emit '! emit next t)
			|	#"<" copy t ?tag! #">"
				(emit '? emit next t)
			|	data-tag! | atag! | ztag! | entity!
			|	set t skip (emit t)
			]
		]
		copy t to end (emit t)
	]
	either parse to string! data html! [ret] [return false]
]

; vim: syn=rebol sw=2 ts=2 sts=2:
