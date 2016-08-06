REBOL [
    title: "A tiny static HTTP server"
    author: ["abolka" "Giulio Lunati"]
    date: [2009-11-04 2016-07-25]
    name: shttpd
    type: module
    exports: [shttpd]
]

shttpd: has [
    code-map: make map! [200 "OK" 400 "Forbidden" 404 "Not Found"]
    mime-map: make map! [
        "html" "text/html" "css" "text/css" "js" "application/javascript"
        "gif" "image/gif" "jpg" "image/jpeg" "png" "image/png"
        "r" "text/plain" "r3" "text/plain" "reb" "text/plain"
    ]
    error-template: trim/auto {
        <html><head><title>$code $text</title></head><body><h1>$text</h1>
        <p>Requested URI: <code>$uri</code></p><hr><i>shttpd.r</i> on
        <a href="http://www.rebol.com/rebol3/">REBOL 3</a> $r3</body></html>
    }

    error-response: func [code uri values:] [
        values: [code (code) text (code-map/:code) uri (uri) r3 (system/version)]
        reduce [code "text/html" reword error-template compose values]
    ]

    start-response: func [port res code: text: type: body:] [
        set [code type body] res
        write port ajoin ["HTTP/1.0 " code " " code-map/:code crlf]
        write port ajoin ["Content-type: " type crlf]
        write port ajoin ["Content-length: " length? body crlf]
        write port crlf
        write port body
    ]

    handle-request: func [config req uri: path: type: file: data: ext:] [
        parse to-string req ["get " ["/ " | copy uri to " "]]
        uri: default "index.html"
        print ["URI:" uri]
        parse uri [ copy path [to #"?" | to end]]
        parse path [some [thru "."] copy ext to end (type: mime-map/:ext)]
        type: default "application/octet-stream"
        if not exists? file: config/root/:path [return error-response 404 uri]
        if error? try [data: read file] [return error-response 400 uri]
        reduce [200 type data]
    ]

    awake-client: func [event port: res:] [
        port: event/port
        switch event/type [
            read [
                either find port/data to-binary join crlf crlf [
                    res: handle-request port/locals/config port/data
                    start-response port res
                ] [
                    read port
                ]
            ]
            close [close port]
        ]
    ]

    awake-server: func [event client:] [
        if event/type = 'accept [
            client: first event/port
            client/awake: :awake-client
            read client
        ]
    ]

    serve: func [web-port web-root listen-port:] [
        listen-port: open join tcp://: web-port
        listen-port/locals: has compose/deep [config: [root: (web-root)]]
        listen-port/awake: :awake-server
        wait listen-port
    ]    
]
; vim: set syn=rebol sw=4 ts=4:
