remark: import 'remark

probe trap[
remark/html/do [
body [
p /center /bold ["centrato "br"grassetto"]
p #mypar [
"testo normale "b"grassetto""normale"i"italico" 
]
] ; body
]
] ; trap
;; vim: set syn=rebol:
