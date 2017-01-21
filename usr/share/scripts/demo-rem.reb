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
  "LOAD-REM convert ReM code to document tree (DoT):"
  [load-rem [p ["paragraph" br "breakline" ]]]
  _
  {Text is wrote as strings, tags as words:}
  [load-rem [b "bold" hr i "italic"]]
  _
  {NOTE: HTML tag is renamed DOC:}
  [load-rem [doc [b "bold" hr i "italic"]]]
  _
  "Spaces must be explicitly inserted in strings, or with SPACE:"
  [load-rem [b "bold" space "normal " i "italic"]]
  [load-rem [i "this" "has" b "no" "spaces"]]
  _
  [load-rem ["< & > are straightforward."]]
  {Tags accept optional attributes before content:
  - attribute: /refinement value
  - style: set-word: value [...] }
  [load-rem [p /width 100 font-size: ajoin [10 "pt"] color: 'red "content"]]
  "NOTE: values are evaluated!"
  _
  {Other special cases:
  - id: #issue
  - class: .word [...]
  - href, src: %file or url://...}
  [load-rem [a #foo http://www.example.com img .bar1 .bar2 %test.png]]
  _
  "STYLE tag has its own (limited) syntax:"
  [load-rem [style [
    #foo .bar .foobar font-size: 95%
    p h1 text-align: center border: "1pt red solid"
  ] ] ]
  _
  _
  "Code in GROUP is executed but result is hidden. Handy for define values:"
  [load-rem [(hw: "Hello, world") b hw]]
  _
  "You can also define functions:"
  [load-rem [
    (bi: func [x y:] [rem [b i x]])
    bi "bold-italic"
  ] ]
  "NOTE 'rem call in function body: 'rem is a quick version of 'load-rem."
  "'rem is variadic, so you can omit []:"
  [load-rem [
    ( contact: func [name phone email] [
      rem b name space i phone space "<" email ">"
    ] )
    contact "John" 333555666777 john@some.where
  ] ]
  [load-rem [viewport 1]]
]

;; vim: set syn=rebol sw=2 ts=2 sts=2 expandtab:
