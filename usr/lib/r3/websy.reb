REBOL [
	Title: "Websy - a tiny HTTP/1.0 404-Error server"
	Author: "Ingo Hohmann"
	About: {A small server serving 404 errors over http/1.0.
		As an added bonus it is relatively easy to change the handlers
		to return something more interesting.
	}
	Type: module
	Name: websy
]

this: self ;store away self

config: object [
	port: 8080
	verbose: 1
		;; 0: no output
		;; 1: start message, brief request
		;; 2: complete request, response headers
		;; 3: also response body
]

listen-port: _ ; for internal use, to be able to close the port again

code-map: make map! [200 "OK" 400 "Forbidden" 404 "Not Found" 410 "Gone"
	500 "Internal Server Error" 501 "Not Implemented"]

mime-map: make map! [html "text/html" jpg "image/jpeg" r "text/plain"
	txt "text/plain" js "application/javascript" json "application/json"
	css "text/css"
]

template-error: trim/auto {
	<html><head><title>$code $text</title></head>
	<body><h1>$text</h1>
	<h2>Info</h2>
	<p>$info</p>
	<h2>Request:</h2>
	<pre>$request</pre>
	<hr>
	<i>websy.reb</i>
	on <a href="http://www.rebol.com/rebol3/">REBOL 3</a> $r3
	</body></html>
}

template-page: trim/auto {
	<html><head><title>$title</title></head>
	<body>
	$content
	</body></html>
}

crlf2x: join crlf crlf
crlf2xb: to-binary crlf2x

build-error-response: function [
	"Create a block containing return-code(code), mime-type(html), and html content (error, containin request info(molded))"
	status-code [integer!] "http status code"
	request [string!] "request string"
	info [string!] "additional error information"
][
	reduce [
		status-code 'html
		reword template-error compose [
			code (status-code) text (code-map/:status-code)
			info (info)
			request (reduce [request newline newline mold parse-request request "***"]) r3 (system/version)
		]
	]
]

build-success-response: function [
	"Create a block containing return-code(200), mime-type(html), and html content"
	type "unused"
	title [string!] "page title"
	html  [string!] "page text"
][
	reduce [
		200 mime-map/html
		reword template-page compose [
			title (title) content (html)
		]
	]
]

build-header: function [
	"Build response header"
	code [integer!] "http response code"
	type [word! string!]    "file ending as word, e.g. 'html, 'css, to be looked up."
][
	ajoin [
		"HTTP/1.0 " code " " code-map/:code crlf
		"Content-type: " mime-map/:type crlf2x
	]
]

deurl: function [
	"decode an url encoded string"
	s [string!]
][
	dehex replace/all s #"+" #" "
]

parse-request: function [
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
			(name: to-word name
			req/:name: data)
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

;
; all handle-xxx function have to return a block, containg
; http return code [integer!]
; mime/type [word!]
; page content [string! | binary!]
;
handle-get: function [
	"Handle a get request, to be implemented by the user of this library"
	request [string!]
][
	build-error-response 404 request "HTTP GET default handler"
]

handle-post: function [
	"Handle a post request, to be implemented by the user of this library"
	request [string!]
][
	build-error-response 404 request "HTTP POST default Handler"
]

handle-put: function [
	"Handle a put request, to be implemented by the user of this library"
	request [string!]
][
	build-error-response 404 request "HTTP PUT default Handler"
]

handle-delete: function [
	"Handle a delete request, to be implemented by the user of this library"
	request [string!]
][
	build-error-response 410 request "HTTP DELETE default Handler"
]

send-answer: function [
	"Send an answer to the client"
	port [port!] "port to send the datat to"
	data [block!] "http return code, mime-type, page-body"
][
	set [code: type: body:] data
	chunk: 32000
	header: build-header code type
	if config/verbose >= 2 [dump header]
	if config/verbose >= 3 [
		print/only "body: => "
		probe to-string body
	]
	write port header
	until [
		write port copy/part body chunk
		tail? body: skip body chunk
	]
]

handle-request: function [
	"build answer to the client"
	request [binary!]
	reply:
][
	req: to-string request
	if config/verbose = 1 [
		print copy/part req find req newline
	]
	if config/verbose >= 2 [dump req]
	method: copy/part req find req #" "
	set/opt 'reply switch method [
		"GET"    [handle-get    req]
		"POST"   [handle-post   req]
		"PUT"    [handle-put    req]
		"DELETE" [handle-delete req]
	]
	either all [set? 'reply block? reply][
		either parse reply [ integer! word! [binary! | string!] opt [binary! | string!] ][
			reply
		][
			build-error-response 500 req "Sorry, we've got an error, that's purely me doing something wrong."
		]
	][
		build-error-response 404 req "The resource you are searching can't be found."
	]
]

awake-client-connection: function [
	"The client has sent a request"
	event
][
	port: event/port
	switch event/type [
		read [
			either find port/data crlf2xb [
				send-answer port handle-request port/data
			][
				read port
			]
		]
		wrote [close port]
		close [close port]
	]
]

awake-server-dispatch: function [
	"A client wants to connect"
	event
][
	if event/type = 'accept [
		connection: first event/port
		connection/awake: :awake-client-connection
		read connection
	]
]

extend: proc [
	"extend websy with the following definitions"
	code [block!]
	/set "also add new set-words"
][
	either set
	[do bind/set code this]
	[do bind code this]
]

start: func [
	"Start listening"
][
	if config/verbose > 0 [
		print join "Websy starting on localhost:" config/port
	]
	listen-port: open join tcp://: config/port
	listen-port/awake: :awake-server-dispatch
	wait listen-port
]

stop: func [
	"Stop listening"
][
	close listen-port
]
;; vim: set syn=rebol:
