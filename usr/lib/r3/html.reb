REBOL [
  Title: "HTML utils for Ren/C"
  Type: 'module
  Name: 'html
  Exports: [
    load-html
    mold-html
    split-html
  ]
  Needs: [text dot]
  Author: "giuliolunati@gmail.com"
  Version: 0.1.1
]

;=== RULES === 
  !?: charset "!?"
  alpha!: charset [#"A" - #"Z" #"a" - #"z"]
  hexa!: charset [#"A" - #"F" #"a" - #"f" #"0" - #"9"]
  num!: charset [#"0" - #"9"]
  space!: charset " ^/^-^M "
  spacer!: [and string! into[any space!]] 
  mark!: charset "<&"
  quo1!: charset {'\}
  quo2!: charset {"\}
  name!: use [w1 w+] [
    w1: charset [ "ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz" #"^(C0)" - #"^(D6)" #"^(D8)" - #"^(F6)" #"^(F8)" -#"^(02FF)" #"^(0370)" - #"^(037D)" #"^(037F)" - #"^(1FFF)" #"^(200C)" - #"^(200D)" #"^(2070)" - #"^(218F)" #"^(2C00)" - #"^(2FEF)" #"^(3001)" - #"^(D7FF)" #"^(f900)" - #"^(FDCF)" #"^(FDF0)" - #"^(FFFD)" ]
    w+: charset [ "-.0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz" #"^(B7)" #"^(C0)" -#"^(D6)" #"^(D8)" - #"^(F6)" #"^(F8)" - #"^(037D)" #"^(037F)" - #"^(1FFF)" #"^(200C)" - #"^(200D)" #"^(203F)" - #"^(2040)" #"^(2070)" - #"^(218F)" #"^(2C00)" - #"^(2FEF)" #"^(3001)" - #"^(D7FF)" #"^(f900)" - #"^(FDCF)" #"^(FDF0)" - #"^(FFFD)" ]
    [w1 any w+]
  ]
;=== END RULES === 

is-empty: make map! [
  ! true
  ? true
  area true
  base true
  br true
  col true
  embed true
  hr true
  img true
  input true
  keygen true
  link true
  meta true
  param true
  source true
  track true
  wbr true
]

split-html: function [data [string!]] [
  a: b: k: n: t: v: _
  ret: make block! 32
  emit: func [x t:] [
    if x = "" [return _]
    if char? x [x: to string! x]
    if string? x [
      t: to-value last ret
      if string? t [return append t x]
    ]
    append/only ret x
  ]
  entity!: [ #"&"
    [  #"#"
      [  #"x" copy t some hexa! (
          emit do [ ajoin[{"^^(} t {)"}] ]
        )
      |  copy t some num! (
          emit to char! to integer! t
        )
      ]
    | copy t some alpha! (
        emit switch t [
          "nbsp" [#"^(a0)"]
          "amp" [#"&"]
          "lt" [#"<"]
          "gt" [#">"]
          (to tag! t)
        ]
      )
    ]
    opt #";"
  ]
  value!:
    [  copy v [
      #"'" any [to quo1! #"\" skip] thru #"'"
      |
      #"^"" any [to quo2! #"\" skip] thru #"^""
      ] (v: unquote-string v)
    |  copy v to [space! | #">"]
    ]
  attribs!: [ (a: _)
    any [some space!
      copy k name! (v: true )
      opt [any space! #"=" any space! value!]
      (  unless a [a: make block! 8]
        k: to word! k
        if k = 'style [
          b: make block! 8
          parse v [ any [
            any space
            copy n name! any space! #":" any space
            copy k to [#";" | end] opt #";"
            (  
              append b to word! n
              append b k
            )
          ]  ]
          k: 'style v: b
        ] 
        append a k
        append/only a v
      )
    ]
    any space!
  ]
  comment!: ["!--" thru "--" and #">"]
  !tag!: [#"!" to #">"]
  ?tag!: [#"?" to #">"]
  atag!: [
    #"<" copy t name! attribs! opt #"/" #">"
    (emit to word! t if a [emit a])
  ]
  ztag!: [
    "</" copy t name! #">"
    (emit to refinement! t)
  ]
  data-tag!: [
    and copy t ["<script"|"<style"]
    atag! (insert t "</" append t #">")
    copy t to t (emit t) ztag!
  ]
  html!: [ any [
      copy t to mark! (emit t)
      [  #"<" copy t [comment! | !tag!] #">"
        (emit '! emit reduce [next t])
      |  #"<" copy t ?tag! #">"
        (emit '? emit reduce [next t])
      |  data-tag! | atag! | ztag! | entity!
      |  set t skip (emit t)
      ]
    ]
    copy t to end (emit t)
  ]
  either parse to string! data html! [ret] [return false]
]

load-html: func [
    x [block! string!]
    get-tag: dot: t:
  ][
  get-tag: func [c: t: node:] [
    t: x/1  x: next x
    node: make-tag-node :t
    if any [t = '?  t = '!] [
      unless tail? x [
        set-content node x/1
        x: next x
      ]
      return node
    ]
    if block? x/1 [
      foreach [k v] x/1 [
        set-attribute node k v
      ]
      x: next x
    ]
    if is-empty/:t [return node]
    c: make block! 8
    forever [
      case [
        tail? x [break]
        refinement? x/1 [
          if t = to-word x/1 [x: next x  break]
          fail ajoin ["unmatched " t space x/1]
        ]
        word? x/1 [append/only c get-tag]
        any [string? x/1 tag? x/1] [
          append c x/1  x: next x
        ]
        true [fail ajoin ["invalid " x/1]]
      ]
    ]
    switch length c [
      1 [c: c/1]
      0 [c: _]
    ]
    if c [set-content node c]
    node
  ]

  if string? x [x: split-html x]
  dot: make block! 8
  forever [
    if tail? x [break]
    t: x/1
    case [
      word? t [append/only dot get-tag]
      any [string? t tag? t] [append/only dot t x: next x]
      true [fail ajoin ["invalid " t]]
    ]
  ]
  switch length dot [
    1 [dot: dot/1]
    0 [dot: _]
  ]
  dot
]

mold-style: func [
    x [block! string!]
    ret:
  ][
  if string? x [return x]
  ret: make string! 32
  foreach [k v] x [
    if not empty? ret [append ret "; "]
    append ret k
    append ret ": "
    append ret v
  ]
  ret
]

mold-style-def: func [
    x [block! string!]
    ret:
  ][
  if string? x [return x]
  ret: make string! 32
  foreach [k v] x [
    forall k [
      if not head? k [append ret #","]
      append ret space
      append ret k/1
    ]
    append ret " {"
    append ret mold-style v
    append ret #"}"
  ]
  ret
]

quote-html: func [
    x [string!] q:
  ] [
  q: charset "<&>"
  parse x [any [to q
		[ #"&" insert "amp;"
		| remove #"<" insert "&lt;"
		| remove #">" insert "&gt;"
		]
  ] ]
  x
]

mold-html: func [
    x
    ret: tag: k: v:
  ] [
  case [
    tag: get-tag-name x [
      ret: make string! 512
      if tag = 'doc [tag: 'html]
      append ret #"<"
      append ret tag
      for-each-attribute k v x [
        append ret space 
        append ret k
        append ret #"="
        append ret quote-string
          either k = 'style [mold-style v] [to-string v]
      ]
      v: get-content x
      case [
        any [tag = '! tag = '?] [
          append ret v
          append ret #">"
        ]
        is-empty/:tag [append ret "/>"]
        true [
          append ret #">"
          append ret
            either tag = 'style
            [ mold-style-def v ]
            [ mold-html v ]
          append ret "</"
          append ret tag
          append ret #">"
        ]
      ]
    ]
    block? x [
      ret: make string! 512
      forall x [
        append ret mold-html x/1
      ]
    ]
    tag? x [ret: ajoin [#"&" to string! x #";"]]
    true [ret: quote-html to-string x]
  ]
  ret
]

; vim: syn=rebol sw=2 ts=2 sts=2 expandtab:
