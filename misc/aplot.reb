canvas: object [
  init: func [wid hei] [
    screen: make string! wid * hei
    loop hei [
      append/dup screen "." wid
      append screen newline
    ]
  ]
  show: does [print screen]
]

canvas/init 7 9
canvas/show
; vim: set syn=rebol sw=2 ts=2:
