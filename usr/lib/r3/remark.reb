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
	tag2: function [
		tag
		x [string! block! refinement! issue! <...>]
	][
		open-tag: copy tag
		class: id: _
		forever [
			t: take x
			if string? t [t: reduce [t]]
			if block? t [
				t: reduce t
				if id [ 
					repend open-tag [ { id="} id {"}]
				]
				if class [
					repend open-tag [ { class="} class {"}]
				]
				insert t open-tag
				append t join </> to-string tag
				return ajoin t
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
	]
	def-tag2: func [tag] [
		func [x [any-value! <...>]]
		compose[tag2 (tag) x]
	]
	b: def-tag2 <b>
	body: def-tag2 <body>
	i: def-tag2 <i>
	p: def-tag2 <p>
	div: def-tag2 <div>
]

;; vim: set syn=rebol:
