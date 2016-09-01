probe trap [

args: system/options/args
root: either args
[to-file args/1]
[%/]

shttpd: import 'shttpd
shttpd/start 8080 root

]
; vim: set syn=rebol sw=4 ts=4:
