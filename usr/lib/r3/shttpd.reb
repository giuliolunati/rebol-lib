REBOL [
  Title: "Static web server"
  Type: module
  Name: shttpd
  Author: "Giulio Lunati"
  Email: giuliolunati@gmail.com
  Date: 2016-09-01
  ; Needs: websy
]

remark: import 'remark
websy: import 'websy
config: websy/config

websy/extend/set [

  append config [root: %/ list-dir: true]

  ext-map: make block! [
    "css" css
    "gif" gif
    "htm" html
    "html" html
    "jpg" jpg
    "jpeg" jpg
    "js" js
    "json" json
    "png" png
    "r" rebol
    "r3" rebol
    "reb" rebol
    "rem" remark
    "txt" txt
  ]

  html-list-dir: function [
    "Output dir contents in HTML."
    dir [file!]
    param "config/list-dir value"
  ] [
    if error? try [list: read dir] [
      return build-error-response 400 request ""
    ]
    insert list ".."
    sort list
    data: make string! 256
    for-each i list [
      append data ajoin [ {<a href="} i {">} i </a> <br/>]
    ]
    return reduce [200 'html data]
  ]

  handle-get: function [
    "Handle a get request and serves files and folders"
    request [string!]
  ][
    if not config/root [
      return build-error-response 400 request "You must set root!"
    ]
    req: parse-request request
    mime: ext-map/(req/file-type)
    file: join-of config/root req/path
    type: exists? file
    if type = 'dir [
      while [#"/" = last file] [take/last file]
      append file #"/"
      if not config/list-dir [ 
        return build-error-response
          400 request "No folder access."
      ]
      either file? config/list-dir [
        file-index: join-of file config/list-dir
        either 'file = exists? file-index [
          ;; drop to type = 'dir
          file: file-index
          type: 'file
          mime: 'html
        ] [
          return build-error-response
            404 request
            ajoin [file-index " not found."]
        ]
      ] [
        return html-list-dir file config/list-dir
      ]
    ]
    if type = 'file [
      either error? data: trap [read file] [
        return build-error-response 400 request join-of "Cannot read file " file
      ] [
        if mime = 'remark [
          mime: either error? data: trap [
            remark/html-from-rem load data
          ] [data: form data 'txt]
          ['html]
        ]
        return reduce [200 mime data]
      ]
    ]
    return build-error-response 404 request ""
  ]

]

start: func [
  "Starts web server"
  port [integer!] "web server port"
  root [file! string!] "web server root directory"
] [
  config/port: port
  while [all [
    #"/" = last root
    1 < length root 
  ] ] [
    take/last root
  ]
  config/root: to-file root
  websy/start
]

;; vim: set syn=rebol sw=2 ts=2 sts=2 expandtab:
