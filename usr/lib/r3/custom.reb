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

  if any[block? value group? value] [
    r: copy ""
    either mold-recur? value [append r "..."]
    [
      append/only mold-stack value
      if all[new not quote] [value: reduce value]
      delim: case [
        not all [new delimit] [space]
        block? delimiter [take delimiter]
        true [delimiter]
      ]
      forall value [
        if all [delim not head? value] [append r delim]
        append r apply :form [value: value/1 delimit: delimit if delimit [delimiter: delimiter] quote: quote new: new]
      ]
      take/last mold-stack
    ]
    return r
  ]

  if map? value [
    r: copy ""
    either mold-recur? value [append r "..."]
    [
      append/only mold-stack value
      for-each i value [repend r [
        mold i space
        apply :mold [value: select value i delimit: delimit if delimit [delimiter: delimiter] quote: quote new: new]
        indented-line
      ]]
      take/last mold-stack
    ]
    return r
  ]

  if object? value [
    r: copy ""
    either mold-recur? value [append r "..."]
    [
      append/only mold-stack value
      for-each i value [repend r [
        mold i ": "
        apply :mold [value: select value i delimit: delimit if delimit [delimiter: delimiter] quote: quote new: new]
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
    apply :value/custom-type/mold [value: value only: only all: all flat: flat]
  ]
  [return r]

  line: either flat [:newline][:indented-line]

  if any[block? value group? value] [
    if group? value [only: false]
    unless only [indent+]
    r: copy either group? value ["("]
    [either only [""] ["["]]
    lines: false
    either mold-recur? value [append r "..."]
    [
      append/only mold-stack value
      forall value [
        if new-line? value [
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
    return append r either group? value [")"]
    [either only [""] ["]"]]
  ]

  if map? value [
    r: copy either all
    ["#[map! ["] ["make map! ["]
    either mold-recur? value [append r "..."]
    [
      append/only mold-stack value
      indent+
      for-each i value [repend r [
          line
          mold i space
          apply :mold [value: select value i only: false all: all flat: flat]
      ]]
      indent-
      append r line
      take/last mold-stack
    ]
    append r either all ["]]"] [#"]"]
    return r
  ]

  if object? value [
    r: copy either all
    ["#[object! ["] ["make object! ["]
    either mold-recur? value [append r "..."]
    [
      append/only mold-stack value
      indent+
      repend r [line "[self: "]
      for-each i value [repend r [mold i space]]
      take/last r
      repend r [#"]" line #"["]
      indent+
      for-each i value [repend r [
          line
          mold i ": "
          apply :mold [value: select value i only: false all: all flat: flat]
      ]]
      indent-
      repend r [line #"]"]
      indent-
      take/last mold-stack
    ]
    repend r [line either all ["]]"] ["]"]]
    return r
  ]

  apply :lib/mold [value: value only: only all: all flat: flat]
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
  attempt [value1/custom-type/add value1 value2]
  attempt [value2/custom-type/add value1 value2]
  lib/add value1 value2 ;; raise error
]]

subtract: func [value1 value2] [any [
  attempt [lib/subtract value1 value2]
  attempt [value1/custom-type/subtract value1 value2]
  attempt [value2/custom-type/subtract value1 value2]
  lib/subtract value1 value2 ;; raise error
]]

multiply: func [value1 value2] [any [
  attempt [lib/multiply value1 value2]
  attempt [value1/custom-type/multiply value1 value2]
  attempt [value2/custom-type/multiply value1 value2]
  lib/multiply value1 value2 ;; raise error
]]

divide: func [value1 value2] [any [
  attempt [lib/divide value1 value2]
  attempt [value1/custom-type/divide value1 value2]
  attempt [value2/custom-type/divide value1 value2]
  lib/divide value1 value2 ;; raise error
]]

absolute: func [value] [any [
  attempt [lib/absolute value]
  attempt [value/custom-type/absolute value]
  lib/absolute value ;; raise error
]]

negate: func [value] [any [
  attempt [lib/negate value]
  attempt [value/custom-type/negate value]
  lib/negate value ;; raise error
]]

log-e: func [value f:] [any [
  attempt [lib/log-e value]
  attempt [value/custom-type/log-e value]
  fail/where ajoin ["Invalid parameter for log: " form value] 'value
]]

exp: func [value] [any [
  attempt [lib/exp value]
  attempt [value/custom-type/exp value]
  lib/exp value ;; raise error
]]

] ; custom object

infix-alias: [+ add - subtract * multiply / divide]
prefix-alias: [abs absolute log log-e]

customize: proc ['where f:] [
  foreach w bind words-of custom where [
    set w :custom/:w
  ]
  foreach [o p] bind infix-alias where [
    set/lookback o tighten :custom/:p
  ]
  foreach [a b] bind prefix-alias where [
    set a :custom/:b
  ]
]

; vim: set syn=rebol ts=2 sw=2 sts=2:
