REBOL [
  Name: 'csv
  Type: module
  Author: "Giulio Lunati"
  Email: giuliolunati@gmail.com
  Description: "CSV input/output"
  Exports: [read-csv write-csv]
]

read-csv: func [x [string!] b: f: r: delim!:] [
	delim!: charset {,^/}
	b: make block! 256
	r: parse x [any [ ;; record
		(r: make block! 32)
		any [ ;; field
			[ [#""" copy f to #""" skip]
			| copy f to delim!
			] (append/only r f)
			[#"," | break]
		]
		some newline (append/only b r)
	] ]
	b
]

write-csv: func [x] [x]


;; vim: set syn=rebol sw=2 ts=2 sts=2:
