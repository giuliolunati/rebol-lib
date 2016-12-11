REBOL [
  Title: "Fractions"
  Author: "giuliolunati@gmail.com"
  Version: 0.1.0
  Type: module
  Name: 'fraction
  Exports: [fraction! fraction? to-fraction gcd]
]

custom: import 'custom
custom: custom/custom

decimal-to-fraction: func [
  x r: n1: d1: n2: d2: n: t:
][
  n1: d2: 0  n2: d1: 1 r: x
  forever [
    n: to-integer r
    t: n * n2 + n1
    n1: n2  n2: t
    t: n * d2 + d1
    d1: d2  d2: t
    if n = x [break]
    if n2 / d2 - x = 0 [break]
    r: 1 / (r - n)
  ]
  forever [
    n2: n2 - n1  d2: d2 - d1
    if n2 / d2 - x != 0 [break]
  ]
  to-fraction [n2 + n1  d2 + d1]
]

gcd: func [a [integer!] b [integer!] r:] [
  while [b != 0] [
    r: a // b  a: b  b: r
  ] abs a
]

fraction!: make map! 8

fraction?: func [x] [
  either attempt [same? x/custom-type fraction!]
  [true] [false]
]

custom-divide-bak: :custom/divide
custom/divide: func [value1 value2] [
  if all [integer? value1 integer? value2] [
    return to-fraction [value1 value2]
  ]
  custom-divide-bak value1 value2
]

to-fraction: func [def o: t:] [
  if fraction? def [return def]
  if decimal? def [
    return decimal-to-fraction def
  ]
  o: make map! reduce [
    'custom-type fraction!
    'n 0 'd 1
  ]
  case [
    integer? def [o/n: def]
    block? def [
      def: reduce def
      o/n: def/1  o/d: def/2
    ]
    string? def [
      t: split def #"/"
      o/n: to-integer t/1
      o/d: to-integer t/2
    ]
    true [fail/where ajoin [
      "Cannot make fraction! from " mold def
    ] backtrace 5]
  ]
  if zero? o/d [fail/where ajoin [
      "Cannot make fraction! from " mold def
  ] backtrace 5]
  t: gcd o/n o/d
  if t > 1 [o/n: o/n / t  o/d: o/d / t]
  if o/d < 0 [o/n: negate o/n  o/d: negate o/d]
  o
]

fraction!/make: f-make: func [type def] [
  if same? type fraction! [ ;; MAKE
    if fraction? def [return copy def]
    return to-fraction def
  ]
  unless fraction? def [return make type def]
  ;; TO
  switch type [
    :decimal! [return def/n / def/d]
    :block! [return reduce [def/n def/d]]
    :string! [return c-form def]
  ]
  fail/where ajoin ["Cannot convert fraction! to " type] backtrace 3
]

fraction!/form: c-form: func [
  value [<opt> any-value!]
  /delimit delimiter [blank! any-scalar! any-string! block!]
  /quote /new
  r: frame:
] [ajoin [value/n "/" value/d]]

fraction!/mold: func [value /only /all /flat r:] [
  lib/ajoin ["make fraction! [" value/n space value/d "]"]
]

fraction!/add: func [x y n: d:] [
  x: to-fraction x  y: to-fraction y
  d: gcd x/d y/d
  n: (y/d / d * x/n) + (x/d / d * y/n)
  d: x/d / d * y/d
  to-fraction [n d]
]

fraction!/subtract: func [x y n: d:] [
  x: to-fraction x  y: to-fraction y
  d: gcd x/d y/d
  n: (y/d / d * x/n) - (x/d / d * y/n)
  d: x/d / d * y/d
  to-fraction [n d]
]

fraction!/multiply: func [x y n: d:] [
  x: to-fraction x  y: to-fraction y
  n: gcd x/n y/d
  d: gcd x/d y/n
  to-fraction [
    x/n / n * y/n / d
    x/d / d * y/d / n
  ]
]

fraction!/divide: func [x y n: d:] [
  x: to-fraction x  y: to-fraction y
  n: gcd x/n y/n
  d: gcd x/d y/d
  to-fraction [
    x/n / n * y/d / d
    x/d / d * y/n / n
  ]
]

fraction!/zero?: func [x] [zero? x/n]

fraction!/negate: func [x] [
  x: copy x
  x/n: negate x/n
  x
]

fraction!/power: func [x y n: d:] [
  n: x/n ** y
  d: x/d ** y
  any [
    attempt [all [
      zero? n // 1
      zero? d // 1
      to-fraction [to-integer n  to-integer d]
    ]]
    (x/n / x/d) ** y
  ]
]

fraction!/square-root: func [x n: d:] [
  n: square-root x/n
  d: square-root x/d
  any [
    all[
      zero? n // 1
      zero? d // 1
      to-fraction [to-integer n  to-integer d]
    ]
    n / d
  ]
]

fraction!/equal?: f-=: func [x y] [
  if all [fraction? x fraction? y] [
    return (x/n * y/d) = (x/d * y/n)
  ]
  (f-make decimal! x) = (f-make decimal! y)
]

fraction!/strict-equal?: func [x y] [
  if all [fraction? x fraction? y] [
    return (x/n * y/d) = (x/d * y/n)
  ]
  false
]

fraction!/lesser?: func [x y r:] [
  if all [fraction? x fraction? y] [
    return either (sign? y/d) = (sign? x/d)
    [(x/n * y/d) < (x/d * y/n)]
    [(x/d * y/n) < (x/n * y/d)]
  ]
  (f-make decimal! x) < (f-make decimal! y)
]

fraction!/lesser-or-equal?: func [x y r:] [
  if all [fraction? x fraction? y] [
    return either (sign? y/d) = (sign? x/d)
    [(x/n * y/d) <= (x/d * y/n)]
    [(x/d * y/n) <= (x/n * y/d)]
  ]
  (f-make decimal! x) < (f-make decimal! y)
]

; vim: set syn=rebol ts=2 sw=2 sts=2:
