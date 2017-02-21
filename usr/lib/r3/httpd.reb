Rebol [
    Title: "HTTPD Scheme"
    Name: 'httpd
    Type: module
    Date: 10-Jun-2013
    Author: [
        "Giulio Lunati" 21-Feb-2017 "Various enhancements"
        "Christopher Ross-Gill" 4-Jan-2017 "Adaptation to Scheme"
        "Andreas Bolka" 4-Nov-2009 "A Tiny HTTP Server"
    ]
    File: %httpd.reb
    Version: 0.1.0
    Rights: http://opensource.org/licenses/Apache-2.0
    Purpose: {
        A Tiny Static Webserver Scheme for Rebol 3
        Based on 'A Tiny HTTP Server' by Andreas Bolka
        https://github.com/earl/rebol3/blob/master/scripts/shttpd.r
    }
]

attempt [_: none] ; for Rebolsource Rebol 3 Compatibility

deurl: function [
    "decode an url encoded string"
    s [string!]
][
    dehex replace/all s #"+" #" "
]

parse-request: function [
    ;; from Ingo Hohmann's Websy
    ;; https://github.com/IngoHohmann/websy
    {parse request and return a map! with header-names as keys
    (standard headers are words, others are strings) }
    request [string!]
][
    name-char: complement charset ":"
    query-split-char: charset "&="
    req: make map! []
    parse request [
        copy method: to #" " skip
        copy path: to #" " skip
        copy version: to newline newline
        (
            req/method: method
            req/version: version
            req/string: ajoin [method space path]
            set [path: query-string:] split path #"?"
            path: deurl path
            req/path: path
            req/path-elements: next split path #"/"
            req/file-name: last req/path-elements
            either pos: find/last req/file-name #"." [
                req/file-base: copy/part req/file-name pos
                req/file-type: copy next pos
            ][
                req/file-base: req/file-name
                req/file-type: ""
            ]
            either all[set? 'query-string query-string ] [
                req/query-string: query-string
            ][
                req/query-string: ""
            ]
        )
        any [
            copy name: [some name-char] 2 skip copy data: to newline
            ( name: to-word name    req/:name: data )
            newline
        ]
        newline
        copy content-string: to end
        (
            req/content-string: content-string
            req/content: map split content-string query-split-char
        )
    ]
    req
]

sys/make-scheme [
    Title: "HTTP Server"
    Name: 'httpd

    Actor: [
        Open: func [port [port!]][
            ; probe port/spec
            port/locals: make object! [
                subport: open [
                    scheme: 'tcp
                    port-id: port/spec/port-id
                ]
                subport/awake: :port/scheme/awake-server
                subport/locals: make object! [
                    parent: :port
                    body: _
                ]
            ]

            port
        ]

        Close: func [port [port!]][
            close port/locals/subport
        ]
    ]

    Status-Codes: make map! [
        200 "OK" 400 "Forbidden" 404 "Not Found"
    ]

    Respond: func [port response][
        write port ajoin ["HTTP/1.0 " response/status " " status-codes/(response/status) crlf]
        write port ajoin ["Content-Type: " response/type crlf]
        write port ajoin ["Content-Length: " length? response/content crlf]
        write port crlf
           ;; Manual chunking is only necessary because of several bugs in R3's
           ;; networking stack (mainly cc#2098 & cc#2160; in some constellations also
           ;; cc#2103). Once those are fixed, we should directly use R3's internal
           ;; chunking instead: `write port body`.
        port/locals/body: to binary! response/content
    ]

    Send-Chunk: func [port [port!]][
           ;; Trying to send data >32'000 bytes at once will trigger R3's internal
           ;; chunking (which is buggy, see above). So we cannot use chunks >32'000
           ;; for our manual chunking.
        either empty? port/locals/body [true][write port take/part port/locals/body 32'000]
    ]

    Awake-Client: use [q] [
        
        func [event [event!] /local port request response][
            port: event/port

            switch event/type [
                read [
                    either find port/data to-binary rejoin [crlf crlf] [
                        request: parse-request to-string port/data
                        q: query port
                        request/remote-ip: q/remote-ip
                        request/remote-port: q/remote-port
                        response: port/locals/parent/awake request
                        respond port response
                    ][
                        read port
                    ]
                ]
                wrote [unless send-chunk port [close port] port]
                close [close port]
            ]
        ]
    ]

    Awake-Server: func [event [event!] /local client] [
        if event/type = 'accept [
            client: first event/port
            client/awake: :awake-client
            read client
        ]
        event
    ]
]
;; vim: set syn=rebol sw=2 ts=2 sts=2 expandtab:
