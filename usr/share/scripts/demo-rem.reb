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
        print "---"
        probe do code
        print "==="
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
demo [
  "Import module:"
  (import 'rem)
  _
  "Example of ReM code:"
  {rem [p ["paragraph" br "breakline" ]]}
  _
  "LOAD-REM convert it to document tree (DoT):"
  [load-rem [rem [p ["paragraph" br "breakline" ]]]]
  _
  {[REM [...]] is a document,
  while [REM ...] is a fragment:}
  [load-rem [rem p ["paragraph" br "breakline" ]]]
  _
  {Text is wrote as strings, tags as words:}
  [load-rem [rem b "bold" hr i "italic"]]
  _
  "Spaces must be explicitly inserted in strings, or with SPACE:"
  [load-rem [rem b "bold" space "normal " i "italic"]]
  [load-rem [rem i "this" "has" b "no" "spaces"]]
  _
  [load-rem [rem "< & > are straightforward."]]
  {Tags accept optional attributes before content:
  - attribute: /refinement value
  - style: set-word: value [...] }
  [load-rem [rem p /width 100 font-size: ajoin [10 "pt"] color: 'red "content"]]
  "NOTE: values are evaluated!"
  _
  {Other special cases:
  - id: #issue
  - class: .word [...]
  - href, src: %file or url://...}
  [load-rem [rem a #foo http://www.example.com img .bar1 .bar2 %test.png]]
  _
  "STYLE tag has its own (limited) syntax:"
  [load-rem [rem style [
    #foo .bar .foobar font-size: 95%
    p h1 text-align: center border: "1pt red solid"
  ] ] ]
  _
  "You can define your own templates before REM:"
  [load-rem [bi: func [x y] [rem b x "&" i y]
    rem [bi "< bold" "italic >"]
  ]]
]
;; vim: set syn=rebol sw=2 ts=2 sts=2 expandtab:
