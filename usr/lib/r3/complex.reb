REBOL [
	Title: "Complex numbers"
	Author: "giuliolunati@gmail.com"
	Version: 0.1.0
	Type: module
	Name: 'complex
  Exports: [complex! complex? i +i -i]
]

import 'customize

complex!: self

complex?: func [x] [
  either attempt [same? x/type complex!]
  [true] [false]
]

make: func [def o:] [
  if complex? def [return def]
  o: lib/make map! reduce [
    'type complex!
    'r 0 'i 0
  ]
  case [
    number? def [o/r: def]
    block? def [o/r: def/1 o/i: def/2]
    true [fail ajoin ["Cannot make complex! from " mold def] ]
  ]
  o
]

i: make [0 1]

+i: enfix func [
  v1 [<tight> any-number!]
  v2 [<tight> any-number!]
] [
  make reduce [v1 v2]
]

-i: enfix func [
  v1 [<tight> any-number!]
  v2 [<tight> any-number!]
] [
  make reduce [v1 negate v2]
]

form: func [
  value [<opt> any-value!]
  /delimit delimiter [blank! any-scalar! any-string! block!]
  /quote /new
  r: frame:
] [
  ajoin either value/i < 0
  [[value/r " -i " negate value/i]]
  [[value/r " +i " value/i]]
]

mold: func [value /only /all /flat r:] [
  lib/ajoin ["make complex! [" value/r space value/i "]"]
]

print: func [value] [
  lib/print form value
]

add: func [v1 v2 v:] [
  v1: make v1 v2: make v2
  v: make reduce[
    lib/add v1/r v2/r
    lib/add v1/i v2/i
  ]
]

subtract: func [v1 v2 v:] [
  v1: make v1 v2: make v2
  v: make reduce[
    lib/subtract v1/r v2/r
    lib/subtract v1/i v2/i
  ]
]

multiply: func [v1 v2 v:] [
  v1: make v1 v2: make v2
  v: make reduce[
    lib/subtract
      lib/multiply v1/r v2/r
      lib/multiply v1/i v2/i
    lib/add
      lib/multiply v1/r v2/i
      lib/multiply v1/i v2/r
  ]
]

divide: func [v1 v2 v: r2:] [
  v1: make v1 v2: make v2
  v: make reduce[
    lib/add
      lib/multiply v1/r v2/r
      lib/multiply v1/i v2/i
    lib/subtract
      lib/multiply v1/i v2/r
      lib/multiply v1/r v2/i
  ]
  r2: lib/add
      lib/multiply v2/r v2/r
      lib/multiply v2/i v2/i
  v/r: lib/divide v/r r2
  v/i: lib/divide v/i r2
  v
]

absolute: func [v] [
  lib/square-root lib/add
    lib/multiply v/r v/r
    lib/multiply v/i v/i
]
; vim: set syn=rebol ts=2 sw=2 sts=2:
