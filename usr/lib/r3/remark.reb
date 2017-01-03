REBOL [
  Name: 'remark
  Type: module
  Author: "Giulio Lunati"
  Email: giuliolunati@gmail.com
  Description: "ReMark reader"
  Exports: [html-from-rem tree-from-rem]
]

html: make object! [
  ch&rs: charset "<&>"
  encode: func [x [string! char!] r: t:] [
    if char? x [x: to-string x]
    unless find x ch&rs [return x]
    r: make string! to-integer (1.1 * length x +1)
    parse x [
      some [
        copy t [to ch&rs | to end] (append r t)
        [ #"&" (append r "&amp;")
        | #"<" (append r "&lt;")
        | #">" (append r "&gt;")
        | end
        ]
      ]
    ] r
  ]

  quot: func [x] [
    ajoin [#""" x #"""]
  ]

  style-from-map: func [m s: k: v:] [
    s: _
    for-each [k v] m [
      k: ajoin [k #":"]
      either s [repend s ["; " k]] [s: k]
      repend s [space v]
    ] s
  ]

  from-style: func [x r: k: v: s:] [
    s: _
    for-each [k v] x [
      r: _
      for-each k k [
        either r
        [ repend r [", " k] ]
        [ r: to-string k ]
      ]
      either s
      [ append s r ]
      [ s: r ]
      repend s [" { " style-from-map v " } "]
    ]
    s
  ]

  from-tree: func [x a: b: c: t: k: v:] [
    switch/default type-of x [
      :blank! [""]
      :string! :char! [encode x]
      :block! [ajoin map-each t x [from-tree t]]
      :map! [
        a: to-tag "" c: _
        for-each [k v] x [case [
          k = '.tag [t: v]
          k = '. [c: v]
          k = 'id [insert a ajoin [" id=" quot v]]
          k = 'class [insert a ajoin [" class=" quot v]]
          k = 'style [insert a ajoin [" style=" quot style-from-map v]]
          word? k [append a ajoin [space k "=" quot v] ]
        ] ]
        if t = 'doc [t: 'html]
        c: either t = 'style
        [ from-style c ]
        [ from-tree c ]
        insert a t
        b: to-tag t
        either void? select x '. [
          append a #"/" b: ""
        ] [
          b: back insert b #"/"
        ]
        ajoin [a c b]
      ]
    ] [print ["invalid" x] quit]
  ]
]

rem: make object! [
  ;; available with /SECURE:
  space: :lib/space
  group: :lib/reduce
  func: :lib/func

  emit-tag: func [
    tag [word!]
    is-empty? [logic!]
    args [any-value! <...>]
    :look [any-value! <...>]
    return: [map!]
    id: class: style: m: t:
  ][
    class: id: style: _
    m: make map! 8
    m/.tag: tag
    forever [
      t: first look
      if word? t [ case [
        #"=" = last to-string t [ take look
          t: to-string t take/last t
          t: to-word t
          m/:t: take args
          continue
        ]
        #"." = first to-string t[
          t: to-refinement next to-string t
        ]
      ] ]
      if refinement? t [ take look
        unless class [class: make block! 4]
        append class to-word t
        continue
      ]
      if set-word? t [ take look
        t: to-word t
        unless style [style: make map! 8]
        style/:t: take args
        continue
      ]
      if issue? t [ take look
        id: next to-string t
        continue
      ]
      break
    ]
    if style [m/style: style]
    if class [m/class: class]
    if id [m/id: id]
    unless is-empty? [
      t: take args
      if block? t [t: reduce t]
      m/.: t
    ]
    m
  ]

  tag-func: func [
    'tag [word!]
    is-empty? [logic!]
    return: [function!]
  ][
    specialize 'emit-tag [tag: tag is-empty?: is-empty?]
  ]

  ;tag:  tag-func tag   is-empty?
  doc:   tag-func doc   false
  head:  tag-func head  false
  title: tag-func title false
  meta:  tag-func meta  true
  body:  tag-func body  false
  div:   tag-func div   false
  h1:    tag-func h1    false
  h2:    tag-func h2    false
  h3:    tag-func h3    false
  h4:    tag-func h4    false
  h5:    tag-func h5    false
  h6:    tag-func h6    false
  p:     tag-func p     false
  span:  tag-func span  false
  b:     tag-func b     false
  i:     tag-func i     false
  img:   tag-func img   true 
  br:    tag-func br    true 
  hr:    tag-func hr    true 

  style: func [code b: t: k: v: s: selector!:] [
    selector!: [
      set t [word! | issue! | refinement!]
      ( if refinement? t [
          t: to-word back change to-string t #"."
      ])
    ]
    s: make block! 8
    parse code [any [
      (b: make block! 4)
      some [selector! (append b t)]
      (append/only s b)
      (t: make map! 8)
      some [
        set k set-word! set v skip
        (k: to-word k t/:k: v)
      ]
      (append s t)
    ] ]
    make map! reduce [
      '.tag 'style
      '. s
    ]
  ]

  viewport: func [content] [
    if number? content [
      content: ajoin ["initial-scale=" content]
    ]
    meta name="viewport" content= content
  ]
]

tree-from-rem: func[x /secure t:] [
  either secure
  [ t: do bind/new x rem ]
  [ t: do bind x rem ]
  t
]

html-from-tree: :html/from-tree

html-from-rem: func [x /secure] [
  html-from-tree apply :tree-from-rem [
    x: x secure: secure
  ]
]

;; vim: set syn=rebol sw=2 ts=2 sts=2 expandtab:
