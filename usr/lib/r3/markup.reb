REBOL [
  Name: 'markup
  Type: module
  Author: "Giulio Lunati"
  Email: giuliolunati@gmail.com
  Description: "Markup conversion"
  Exports: [html-from-rem load-rem]
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
          k = '.tag [t: v]
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

  load-tag: func [
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
          m/:t: to-string take look
          continue
        ]
        #"." = first to-string t [ take look
          unless class [class: make block! 4]
          append class to-word next to-string t
          continue
        ]
      ] ]
      if set-word? t [ take look
        t: to-word t
        unless style [style: make map! 8]
        style/:t: take look
        continue
      ]
      if issue? t [ take look
        id: next to-string t
        continue
      ]
      if any [url? t file? t] [ take look
        either tag = 'a [m/href: t] [m/src: t]
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

  def-tags: proc [
    'empty?
    :look [set-word! bar! <...>]
    t:
  ][
    while [set-word? t: take look] [
      t: to-word t
      set t specialize :load-tag [tag: t is-empty?: empty? = 'empty]
    ]
  ]
  
  ;; we need tags to appear here as set-word,
  ;; else we can't use them in subsequent definitions
  ;; (e.g. see below 'meta used in 'viewport)

  def-tags empty br: hr: img: meta: |

  def-tags non-empty a: b: body: code: div: doc: h1: h2: h3: h4: h5: h6: i: head: p: pre: span: title: |

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

load-rem: func[x /secure t:] [
  either secure
  [ t: do bind/new x rem ]
  [ t: do bind x rem ]
  t
]

mold-html: :html/mold

html-from-rem: chain [:load-rem :html/mold]

;; vim: set syn=rebol sw=2 ts=2 sts=2 expandtab:
