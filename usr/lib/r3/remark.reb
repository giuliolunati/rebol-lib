REBOL [
  Name: 'remark
  Type: module
  Author: "Giulio Lunati"
  Email: giuliolunati@gmail.com
  Description: "ReMark reader"
  Exports: [to-html]
]

encode-block: func [
  x [block!] output [object!]
][
  forall x [
    case[
      string? x/1 [change x output/encode x/1]
      block? x/1 [encode-block x/1 output]
    ]
  ]
]

ajoin-block: func [b [block!] t:] [
  either empty? b [""] [t: ajoin b]
]

tags: make map! [
  ; tag [empty? newline? indent?]
]

html: make object! [
  func: :lib/func
  ajoin: :ajoin-block

  this: self
  indented-line: "^/"
  indent: 2
  indent++: does [loop indent [append indented-line space]]
  indent--: does [loop indent [take/last indented-line]]

  encode: func [x [string!]] [
    forall x [
      switch first x [
        #"&" [x: next x insert x "amp;"]
        #"<" [x: change x #"&" insert x "lt;"]
        #">" [x: change x #"&" insert x "gt;"]
      ]
    ]
    x
  ]

  emit: func [
    tag [tag!]
    close-tag [tag! blank!]
    break-before? [logic!]
    indent? [logic!]
    :args [word!]
    :look [word!]
    return: [string!]
    id: class: open-tag: t:
  ][
    args: get args
    look: get look
    class: id: _
    open-tag: copy tag
    if indent? [indent++]
    forever [
      t: first look
      either all [
        word? t
        #"." = first to-string t
      ][
        t: to-refinement next to-string t
        take look
      ][
        t: take args
      ]
      case [
        refinement? t [
          t: next to-string t
          either class
          [repend class [space t]]
          [class: t]
        ]
        issue? t [id: next to-string t]
        string? t [break]
        block? t [
          t: ajoin-block t
          break
        ]
      ]
    ]
    if id [repend open-tag [ { id="} id {"}]]
    if class [repend open-tag [ { class="} class {"}]]
    if indent? [indent--]
    if all [break-before? close-tag] [
      t: ajoin [t indented-line]
    ]
    either close-tag
    [ t: ajoin [t close-tag] ]
    [ append open-tag "/" ]
    t: ajoin [open-tag t]
    if break-before? [insert t indented-line]
    t
  ]

  tag-func: func [
    'tag [word!]
    is-empty? [logic!]
    break-before? [logic!]
    indent? [logic!]
    return: [function!]
    close-tag:
  ][
    tag: to-tag tag
    close-tag: either is-empty?
    [ _ ]
    [ back insert copy tag "/" ]
    func [
      args [any-string! issue! refinement! block! <...>]
      :look [any-word! any-string! issue! refinement! block! <...>]
    ]
    compose [ emit
      (tag) (close-tag)
      (break-before?) (indent?)
      args look
    ]
  ]

  ;tag: tag-func tag
  ;                   is-empty?
  ;                         break-before?
  ;                               indent?
  html: tag-func html false true  false
  body: tag-func body false true  false
  head: tag-func head false true  true
  div:  tag-func div  false true  true
  h1:   tag-func h1   false true  true
  h2:   tag-func h2   false true  true
  h3:   tag-func h3   false true  true
  h4:   tag-func h4   false true  true
  h5:   tag-func h5   false true  true
  h6:   tag-func h6   false true  true
  p:    tag-func p    false true  true
  span: tag-func span false false false
  b:    tag-func b    false false false
  i:    tag-func i    false false false
  img:  tag-func img  true  false false
  br:   tag-func br   true  true  false
  hr:   tag-func hr   true  true  false

  style: func [b r: t:] [
    r: ajoin [indented-line "<style>"]
    parse b [any[
      set t [word! | issue! | refinement!]
      ( if refinement? t [
          t: back change to-string t #"."
        ]
        append r ajoin [indented-line t]
      )
      and block! into [
        (append r " {" ) any [
          set t skip (
            either bar? t
            [ append r #";"]
            [append r ajoin[space t]]
          )
        ] (append r " }")
      ]
    ]]
    append r ajoin [indented-line "</style>"]
  ]
]

to-html: func[x /secure t:] [
  encode-block x html
  t: do either secure
  [ bind/new x html ]
  [ bind x html ]
  if t/1 = newline [take t]
  t
]
;; vim: set syn=rebol sw=2 ts=2 sts=2:
