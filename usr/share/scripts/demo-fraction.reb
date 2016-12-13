REBOL [
  Title: "Demo for 'fraction module"
  Type: 'script
  Author: "giuliolunati@gmail.com"
  Version: 0.1.0
]

demo: func [code] [
  for-each code code [
    case [
      string? code [
        for-each x split code [
          newline some space
        ] [print x]
      ]
      block? code [
        print [">>" mold/only code]
        print ['== do code]
      ]
      group? code [
        code: to block! code
        print [">>" mold/only code]
        do code
      ]
      code = _ [print/only newline]
      code = 'quit [quit]
    ]
  ]
]
;;; MAIN
demo [
  _
  "=== FRACTION MODULE DEMO ==="
  _
  "First of all, import:"
  (import 'fraction)
  _
  {NOTE: 'fraction module is based on 'custom, 
  that needs to be enabled:}
  (customize self)
  _
  {Make fraction value with MAKE FRACTION!
  or TO-FRACTION (indifferently)
  from number, block or string: ...}
  [make fraction! 3]
  [make fraction! [1 2]]
  [to-fraction "1/2"]
  [to-fraction sqrt 2]
  _
  "... or with '/ and integers:"
  [3 / 4]
  "But note:"
  [3.0 / 4]
  _
  "NOTE: result is simplified by GCD"
  [a: to-fraction [30 -42]]
  "Greater Common Divisor:"
  [gcd 30 -42]
  _
  "Convert to DECIMAL!, BLOCK! or STRING! :"
  [mold to block! a]
  [mold to string! a]
  [mold to decimal! a]
  _
  "Test a value with 'fraction? and 'zero? :"
  [fraction? a] [fraction? 3.1]
  [zero? (0 / 5)]
  _
  "Comparison:"
  [(3 / 5) == (6 / 10)]
  [(3 / 5) == 0.6]
  [(3 / 5) = 0.6]
  [(3 / 5) < (2 / 3)]
  [(3 / 5) > 0.6]
  _
  "Arithmetics:"
  (a: 7 / 30  b: 5 / 42)
  [negate a]
  [a + b] [a - b] [a * b] [a / b]
  _
  "Power and sqrt:"
  [2 / 3 ** 4]
  [2 / 3 ** 400]
  [2 / 3 ** 0.5]
  [sqrt (16 / 81)]
  [sqrt (2 / 3)]
  _
  "Approximate real by fraction:"
  (precision: 0.001)
  [f: approximate exp 1 precision]
  [abs (f - exp 1)]
  [f: approximate pi 1e-5]
  [to decimal! f]
  [pi]
  [f: to-fraction pi]
  [f: approximate pi 0]
  [f = pi]
  _
  "Numeric functions allowed w/o conversion:"
  "(Note: 87/32 ~ e, 355/113 ~ pi)"
  [log (87 / 32)]
  [cos (355 / 113)]
]
; vim: set syn=rebol ts=2 sw=2 sts=2:

