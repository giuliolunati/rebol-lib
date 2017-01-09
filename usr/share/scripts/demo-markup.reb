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
  (import 'markup)
  _
  "Example of ReM code:"
  {rem [p ["paragraph" br "breakline" ]]}
  _
  "HTML|REM convert it to HTML:"
  [html-rem [rem [p ["paragraph" br "breakline" ]]]]
  _
  {[REM [...]] is a document,
  while [REM ...] is a fragment:}
  [html-rem [rem p ["paragraph" br "breakline" ]]]
  _
  {Text is wrote as strings, tags as words:}
  [html-rem [rem b "bold" hr i "italic"]]
  _
  "Spaces must be explicitly inserted in strings, or with SPACE:"
  [html-rem [rem b "bold" space "normal " i "italic"]]
  [html-rem [rem i "this" "has" b "no" "spaces"]]
  _
  [html-rem [rem "< & > are straightforward."]]
  {Tags accept optional attributes before content:
  - attribute: /refinement value
  - style: set-word: value [...] }
  [html-rem [rem p /width 100 font-size: ajoin [10 "pt"] color: 'red "content"]]
  "NOTE: values are evaluated!"
  _
  {Other special cases:
  - id: #issue
  - class: .word [...]
  - href, src: %file or url://...}
  [html-rem [rem a #foo http://www.example.com img .bar1 .bar2 %test.png]]
  _
  "STYLE tag has its own (limited) syntax:"
  [html-rem [rem style [
    #foo .bar .foobar font-size: 95%
    p h1 text-align: center border: "1pt red solid"
  ] ] ]
  _
  "You can define your own templates before REM:"
  [html-rem [bi: func [x y] [rem b x "&" i y]
    rem [bi "< bold" "italic >"]
  ]]
]
;; vim: set syn=rebol sw=2 ts=2 sts=2 expandtab:
