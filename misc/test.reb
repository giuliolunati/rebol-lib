REBOL [
	Title: "ReCode"
	Purpose: "Write C code in Rebol-like syntax"
	Name: 'recode
	Type: 'module
	Exports: [ c-quote to-c indent+ indent- rebol-ext ]
	Author: "giuliolunati@gmail.com"
	Version: 0.1.0
]
import 'bt
;; FIND ERROR
ok: none
oks: make block! 16
pr: func [x [block!] width] [
	print [
		either tail? x ["TAIL"]
			to string! reduce["POS: ... " copy/part mold/only x width "..."]
		"^/IN BLOCK:^/[ "
		copy/part mold/only head x width "...^/]"
	]
]
find-err: function [code [block!] oks] [
	p: head oks
	forall p [
		if (head p/1) != head code [continue]
		either block? p/1/1
			[return find-err p/1/1 p]
			[return p/1]
	]
	return code
]
traces: function[ok] [
	if none? ok [return none]
	p: head oks
	forall p [
		if (head p/1) != head ok [continue]
		if (index? p/1) < index? ok [p/1: ok]
		return none
	]
	insert/only oks ok
]
;; STACK
emit-path: func[p /local s] [
	s: make string! 16
	repend s p/1
	foreach x next p [
		if word? x [repend s ["->" x]]
		if paren? x [repend s ["[" x "]"]]
	]
	if set-path? p [repend s " = "]
	emit s
]
emit-string: function[s] [
	r: copy {"}
	t: make string! 16
	c: charset {"\^/}
	parse s [ any [
		copy t to c (append r t append r "\")
		[ #"^/" (append r "n")
		| set t skip (append r t)
		]
	] copy t to end (append r t append r {"})]
	repend last stack r
]

		
;; FORMAT
indent: ""
indent+: does[append indent "^-"]
indent-: does[remove indent]
c-quote: function [
		s [block! string!]
	] [
	c: charset {"\^/}
	t: make string! 64
	s: mold/only s
	parse s [
		insert #"^""
		any [
			to c [
				and #"^/" insert "\n^"" skip insert #"^""
				| insert #"\" skip
			]
			| to end insert #"^"" skip
		]
	]
	s
]

to-c: function [
		code [block!]
	] [
	bt/init

	all!: bt/collect[
		'all into [
			expr! some [(emit " && ") expr!]
		]
	]
	any!: bt/collect[
		'any into [
			expr! some [(emit " || ") expr!]
		]
	]
	assignment!: bt/collect[
		[ set t set-word! (emit reduce[to lit-word! t " = "])
		|	set t set-path! (emit-path t)
		| expr! 
			set t [	quote := | quote /= | '+= | '-= | '*= ]
			(switch t[
				:= [t: #"="]
				/= [t: "/="]
			] emit [space t space])
		] [expr! | assignment!]
	]
	directive!: bt/collect[
	]
	expr!: bt/collect[
		'either (emit "(") expr! (emit " ? ")
			into[expr!] (emit " : ") into[expr!] (emit ")")
		| '- (emit '-) expr!
		|	set t lit-word!
			(emit ["(" to word! t ")"])
			and paren! into[(emit "(")expr!(emit ")")]
		| expr1! (insert stack np np: 0) opt any [op! expr1! (emit ")" ++ np)]
			(loop np [insert last stack "("]  np: take stack)
	]
	expr1!: [
		func-call!
		| '++ set t word! (emit [t '++])
		| '-- set t word! (emit [t '--])
		| and paren! into [] ; () void expr
		| and paren! into [ expr! ]
		| all!
		| name!
		| set t [integer! | decimal!] (emit t)
		| set t string! (emit-string t)
		| set t path! (emit-path t)
		| set t issue! (emit to integer! t)
	]
	func-call!: bt/collect[
		name!
		and paren! into [(emit #"(")
			opt expr! any [(emit ", ") expr!]
		(emit #")")]
	]
	op!: [
		set t [
			'+ | '- | '* | quote / | quote // |
			'= | '< | '> | '<= | '>= | '!= |
			'or | 'and |
			'& | '| | '<< | '>>
		]
		( t: switch/default t
			[ =['==]   or['||]   and['&&] //[#"%"] ] [t]
			emit [space t space]
		)
	]
	name!: [
		'none (emit "NULL")
		| 'square-root (emit "sqrt")
		| set t word! (emit t)
	]
	sequence!: bt/collect[
		and block! into[
			statement3! any [(emit ", ") statement3!]
		]
	]
	statement1!: bt/collect[
		'return (emit "return ") expr! ; return () => return
		| vars!
		| assignment!
		| func-call!
		| expr!
	]
	statement2!: bt/collect[
		'if (emit "if (") expr! (emit ") ") [suite! | statement!]
		|	'either (emit "if (") expr! (emit ") ")
			[suite! | statement!] (emit " else ")
			[suite! | statement!]
		| 'for (emit "for (") into [
				statement3!(emit "; ")
				expr! (emit "; ")
				statement3!(emit ") ")
			] [suite! | statement!]
		| 'forever (emit "while (1) ") [suite! | statement!]
		| 'repeat (emit "for (")
			set t word! (emit [t " = 0; " t " < "] insert stack t)
			expr! (emit ["; " take stack "++) "])
			[suite! | statement!]
		| 'while (emit "while (")
			[expr! | sequence!] (emit ")")
			[suite! | statement!]
		| 'switch (emit "switch (")
			expr! (emit ") {^/")
			into [some [
				(emit [indent "case "] indent+) expr! (emit " :^/")
				into [statements!] (emit [indent "break;^/"] indent-) 
			] ] (indent- emit [indent "}^/"])
		| ;func-decl
			set t lit-word! (emit [to string! t space])
			set t set-word! (emit to string! to word! t)
			into [ any string!
				(emit "(") opt vars! any [(emit ", ") vars!] (emit ")")
			] (indent+ emit " {^/")
			into [statements!]
			(indent- emit [indent "}^/"])
		| sequence!
	]
	statement3!: [statement2! | statement1!]
	statement!: [statement2! | statement1!(emit ";")] 
	statements!: bt/collect[ any
		[	; directive
			set t and issue!
			[ #include into
				[ some [(emit "#include ")
					[ set t tag! (emit mold t)
					| set t file! (emit mold to string! t)
					] (emit newline)
				] ]
			| #define (emit [t space])
				expr! (emit space)
				set t skip (emit to string! t)
			| #undef (emit [t space])
				set t word! (emit t)
			]
			(emit newline)
		|	(emit indent) statement! (emit newline)
		]
	]
	suite!: bt/collect[
		and block! into[(emit " {^/" indent+) statements! (indent- emit [indent "}"])]
	]
	var!: bt/collect[
		set t word! (emit t)
		set t opt [set t block! (emit mold t)]
		|	assignment!
	]
	vars!: bt/collect[
		some [set t lit-word! (emit [to word! t space])]
		[ var!
		| into [var! any [(emit ", ") var!]
			]
		]
	]
	set 'ok code
	unless parse code [
		statements!
	] [
		PRIN "*** ERROR ***^/NEAR: "
		pr find-err code oks 58
		quit
	]
	first stack
]
rebol-ext: function [r [block!]] [
	rebol-code: make block! 128
	cases: make string! 128
	n: 0 c: t: none 
	c-code: make string! 128
	parse r [
		copy t to 'REBOL (append c-code to-c t)
		copy t ['REBOL block!] (append rebol-code t)
		any [
			copy t [set-word! 'command block!]
				set c block!
					(append rebol-code t)
					(indent+ append cases ajoin [
						"case " ++ n ": { // " to word! t/1 newline
						to-c c
						"^-break;^/}^/"
					] indent-)
			| set t skip
				(append/only rebol-code t)
		]
	]
	print ajoin[
		c-code
		"^/const char *init_block =^/"
		c-quote rebol-code #";"
		{^/RXIEXT const char *RX_Init(int opts, RL_LIB *lib) {
		RL = lib;
		if (!CHECK_STRUCT_ALIGN) {
			printf ( "CHECK_STRUCT_ALIGN failed\n" );
			return 0;
		}
		return init_block;^/}}

		"^/RL_LIB *RL = NULL;"
		"^/RXIEXT int RX_Call(int cmd, RXIFRM *frm, void *data){"
		"^/switch (cmd) {^/"
		cases
		"default: return RXR_NO_COMMAND;"
		"^/}};"
	]
]
;; TEST ;;
prin to-c [
	'int x: 3
]
;; vim: set syn=rebol sw=2 ts=2 sts=2:
