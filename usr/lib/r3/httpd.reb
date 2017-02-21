Rebol [
    Title: "HTTPD Scheme"
    Name: 'httpd
    Type: module
    Date: 10-Jun-2013
    Author: [
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

    Awake-Client: use [from-actions chars][
        from-actions: ["GET" | "POST"]
        chars: complement union space: charset " " charset [#"^@" - #"^_"]
        
        func [event [event!] /local port request response][
            port: event/port

            switch event/type [
                read [
                    either find port/data to-binary rejoin [crlf crlf][
                        response: port/locals/parent/awake request: make object! [
                            action: target: _
                            parse to-string port/data [
                                copy action from-actions some space
                                copy target some chars some space
                                "HTTP/" ["1.0" | "1.1"]
                            ]
                        ]
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
