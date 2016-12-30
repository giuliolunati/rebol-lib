demo: func [code] [
  for-each code code [
    case [
      string? code [
        for-each x split code [
          newline some space
        ] [print [newline x]]
      ]
      block? code [
        print [">> to-html" mold code]
        print "=="
        print [to-html code]
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
  (import 'remark)
  "TO-HTML converts to HTML:"
  ["&, <, > are &-coded"]
  "(NOTE HTML encoding)"
  "Tags are (variadic) functions..."
  [p [b "bold" "normal" br i "italic" ]]
  "They accept optional args before content:"
  [p .myclass #myid /myotherclass "content"]
  "(NOTE: .class and /class are equivalent)"
  "NOTE only last node is returned:"
  [b "bold" " normal " i "italic"]
  "But you can use AJOIN:"
  [ajoin [b "bold" " normal " i "italic"]]
  "You can define your own funcs:"
  [ bi: func [x y] [ajoin [b x "&" i y]]
    bi "< bold" "italic >"
  ]
]
;; vim: set syn=rebol sw=2 ts=2 sts=2 expandtab:
