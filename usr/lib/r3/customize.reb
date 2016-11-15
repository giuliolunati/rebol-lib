REBOL [
	Title: "Custom Types"
	Author: "giuliolunati@gmail.com"
	Version: 0.1.0
	Type: module
	Name: 'customize
  Exports: [enable-customize]
]

prefix-words: [
  make
  form mold ajoin print probe
  add subtract multiply divide
  absolute
]
op-pairs: [+ add - subtract * multiply / divide]
alias-pairs: [abs absolute]

enable-customize: proc ['where f:] [
  foreach w bind prefix-words where [
    set w :self/:w
  ]
  foreach [o p] bind op-pairs where [
    set/lookback o tighten get :p
  ]
  foreach [a b] bind alias-pairs where [
    set a get :b
  ]
]

make: adapt :lib/make [
  if any [
    module? get first lookahead
    map?  get first lookahead
    object?  get first lookahead
  ] [
    type: take type
    def: take def
    exit/from/with 2 type/make def
  ]
]

indented-line: "^/"
indent+: does [append indented-line "    "]
indent-: does [loop 4 [take/last indented-line]]
mold-stack: make block! 8

mold-recur?: func [x] [
  for-each y mold-stack [
    if same? x y [return true]
  ]
  false
]

form: func [
  value [<opt> any-value!]
  /delimit delimiter [blank! any-scalar! any-string! block!]
  /quote /new
  r: frame: delim:
  ] [
  frame: [value: value delimit: delimit if delimit [delimiter: delimiter] quote: quote new: new]
  if r: attempt [apply :value/type/form frame]
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
    apply :value/type/mold [value: value only: only all: all flat: flat]
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
  if attempt [apply :value/type/print [
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

probe: func [value [any-value!] /f] [
  lib/print either f
  [form :value]
  [mold :value]
  :value
]

add: func [value1 value2] [any [
  attempt [value1/type/add value1 value2]
  attempt [value2/type/add value1 value2]
  lib/add value1 value2
]]

subtract: func [value1 value2] [any [
  attempt [value1/type/subtract value1 value2]
  attempt [value2/type/subtract value1 value2]
  lib/subtract value1 value2
]]

multiply: func [value1 value2] [any [
  attempt [value1/type/multiply value1 value2]
  attempt [value2/type/multiply value1 value2]
  lib/multiply value1 value2
]]

divide: func [value1 value2] [any [
  attempt [value1/type/divide value1 value2]
  attempt [value2/type/divide value1 value2]
  lib/divide value1 value2
]]

absolute: func [value] [any [
  attempt [value/type/absolute value]
  lib/absolute value
]]

; vim: set syn=rebol ts=2 sw=2 sts=2:
