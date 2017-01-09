REBOL [
  Name: 'markup
  Type: module
  Author: "Giulio Lunati"
  Email: giuliolunati@gmail.com
  Description: "Markup conversion"
  Exports: [html-rem load-rem mold-html]
]

html: make object! [
  markup-char: charset "<&>"

  encode: func [x [string! char!] r: t:] [
    if char? x [x: to-string x]
    unless find x markup-char [return x]
    r: make string! to-integer (1.1 * length x +1)
    parse x [
      some [
        copy t [to markup-char | to end] (append r t)
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

  mold-style-map: func [m s: k: v:] [
    s: _
    for-each [k v] m [
      k: ajoin [k #":"]
      either s [repend s ["; " k]] [s: k]
      repend s [space v]
    ] s
  ]

  mold-style-tag: func [x r: k: v: s:] [
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
      repend s [" { " mold-style-map v " } "]
    ]
    s
  ]

  mold: func [x a: b: c: t: k: v:] [
    switch/default type-of x [
      :blank! [""]
      :string! :char! [encode x]
      :block! [ajoin map-each t x [mold t]]
      :map! [
        a: to-tag "" c: _
        for-each [k v] x [case [
          k = 'tag! [t: v]
          k = '. [c: v]
          k = 'id [insert a ajoin [" id=" quot v]]
          k = 'class [insert a ajoin [" class=" quot v]]
          k = 'style [insert a ajoin [" style=" quot mold-style-map v]]
          word? k [append a ajoin [space k "=" quot v] ]
        ] ]
        if t = 'doc [t: 'html]
        c: either t = 'style
        [ mold-style-tag c ]
        [ mold c ]
        b: to-tag t
        either 'EMPTY-TAG = get :t [
          append a #"/" b: "" t: to-word t
        ] [
          b: back insert b #"/"
        ]
        insert a t
        ajoin [a c b]
      ]
    ] [print ["Invalid" x type-of x] quit]
  ]
]

rem: make object! [
  ;; available with /SECURE:
  space: :lib/space
  func: :lib/func

  doc: head: title: style: script: body:
  div: h1: h2: h3: h4: h5: h6: p:
  span: a: b: i:
  table: tr: td:
  'TAG

  meta: hr: br: img:
  'EMPTY-TAG

  rem: func [
    args [any-value! <...>]
    :look [any-value! <...>]
    x: b: m: read-1:
  ][
    read-1: func [
      id: class: style: m: t: w:
    ][
      w: first look
      if any [path? :w all [word? :w
        'TAG != get :w 'EMPTY-TAG != get :w
      ] ] [return take args]
      unless word? :w [return take look]
      take look
      m: make map! 8
      m/tag!: :w
      class: id: style: _
      forever [
        t: first look
        if word? t [
          if #"." = first to-string t [ take look
            unless class [class: make block! 4]
            append class to-word next to-string t
            continue
          ]
          break
        ]
        if refinement? t [ take look
          t: to-word t
          m/:t: read-1
          ; ^--- for non-HTML applications:
          ; value of an attribute may be a node!
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
        if any [url? t file? t] [ take look
          either w = 'a [m/href: t] [m/src: t]
          continue
        ]
        break
      ]
      if style [m/style: style]
      if class [m/class: class]
      if id [m/id: id]
      if 'TAG = get :w [
        case [
          block? t [
            insert x: take look 'rem ; DIRTY HACK!
            t: do x
            take x
          ]
          string? t [take look]
          any [word? t path? t] [
            t: read-1
          ]
        ]
        m/.: t
      ]
      m
    ]

    x: first look
    if block? x [
      m: make map! 2
      m/tag!: 'doc
      insert x: take look 'rem ; DIRTY HACK!
      m/.: do x
      take x
      return m
    ]
    b: make block! 8
    forever [
      x: first look
      unless x [break]
      append b read-1
    ]
    if 1 < length b [return b]
    b/1
  ]

  style: func [code b: t: k: v: s: selector!:] [
    selector!: [
      set t [word! | issue!]
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
      'tag! 'style
      '. s
    ]
  ]

  viewport: func [content] [
    if number? content [
      content: ajoin ["initial-scale=" content]
    ]
    rem meta /name "viewport" /content content
  ]
]

load-rem: func[x [block! string!] /secure t: ] [
  if string? x [return x]
  either secure
  [ x: bind/new x rem ]
  [ x: bind x rem ]
  do x
]

mold-html: :html/mold

html-rem: chain [:load-rem :html/mold]

;; vim: set syn=rebol sw=2 ts=2 sts=2 expandtab:
