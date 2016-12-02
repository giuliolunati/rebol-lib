REBOL [
	Title: "Complex numbers"
	Author: "giuliolunati@gmail.com"
	Version: 0.1.0
	Type: module
	Name: 'complex
  Exports: [complex! complex? i +i -i]
]

import 'customize

complex!: make map! 8

complex?: func [x] [
  either attempt [same? x/type complex!]
  [true] [false]
]

complex!/make: complex-make: func [type def o: t:] [
  if same? type complex! [ ;; MAKE
    if complex? def [return copy def]
    o: make map! reduce [
      'type complex!
      'r 0 'i 0
    ]
    case [
      number? def [o/r: def return o]
      block? def [o/r: def/1 o/i: def/2 return o]
      string? def [
        if attempt [
          t: split def #"i"
          insert t/2 take/last t/1
          o/r: to-decimal t/1
          o/i: to-decimal t/2
        ] return o
      ]
    ]
    fail/where ajoin [
      "Cannot make complex! from " mold def
    ] backtrace 4
  ]
  assert [complex? def] ;; TO
  switch type [
    :block! [return reduce [def/r def/i]]
    :string! [return complex-form def]
  ]
  fail/where ajoin ["Cannot convert complex! to " type] backtrace 3
]

i: complex-make complex! [0 1]

+i: enfix func [
  v1 [<tight> any-number!]
  v2 [<tight> any-number!]
] [
  complex-make complex! reduce [v1 v2]
]

-i: enfix func [
  v1 [<tight> any-number!]
  v2 [<tight> any-number!]
] [
  complex-make complex! reduce [v1 negate v2]
]

complex!/form: complex-form: func [
  value [<opt> any-value!]
  /delimit delimiter [blank! any-scalar! any-string! block!]
  /quote /new
  r: frame:
] [
  ajoin either value/i < 0
  [[value/r "-i" negate value/i]]
  [[value/r "+i" value/i]]
]

complex!/mold: func [value /only /all /flat r:] [
  lib/ajoin ["make complex! [" value/r space value/i "]"]
]

complex!/print: func [value] [
  print complex-form value
]

complex!/add: func [v1 v2 v:] [
  v1: complex-make complex! v1 v2: complex-make complex! v2
  v: complex-make complex! reduce[
    add v1/r v2/r
    add v1/i v2/i
  ]
]

complex!/subtract: func [v1 v2 v:] [
  v1: complex-make complex! v1 v2: complex-make complex! v2
  v: complex-make complex! reduce[
    subtract v1/r v2/r
    subtract v1/i v2/i
  ]
]

complex!/multiply: func [v1 v2 v:] [
  v1: complex-make complex! v1 v2: complex-make complex! v2
  v: complex-make complex! reduce[
    subtract
      multiply v1/r v2/r
      multiply v1/i v2/i
    add
      multiply v1/r v2/i
      multiply v1/i v2/r
  ]
]

complex!/divide: func [v1 v2 v: r2:] [
  v1: complex-make complex! v1 v2: complex-make complex! v2
  v: complex-make complex! reduce[
    add
      multiply v1/r v2/r
      multiply v1/i v2/i
    subtract
      multiply v1/i v2/r
      multiply v1/r v2/i
  ]
  r2: add
      multiply v2/r v2/r
      multiply v2/i v2/i
  v/r: divide v/r r2
  v/i: divide v/i r2
  v
]

complex!/absolute: complex-abs: func [v] [
  square-root add
    multiply v/r v/r
    multiply v/i v/i
]

atan2: func [y x a:] [
  either (absolute x) >= (absolute y) [
    if zero? x [return 0]
    a: arctangent/radians (y / x)
  ][
    a: (pi / 2) - arctangent/radians (x / y)
  ]
  if x + y < 0 [a: a - pi]
  if all [x + y = 0  x < 0] [a: a + pi]
  if a + pi <= 0 [a: a + pi + pi]
  a
]

angle: func [z] [
  atan2 z/i z/r
]

complex!/log-e: func [z o:] [
  o: make map! 3
  unless o/r: log-e complex-abs z [
    make error! _
  ]
  o/type: complex!
  o/i: atan2 z/i z/r
  o
]

complex!/exp: func [z o: r:] [
  o: make map! 3
  o/type: complex!
  r: exp z/r
  o/i: r * sine/radians z/i
  o/r: r * cosine/radians z/i
  o
]
; vim: set syn=rebol ts=2 sw=2 sts=2:
