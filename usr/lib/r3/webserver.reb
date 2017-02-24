REBOL [
  Title: "Static web server"
  Type: module
  Name: 'webserver
  Exports: [webserver]
  Author: "Giulio Lunati"
  Email: giuliolunati@gmail.com
  Date: 2017-02-24
]

import 'httpd
rem: import 'rem
html: import 'html

mold-html: :html/mold-html
load-rem: :rem/load-rem

webserver: make object! [
  ;; config
  access-dir: true ;; 
  verbose: 0 ;; [0 1 2]
  root: %"" ;;
  
  ;; internal
  port: _

  code-map: make map! [
    200 "OK"
    400 "Forbidden"
    404 "Not Found"
    410 "Gone"
    500 "Internal Server Error"
    501 "Not Implemented"
  ]

  ext-map: make block! [
    "css" css
    "gif" gif
    "htm" html
    "html" html
    "jpg" jpeg
    "jpeg" jpeg
    "js" js
    "json" json
    "png" png
    "r" rebol
    "r3" rebol
    "reb" rebol
    "rem" rem
    "txt" text
  ]

  mime: make map! [
    html "text/html"
    jpeg "image/jpeg"
    r "text/plain"
    text "text/plain"
    js "application/javascript"
    json "application/json"
    css "text/css"
  ]

  template-error: ;; from Ingo Hohmann's websy.reb
  {<html><head>
    <title>$code $text</title></head>
    <body><h1>$text</h1>
    <h2>Info</h2>
    <p>$info</p>
    <h2>Request:</h2>
    <pre>$request</pre>
    <hr>
    <i>server.reb</i>
    on <a href="http://github.com/metaeducation/ren-c/">Ren/C</a> $r3
    </body></html>
  }

  build-error-response: function [
    ;; from Ingo Hohmann's websy.reb
    "Create a block containing return-code(code), mime-type(html), and html content (error, containin request info(molded))"
    status-code [integer!] "http status code"
    request [map!] "parsed request"
    info [string!] "additional error information"
    ][
    reduce [
      'status status-code
      'type mime/html
      'content reword template-error reduce [
        'code status-code
        'text code-map/:status-code
        'info info
        'request form reduce [request/string newline newline mold request]
        'r3 system/version
      ]
    ]
  ]

  html-list-dir: function [
    "Output dir contents in HTML."
    dir [file!]
    ][
    if error? try [list: read dir] [
      return build-error-response 400 request ""
    ]
    insert list ".."
    sort list
    data: copy {<head><meta name="viewport" content="initial-scale=1.0" /></head>}
    for-each i list [
      append data ajoin [ {<a href="} i {">} i </a> <br/>]
    ]
    return reduce [
      'status 200
      'type mime/html
      'content data
    ]
  ]

  handle-request: func [
    request [map!]
    mimetype: file: filetype: data: file-index:
    ][
    switch verbose [
      1 [print request/string]
      2 [print [newline request]]
    ]
    mimetype: ext-map/(request/file-type)
    file: join-of root request/path
    filetype: exists? file
    if filetype = 'dir [
      while [#"/" = last file] [take/last file]
      append file #"/"
      if access-dir [ 
        return html-list-dir file
      ]
      return build-error-response
        400 request "No folder access."
    ]
    if filetype = 'file [
      either error? data: trap [read file] [
        return build-error-response 400 request join-of "Cannot read file " file
      ][
        if any [mimetype = 'rem all [
          mimetype = 'html 
          "REBOL" = uppercase to-string copy/part data 5
        ] ] [
          either error? data: trap [
            mold-html load-rem load data
          ] [data: form data mimetype: 'text]
          [mimetype: 'html]
        ]
        return reduce [
          'status 200
          'type mime/mimetype
          'content data
        ]
      ]
    ]
    return build-error-response 404 request ""
  ]

  start: func [
    port-number [integer!]
    ][
    wait port: open [
      Scheme: 'httpd
      Port-ID: port-number
      Awake: :handle-request
    ]
  ]
]
;; vim: set syn=rebol sw=2 ts=2 sts=2 expandtab:
