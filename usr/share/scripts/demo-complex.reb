REBOL [
	Title: "Demo for 'complex module"
	Type: 'script
	Require: 'complex
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
  "=== COMPLEX MODULE DEMO ==="
  _
  "First of all, import:"
  (import 'complex)
  _
  {NOTE: 'complex module is based on 'custom, 
  that needs to be enabled:}
  (customize self)
  _
  {Make complex value with MAKE
  from number, block or string: ...}
	[make complex! 3]
	[a: make complex! [1 2]]
	[make complex! "1-i2"]
  _
  {... or with '+i and '-i operators:}
  [b: 2 +i 1]
  [c: 2 -i 3]
  _
  "NOTE: 'i is imaginary unit: "
  [i]
  _
  "Convert to BLOCK! or to STRING!:"
  [mold to block! a]
  [mold to string! a]
  _
  "Test a value with 'complex? and 'zero? :"
  [complex? b] [complex? 3.1]
  [zero? 0 +i 0]
  _
  "Comparison:"
  [(2 +i 0) = 2]
  [(2 +i 0) == 2]
  _
  "Some arithmetics:"
  [[a "," b]]
  [negate a] [a + b] [a - b] [a * b] [a / b]
  _
  "Also mixed with real numbers:"
  [2 +i 3 * 2] [1 / (1 -i 2)]
  _
  "Logarithm and exponential:"
  [y: log (-1 +i 0)]
  [exp y]
  [y: exp (3 +i (2 * pi + 1))]
  [log y]
  [log -1]
  _
  "Power and square-root:"
  [power (0.866 +i 0.5) 12]
  [2 ** (1 + i)]j
  [z: square-root (2 * i)]
  [z: sqrt z]
  [sqrt -1]
  _
  "Trigonometrics:"
  [z: cos (i + 1)]
  [acos z]
  [z: sin (i + 1)]
  [asin z]
  [z: tan (i + 1)]
  [atan z]
]
; vim: set syn=rebol ts=2 sw=2 sts=2:
