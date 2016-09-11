REBOL [
	Name: remark
	Type: module
	Author: "Giulio Lunati"
	Email: giuliolunati@gmail.com
	Description: "ReMark reader"
	Help: {
	}
]

html: object[
	this: self
	do: func[x] [lib/do bind/new x this]
	emit: function [
		tag [tag!]
		:args [word!]
		:look [word!]
	][
		args: get args
		look: get look
		class: id: _
		open-tag: copy tag
		close-tag: make tag! 8
		either empty: #"/" = last tag
		[ take/last open-tag  close-tag: make tag! 0 ]
		[ close-tag: join </> to-string tag ]
		forever [
			t: first look
			either all [
				word? t
				#"." = first to-string t
			][
				probe t: to-refinement next to-string t
				take look
			][
				t: take args
			]
			if string? t [t: reduce [t]]
			if block? t [
				t: reduce t
				break
			]
			if refinement? t [
				t: next to-string t
				either class
				[repend class [space t]]
				[class: t]
				continue
			]
			if issue? t [id: to-string t]
		]
		if id [ 
			repend open-tag [ { id="} id {"}]
		]
		if class [
			repend open-tag [ { class="} class {"}]
		]
		if empty [append open-tag " /"]
		ajoin [open-tag t close-tag]
	]
	def-tag: func [tag] [
		func [
			args [any-string! issue! refinement! block! <...>]
			:look [any-word! any-string! issue! refinement! block! <...>]
		]
		compose[emit (tag) args look]
	]
	b: def-tag <b>
	body: def-tag <body>
	i: def-tag <i>
	p: def-tag <p>
	div: def-tag <div>
	br: def-tag <br/>
]

;; vim: set syn=rebol:
