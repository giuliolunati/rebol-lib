REBOL [ 
	Title: "HTML utils for REBOL 3"
	Type: 'module
	Name: 'html
	Exports: [
		html-clean
		html-parse
		html-scan
		html-write
	]
	Needs: [text]
	Author: "giuliolunati@gmail.com"
	Version: 0.1.0
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
fix-space: function [s [string!]] [
	parse s [ any [
		to space!
		remove some space! insert #" "
	] ] s
]
invert-tag: func [t [tag!]] [
	either t/1 = #"/"
		[next t]
		[head insert copy t #"/"]
]
is-block?: func[x] [
	if x/1 = #"/" [x: next x]
	find [
		P H1 H2 H3 H4 H5 H6
		UL OL DL
		PRE
		DIV NOSCRIPT BLOCKQUOTE FORM HR TABLE FIELDSET ADDRESS
	] to word! to string!	x 
]
is-empty?: func[x] [
	find [
		AREA BASE BR COL COMMAND EMBED HR IMG INPUT KEYGEN
		LINK META PARAM SOURCE TRACK WBR
	] to word! to string!	x
]
is-flow?: func[x] [any [is-block? x is-inline? x]]
is-inline?: func[x] [
	if x/1 = #"/" [x: next x]
	find [
		TT I B BIG SMALL FONT
		EM STRONG DFN CODE SAMP KBD VAR CITE ABBR ACRONYM
		A IMG OBJECT BR SCRIPT MAP Q SUB SUP SPAN BDO
		INPUT SELECT TEXTAREA LABEL BUTTON
	] to word! to string!	x 
]
html-parse: function [data] [
	a: k: n: t: v: none
	ret: make block! 32
	emit: func [x /local t] [
		if x = "" [return none]
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
	attribs!: [ (a: none)
		any [some space!
			copy k name! (v: true )
			opt [any space! #"=" any space! value!]
			(	unless a [a: object[]]
				either k != "style" [
					extend a to word! k :v
				]	[
					parse v [ any [
						any space
						copy n name! any space! #":" any space
						copy k to [#";" | end] opt #";"
						(	insert n #"-"
							extend a to word! n :k
						)
					]	]
				] 
			)
		]
		any space!
	]
	comment!: ["!--" thru "--"]
	!tag!: [#"!" to #">"]
	?tag!: [#"?" to #">"]
	atag!: [ #"<" copy t name! attribs!
		[	#"/"
			then (append t #"/")
		|	(	if is-empty? t [append t #"/"] )
		] #">"
		(emit to tag! t if a [emit a])
	]
	ztag!: [
		#"<" copy t [#"/" name!] #">"
		(emit to tag! t)
	]
	data-tag!: [
		and copy t ["<script"|"<style"]
		atag! (insert t "</" append t #">")
		copy t to t (emit t) ztag!
	]
	html!: [ any [
			copy t to mark! (emit t)
			[	#"<" copy t [comment! | !tag! | ?tag!] #">"
				(emit to tag! t)
			|	data-tag! | atag! | ztag! | entity!
			|	set t skip (emit t)
			]
		]
		copy t to end (emit t)
	]
	either parse to string! data html! [ret] [return false]
	;; fix 
	b: make block! 8
	fix: [
		any [
			to tag!
			[	set t into [ !? to end ] 
			| v: into [ #"/" copy t to end] (
					if (n: b/1) != t [ case [
						n = none []
						n = <p> [insert v </p>]
						n/1 = #"/" [insert v n]
						true [
							n: find b t
							if n [change n invert-tag t]
							remove v
							insert b none
						]
					]	]
					take b
					v: next v
				) :v 
			|	into [ some thru #"/"]
			|	v: set t skip (
					switch b/1 [
						<p> [ unless is-inline? t [
							insert v </p>
							v: back v
						]	]
					]
					insert b t
					v: next v
				) :v
			]
		]
		to end v:
		( while [t: take b] [
			insert v invert-tag t
			v: next v
		]	) :v
	]
	either parse ret fix [ret] [false]
]
html-scan: function [data [string! block!]] [
	a: o: t: w: none tags: object[]
	if string? data [data: html-parse data]
	unless data [return data]
	parse data [ any [
		to tag!
		[	into [ [!? | #"/"] to end]
		| set t skip (
				t: to word! to string! t
				unless in tags t [
					extend tags t true
				]
			)
		]
		opt [set o object! (
				foreach a words-of o [
					unless object? tags/(t) [tags/(t): object[]]
					unless in tags/(t) a [
						extend tags/(t) a make block! 2
					]
					unless find tags/(t)/(a) o/(a) [
						append tags/(t)/(a) o/(a)
					]
				]
		)	]
	]	to end ]
	tags
]
html-clean: function [data] [
	hsp: false
	ib: ii: ob: oi: false
	vsp: 0
	vtag: none
	ret: make block! 128
	emit: func [x] [
		if tag? x [
			append ret copy x
			switch x [
				<b> [ob: true]
				<i> [oi: true]
				</b> [ob: false]
				</i> [oi: false]
			]
			return none
		]
		x: fix-space x
		if x/1 = #" " [x: next x hsp: true]
		case/all [
			if oi and (not ii) [emit </i>]
			if ob and (not ib) [emit </b>]
			vsp >= 2 [
				if vtag [
					if oi [emit </i>]
					if ob [emit </b>]
					append ret vtag
				]
				append ret copy <p>
				if ib [emit <b>]
				if ii [emit <i>]
				vtag: copy </p>
			]
			vsp = 1 [append ret copy <br/>]
			all [hsp vsp = 0] [append ret copy " "]
			true [hsp: false vsp: 0]
			(last x) = #" " [hsp: true remove back tail x]
			if (not ob) and ib [append ret copy <b> ob: true]
			if (not oi) and ii [append ret copy <i> oi: true]
		]
		either string? last ret
		[ append last ret x]
		[	append ret x ]
	]
	if string? data [data: html-parse data]
	unless data [return data]
	parse data [ any [
		spacer! (hsp: true)
		|	set t string!	(emit t)
		|	and tag! into [ !? to end ]
		|	<head> thru </head>
		|	<script> thru </script>
		|	<style> thru </style>
		|	<br/> (++ vsp)
		|	<p> (vsp: vsp + 2)
		|	<b> (ib: true)
		| </b> (ib: false)
		|	<i> (ii: true)
		| </i> (ii: false)
		|	tag!
		|	object!
	] ]
	ret
]
html-write: function [
		tree [block!]
	] [
	ret: []
	append ret make string! 128
	emit: func [x] [
		either block? x
			[append ret/1 ajoin x]
			[append ret/1 x]
	]
	t: w: none
	foreach t tree [
		case [
			object? t [
				emit [#"<" t/!]
				foreach w words-of t [
					if any [w = '! w = '*] [continue]
					emit [#" " w #"=" quote-string t/(w)]
				]
				either in t '* [
					emit #">"
					emit html-write t/*
					emit [#"<" #"/" t/! #">"]
				] [
					emit [#"/" #">"]
				]
			]
			any [string? t t/1 = #"&"] [emit t]
		]
	]
	take ret
]

; vim: syn=rebol sw=2 ts=2 sts=2:
