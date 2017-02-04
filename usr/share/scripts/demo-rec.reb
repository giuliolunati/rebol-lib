demo: func [code x: ret:] [
  forall code [
    x: code/1
    case [
      string? x [
        for-each x split x [
          newline some space
        ] [print x]
      ]
      block? x [
        print [">>" mold/only x]
        ret: probe do x
      ]
      group? x [
        x: to block! x
        print [">>" mold/only x]
        do x
      ]
      x = _ [print/only newline]
      x = 'quit [quit]
      x = '= [
        code: next code
        unless ret = code/1 [
          print ajoin [
            "** " mold code/1 " expected"
          ]
          quit/with 1
        ]
      ]
    ]
  ]
]
demo [
  "Import module:"
  (import 'rec)
  _
  [load-rec [
    x: y + z
    repeat i n - 1 [x: 6 / y]
    f [5 x - 2 7]
  ] ]
]
;; vim: set syn=rebol sw=2 ts=2 sts=2 expandtab:
