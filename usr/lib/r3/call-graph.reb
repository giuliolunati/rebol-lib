; CHARSETS
letter!: charset [#"A" - #"Z" #"a" - #"z" #"_"]
numletter!: or~ letter! charset [#"0" - #"9"]
noname!: complement numletter!
spc!: charset " ^-^/"
par!: charset "()"
stop1!: charset "/\^/"
stop2!: or~ stop1! letter!

; RULES
c-keywords: ["if" "for" "switch" "while"]
comment1!: ["//" to #"^/"]
comment2!: ["/*" thru "*/"]
comment!: [comment1! | comment2!]
continue-line!: "\^/"
func-call!: [copy t name! group!]
func-decl!: [
  copy t ["REBNATIVE(" name! ")"]
  | func-call! any spc! #"{" ;}
]
group!: [#"(" any [to par! group!] thru #")"]
name!: [letter! to noname!]
step1!: [to stop1! | to end]
step2!: [to stop2! | to end]
macro-decl: func-decl: none

directive!: [
  opt #"^/" any spc! #"#" [
    "define" some spc!
    func-call! (macro-decl: t print [t p])
    step2!
    any [
      [ func-call!
        (if macro-decl [print [t macro-decl]])
      | name!
      | comment!
      | continue-line!
      | #"\"
      ] step2!
    ] (macro-decl: none)
  | step1!
    any [continue-line! step1!]
  ]
]
rule!: [any [
  [ func-decl! (func-decl: t print [t p])
  | func-call!
    (if func-decl [print [t func-decl]])
  | name!
  | directive!
  | comment!
  | and "^/}" skip (func-decl: none)
  | skip
  ] step2!
] ]

; MAIN
args: system/options/args
print "["
for-each f args [
  p: copy system/options/path
  text: to string! read append p f
  p: mold to file! find/reverse tail p "src"
  unless parse text rule!
  [print "ERROR!" quit]
]
print "]"
; vim: set syn=rebol expandtab sw=2 nosmartindent autoindent:
