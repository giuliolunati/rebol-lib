import 'shttpd
args: system/options/args
root: either args
[to-file args/1]
[system/options/path]
shttpd/serve 8080 probe root

; vim: set syn=rebol sw=4 ts=4:
