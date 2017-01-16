REBOL [
  Title: "HTML utils for Ren/C"
  Type: 'module
  Name: 'html
  Exports: [
    load-html
    split-html
  ]
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

;; from 'text module
unquote-string: function [
    {Remove \ escape and " quotes}
    s
  ] [
  parse s [ any [
    to #"\" remove skip skip
  ] ]
  copy/part next s back tail s
]

split-html: function [data [string!]] [
  a: b: k: n: t: v: _
  ret: make block! 32
  emit: func [x /local t] [
    if x = "" [return _]
    if char? x [x: to string! x]
    if string? x [
      t: last ret
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
        emit switch/default t [
          "nbsp" [#"^(a0)"]
        ] ajoin[#"&" t #";"]
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
  comment!: ["!--" thru "--"]
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
        (emit '! emit next t)
      |  #"<" copy t ?tag! #">"
        (emit '? emit next t)
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
    get-tag: ret: t:
  ][
  get-tag: func [c: t: m:] [
    m: make block! 8
    t: x/1  x: next x
		append m 'tag!
		append/only m t
    if any [t = '?  t = '!] [
      unless tail? x [
        append m '.
				append m x/1
        x: next x
      ]
      return m
    ]
    if block? x/1 [append m x/1 x: next x]
    if is-empty/:t [return m]
    c: make block! 8
    forever [
      case [
        tail? x [break]
        refinement? x/1 [
          if t = to-word x/1 [x: next x  break]
          fail ajoin ["unmatched " t space x/1]
        ]
        word? x/1 [append/only c get-tag]
        string? x/1 [append/only c x/1  x: next x]
      ]
    ]
    switch length c [
      1 [c: c/1]
      0 [c: _]
    ]
    if c [append m '. append/only m c]
    m
  ]

  if string? x [x: split-html x]
  ret: make block! 8
  forever [
    if tail? x [break]
    t: x/1
    case [
      string? t [append/only ret t x: next x]
      word? t [append/only ret get-tag]
      true [fail ajoin ["invalid " t]]
    ]
  ]
  switch length ret [
    1 [ret: ret/1]
    0 [ret: _]
  ]
  ret
]

; vim: syn=rebol sw=2 ts=2 sts=2:
