REBOL [
	Title: "Customize functions"
	Author: "giuliolunati@gmail.com"
	Version: 0.1.0
	Type: module
	Name: 'custom
  Exports: [custom customize]
]

indented-line: "^/"
indent+: does [append indented-line "    "]
indent-: does [loop 4 [take/last indented-line]]
mold-stack: lib/make block! 8

mold-recur?: func [x] [
  for-each y mold-stack [
    if same? x y [return true]
  ]
  false
]

custom-type?: func [x] [
  all [map? x any-function? :x/make]
]

fail-invalid-parameter: func [
  func-name [string! word!]
  params [block! word!]
] [
  either word? params [
    fail/where ajoin [
      "Invalid parameter for " func-name ": "
      custom/form get params
    ] params
  ] [
    fail/where ajoin [
      "Invalid parameters for " func-name ": "
      map-each x params [custom/form get x]
    ] params/1
  ]
]

customize: proc ['where f:] [
  foreach w bind/new words-of custom where [
    set w :custom/:w
  ]
  foreach [o p] bind/new infix-alias where [
    set/lookback o tighten :custom/:p
  ]
  foreach [a b] bind/new prefix-alias where [
    set a :custom/:b
  ]
]

try-method: func [method arg] [
  all [
    attempt [method: :arg/custom-type/:method]
    attempt [method arg]
  ]
]

try-method-1: func [method arg1 arg2] [
  all [
    attempt [method: :arg1/custom-type/:method]
    attempt [method arg1 arg2]
  ]
]

try-method-2: func [method arg1 arg2] [
  all [
    attempt [method: :arg2/custom-type/:method]
    attempt [method arg1 arg2]
  ]
]

custom: make object! [

make: adapt :lib/make [
  if custom-type? get first lookahead [
    type: take type
    def: take def
    exit/from/with 2 type/make type def
  ]
]

to: adapt :lib/to [
  if all [
    map? value
    custom-type? :value/custom-type
  ][
    exit/from/with 2 value/custom-type/make type value
  ]
]

form: func [
  value [<opt> any-value!]
  /delimit delimiter [blank! any-scalar! any-string! block!]
  /quote /new
  r: frame: delim:
  ] [
  frame: [value: value delimit: delimit if delimit [delimiter: delimiter] quote: quote new: new]
  if r: attempt [apply :value/custom-type/form frame]
  [return r]

  if any [block? :value group? :value] [
    r: copy ""
    either mold-recur? :value [append r "..."]
    [
      append/only mold-stack :value
      if all[new not quote] [value: reduce :value]
      delim: case [
        not all [new delimit] [space]
        block? delimiter [take delimiter]
        true [delimiter]
      ]
      forall value [
        if all [delim not head? :value] [append r delim]
        append r apply :form [value: value/1 delimit: delimit if delimit [delimiter: delimiter] quote: quote new: new]
      ]
      take/last mold-stack
    ]
    return r
  ]

  if map? :value [
    r: copy ""
    either mold-recur? :value [append r "..."]
    [
      append/only mold-stack :value
      for-each i :value [repend r [
        mold i space
        apply :mold [value: select :value i delimit: delimit if delimit [delimiter: delimiter] quote: quote new: new]
        indented-line
      ]]
      take/last mold-stack
    ]
    return r
  ]

  if object? :value [
    r: copy ""
    either mold-recur? :value [append r "..."]
    [
      append/only mold-stack :value
      for-each i :value [repend r [
        mold i ": "
        apply :mold [value: select :value i delimit: delimit if delimit [delimiter: delimiter] quote: quote new: new]
        indented-line
      ]]
      take/last mold-stack
    ]
    return r
  ]

  apply :lib/form frame
]

mold: func [
  value [any-value!]
  /only /all /flat
  r: line: lines:
  ] [
  if r: attempt [
    apply :value/custom-type/mold [value: :value only: only all: all flat: flat]
  ]
  [return r]

  line: either flat [:newline][:indented-line]

  if any [block? :value group? :value] [
    if group? :value [only: false]
    unless only [indent+]
    r: copy either group? :value ["("]
    [either only [""] ["["]]
    lines: false
    either mold-recur? :value [append r "..."]
    [
      append/only mold-stack :value
      forall value [
        if new-line? :value [
          lines: true
          if r > "" [append r line]
        ]
        append r apply :mold [value: value/1 only: false all: all flat: flat]
        append r space
      ]
      take/last r
      take/last mold-stack
    ]
    unless only [indent- if lines [append r line]]
    return append r either group? :value [")"]
    [either only [""] ["]"]]
  ]

  if map? :value [
    r: copy either all
    ["#[map! ["] ["make map! ["]
    either mold-recur? :value [append r "..."]
    [
      append/only mold-stack :value
      indent+
      for-each i :value [repend r [
          line
          mold i space
          apply :mold [value: select :value i only: false all: all flat: flat]
      ]]
      indent-
      append r line
      take/last mold-stack
    ]
    append r either all ["]]"] [#"]"]
    return r
  ]

  if object? :value [
    r: copy either all
    ["#[object! ["] ["make object! ["]
    either mold-recur? :value [append r "..."]
    [
      append/only mold-stack :value
      indent+
      repend r [line "[self: "]
      for-each i :value [repend r [mold i space]]
      take/last r
      repend r [#"]" line #"["]
      indent+
      for-each i :value [repend r [
          line
          mold i ": "
          apply :mold [value: select :value i only: false all: all flat: flat]
      ]]
      indent-
      repend r [line #"]"]
      indent-
      take/last mold-stack
    ]
    repend r [line either all ["]]"] ["]"]]
    return r
  ]

  apply :lib/mold [value: :value only: only all: all flat: flat]
]

ajoin: func [
  block [block!]
  /delimit delimiter
  ] [
  unless delimit [delimiter: _]
  apply :form [
    value: block new: true
    delimit: true
    delimiter: delimiter
  ]
]

print: proc [
  :lookup [any-value! <...>]
  value [any-value! <...>]
  /only
  /delimit delimiter
  /quote
  /eval
  l: v: 
  ] [
  l: first lookup
  v: take value
  if attempt [apply :value/custom-type/print [
    value: v eval: eval quote: quote delimit: delimit
    if delimit [delimiter: delimiter]
  ] ] [leave]

  if all [block? v not block? l] [
    lib/print v ; fail !!
    leave
  ]
  
  either only [
    lib/print/only apply :form [
      value: v new: true quote: quote
      delimit: true delimiter: _
    ]
  ][
    lib/print apply :form [
      value: v new: true quote: quote
      delimit: delimit
      if delimit [delimiter: delimiter]
    ]
  ]
]

probe: func [value [any-value!] /form] [
  lib/print either f
  [custom/form :value]
  [mold :value]
  :value
]

add: func [value1 value2] [any [
  attempt [lib/add value1 value2]
  try-method-1 'add value1 value2
  try-method-2 'add value1 value2
  fail-invalid-parameter 'add [value1 value2]
]]

subtract: func [value1 value2] [any [
  attempt [lib/subtract value1 value2]
  try-method-1 'subtract value1 value2
  try-method-2 'subtract value1 value2
  fail-invalid-parameter 'subtract [value1 value2]
]]

multiply: func [value1 value2] [any [
  attempt [lib/multiply value1 value2]
  try-method-1 'multiply value1 value2
  try-method-2 'multiply value1 value2
  fail-invalid-parameter 'multiply [value1 value2]
]]

divide: func [value1 value2] [any [
  attempt [lib/divide value1 value2]
  try-method-1 'divide value1 value2
  try-method-2 'divide value1 value2
  fail-invalid-parameter 'divide [value1 value2]
]]

absolute: func [value] [any [
  attempt [lib/absolute value]
  try-method 'absolute value
  fail-invalid-parameter 'absolute 'value
]]

negate: func [value] [any [
  attempt [lib/negate value]
  try-method 'negate value
  fail-invalid-parameter 'negate 'value
]]

zero?: func [value] [any [
  attempt [lib/zero? value]
  try-method 'zero? value
  fail-invalid-parameter 'zero? 'value
]]

log-e: func [value] [any [
  attempt [lib/log-e value]
  try-method 'log-e value
  fail-invalid-parameter 'log-e 'value
]]

exp: func [value] [any [
  attempt [lib/exp value]
  try-method 'exp value
  fail-invalid-parameter 'exp 'value
]]

power: func [number exponent] [any [
  attempt [lib/power number exponent]
  try-method-1 'power number exponent
  try-method-2 'power number exponent
  fail-invalid-parameter 'power [number exponent]
]]

square-root: func [value] [any [
  attempt [lib/square-root value]
  try-method 'square-root value
  fail-invalid-parameter 'square-root 'value
]]

sin: func [value] [any [
  attempt [lib/sine/radians value]
  try-method 'sin value
  fail-invalid-parameter 'sin 'value
]]

cos: func [value] [any [
  attempt [lib/cosine/radians value]
  try-method 'cos value
  fail-invalid-parameter 'cos 'value
]]

tan: func [value] [any [
  attempt [lib/tangent/radians value]
  try-method 'tan value
  fail-invalid-parameter 'tan 'value
]]

asin: func [value] [any [
  attempt [lib/arcsine/radians value]
  try-method 'asin value
  fail-invalid-parameter 'asin 'value
]]

acos: func [value] [any [
  attempt [lib/arccosine/radians value]
  try-method 'acos value
  fail-invalid-parameter 'acos 'value
]]

atan: func [value] [any [
  attempt [lib/arctangent/radians value]
  try-method 'atan value
  fail-invalid-parameter 'atan 'value
]]
] ; custom object

infix-alias: [+ add  - subtract  * multiply  / divide  ** power]
prefix-alias: [abs absolute  log log-e  sqrt square-root]

; vim: set syn=rebol ts=2 sw=2 sts=2:
