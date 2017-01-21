REBOL [
  Name: 'dot
  Type: module
  Author: "Giulio Lunati"
  Email: giuliolunati@gmail.com
  Description: "DOcument Tree"
  Exports: [
    for-each-attribute
    get-content
    get-tag-name
    make-tag-node
    get-attribute
    set-attribute
    set-content
  ]
]

for-each-attribute: func [
  'name [word!]
  'value [word!]
  node [block!]
  code [block!]
  n: v:
  ][
  n: attempt [get :name]
  v: attempt [get :value]
  for-each [n v] node [
    if any [n = 'tag n = '.] [continue]
    set :name n
    set :value v
    do code
  ]
  set :name n
  set :value v
]

get-attribute: func [x name [word!]] [
  x: all [block? x 'tag = x/1 x/:name]
  if all [x name = 'tag] [x: to word! x]
  x
]

get-content: specialize :get-attribute [name: '.]

get-tag-name: specialize :get-attribute [name: 'tag]

make-tag-node: func [name [word!] node:] [
  node: make block! 8
  set-attribute node 'tag to string! name
]

set-attribute: func [
    node [block!]
    name [word!]
    value
  ][
  append node name append/only node value
]

set-content: specialize :set-attribute [name: '.]

;; vim: set syn=rebol sw=2 ts=2 sts=2 expandtab:
