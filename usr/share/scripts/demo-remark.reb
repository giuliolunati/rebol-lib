import 'remark

print to-html [

bi: func [x y] [ajoin [b x " -- " i y]]

ajoin [
head [
  style [
    .class1 [color: red | font-size: 200%]
    #id1 [font-weight: bold]
    /class2 []
    div [text-align: center]
  ]
]
body [
div p /class1 [
  b #id1 "bold"
  br
  i .class2 "italic"
]
bi "bold" "italic"
33 + 66
]]]
;; vim: set syn=rebol sw=2 ts=2 sts=2:
