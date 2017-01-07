demo: func [code] [
  for-each code code [
    case [
      string? code [
        for-each x split code [
          newline some space
        ] [print x]
      ]
      block? code [
        print [">> html-from-rem" mold code]
        print "==="
        print html-from-rem/secure code
        print "---"
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
  "TO-HTML converts to HTML:"
  ["&, <, > are &-coded"]
  "(NOTE HTML encoding)"
  _
  "NOTE - only last node is returned:"
  ["bold" " normal" space "italic"]
  "But you can use GROUP:"
  [group ["bold" " normal" space "italic"]]
  _
  "Tags are (variadic) functions..."
  [p [b "bold" "normal" br i "italic" ]]
  {They accept optional args before content:
  - issue for id
  - .word or refinement for class
  -- (NOTE: .foo and /foo are equivalent)
  - set-word + value for css style
  - word= for attribute}
  [p .foo1 #bar width= 100 font-size: "10pt" /foo2 color: 'red "content"]
  _
  "STYLE tag has its own (limited) syntax:"
  [style [
    #foo .bar /foobar font-size: 95%
    p h1 text-align: center border: "1pt red solid"
  ] ]
  _
  "No 'HTML, use 'DOC instead:"
  [doc [head _ body _]]
  {NOTE '_ for ""}
  _
  "You can define your own templates:"
  [ bi: func [x y] [group [b x "&" i y]]
    bi "< bold" "italic >"
  ]
]
;; vim: set syn=rebol sw=2 ts=2 sts=2 expandtab:
