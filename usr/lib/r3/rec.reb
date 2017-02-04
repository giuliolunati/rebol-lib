REBOL [
  Name: 'rec
  Type: module
  Author: "Giulio Lunati"
  Email: giuliolunati@gmail.com
  Description: ""
  Exports: [load-rec]
]

fix-words: func [code x: y: set:] [
  forall code [
    x: code/1
    case [
      any [group? x block? x] [fix-words x]
      all [word? x not set? x] [
        code: insert code 'quote
        change code to-lit-word x
      ]
      set-word? x [
        code: insert code to-word bind 'set rec
        code: insert code 'quote
        change code to-lit-word x
      ]
    ]
  ]
  code
]
rec: make object! append [
  +: enfix tighten func [x y] [
    append append copy [add] x y
  ]
  -: enfix tighten func [x y] [
    append append copy [subtract] x y
  ]
  *: enfix tighten func [x y] [
    append append copy [multiply] x y
  ]
  set: func [x y] [
    append append copy [set] x y
  ]
  repeat: func [w [lit-word!] n code] [
    append/only append append copy [repeat] w n
      load-block code
  ]
] compose [ ;; DIRTY HACK -- can't write /:
  (to-set-word #"/") enfix tighten func [x y] [
    append append copy [divide] x y
  ]
]

load-varargs: func [
  args [any-value! <...>]
  :look [any-value! <...>]
  ret: x:
  ][
  ret: make block! 16
  while [not tail? look ] [
    x: first look
    if block? x [
      x: load-block [take args]
      append/only ret x
      continue
    ]
    x: take args
    if lit-word? x [append ret 'apply]
    append ret x
  ]
  ret
]

load-block: func [code [block!]] [
  code: make varargs! code
  apply 'load-varargs [args: code look: code]
]

load-rec: func [code [block!]] [
  load-block fix-words bind code rec
]


;; vim: set syn=rebol sw=2 ts=2 sts=2 expandtab:
