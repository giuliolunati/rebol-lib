REBOL [
	Title: "Complex numbers"
	Author: "giuliolunati@gmail.com"
	Version: 0.1.0
	Type: module
	Name: 'complex
  Exports: [complex! complex? to-complex i +i -i]
]

custom: import 'custom
custom: custom/custom

complex!: make map! 8

complex?: func [x] [
  either attempt [same? x/custom-type complex!]
  [true] [false]
]

to-complex: func [def o: t:] [
  if complex? def [return def]
  o: make map! reduce [
    'custom-type complex!
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

complex!/make: func [type def] [
  if same? type complex! [ ;; MAKE
    if complex? def [return copy def]
    return to-complex def
  ]
  assert [complex? def] ;; TO
  switch type [
    :block! [return reduce [def/r def/i]]
    :string! [return c-form def]
  ]
  fail/where ajoin ["Cannot convert complex! to " type] backtrace 3
]

i: to-complex [0 1]

+i: enfix func [
  v1 [<tight> any-number!]
  v2 [<tight> any-number!]
] [
  to-complex reduce [v1 v2]
]

-i: enfix func [
  v1 [<tight> any-number!]
  v2 [<tight> any-number!]
] [
  to-complex reduce [v1 negate v2]
]

complex!/form: c-form: func [
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
  print c-form value
]

complex!/add: c-add: func [v1 v2 v:] [
  v1: to-complex v1 v2: to-complex v2
  v: to-complex reduce[
    add v1/r v2/r
    add v1/i v2/i
  ]
]

complex!/subtract: func [v1 v2 v:] [
  v1: to-complex v1 v2: to-complex v2
  v: to-complex reduce[
    subtract v1/r v2/r
    subtract v1/i v2/i
  ]
]

complex!/multiply: c-mul: func [v1 v2 v:] [
  v1: to-complex v1 v2: to-complex v2
  v: to-complex reduce[
    subtract
      multiply v1/r v2/r
      multiply v1/i v2/i
    add
      multiply v1/r v2/i
      multiply v1/i v2/r
  ]
]

complex!/divide: c-div: func [v1 v2 v: r2:] [
  v1: to-complex v1 v2: to-complex v2
  v: to-complex reduce[
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

complex!/absolute: c-abs: func [v] [
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

complex!/log-e: c-log: func [z o:] [
  o: make map! 3
  unless o/r: log-e c-abs z [
    make error! _
  ]
  o/custom-type: complex!
  o/i: atan2 z/i z/r
  o
]

custom/log-e: adapt :custom/log-e [
  if all [any-number? value  value < 0] [
    value: to-complex value
  ]
]

complex!/exp: c-exp: func [z o: r:] [
  o: make map! 3
  o/custom-type: complex!
  r: exp z/r
  o/i: r * sine/radians z/i
  o/r: r * cosine/radians z/i
  o
]

complex!/power: func [z k r:] [
  if all [integer? k  k > 0] [
    r: 1 
    while [k > 0] [
      if odd? k [-- k r: c-mul r z]
      k: k / 2
      z: c-mul z z
    ]
    return r
  ]
  z: to-complex z
  k: to-complex k
  if all [zero? z/r  zero? z/i] [
    if k/r > 0 [return 0]
    return make error! _
  ]
  c-exp c-mul k c-log z
]

complex!/square-root: c-sqrt: func [z o: r: a:] [
  r: square-root c-abs z
  a: (angle z) / 2
  o: make map! 3
  o/custom-type: complex!
  o/i: r * sine/radians a
  o/r: r * cosine/radians a
  o
]

custom/square-root: adapt :custom/square-root [
  if all [any-number? value  value < 0] [
    value: to-complex value
  ]
]

complex!/sin: c-sin: func [z t:] [
  z: c-exp c-mul i z
  z: c-add z c-div -1 z
  t: z/r / -2  z/r: z/i / 2  z/i: ;t=z/2i
  z
]

complex!/cos: c-cos: func [z t:] [
  z: c-exp c-mul i z
  z: c-add z c-div 1 z
  z/r: z/r / 2  z/i: z/i / 2
  z
]

complex!/tan: func [z s: c: t:] [
  c-div c-sin z c-cos z
]

; vim: set syn=rebol ts=2 sw=2 sts=2:
