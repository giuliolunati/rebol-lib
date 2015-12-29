usage: func [/local t] [
  t: second split-path system/options/script
  t: ajoin ["r3 " t]
  print "^/USAGE:"
  print ["^/" t "-m[ake] SOURCE-FILES... > CALL-MAP-FILE"
  "^/--> write call map"]
  print ["^/" t "CALL-MAP-FILE FUNCTION-NAME"
  "^/--> show call graph of a function"]
  print ""
  quit
]

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
func-call!: [
  copy t name! and #"("
  (if find c-keywords t [t: none])
]
func-decl!: [
  ["REBNATIVE(" copy t name! ")"
  (t: ajoin ["N_" t])]
  | copy t name! group! any spc! #"{" ;}
  (if find c-keywords t [t: none])
]
group!: [#"(" any [to par! group!] thru #")"]
name!: [letter! to noname!]
step1!: [to stop1! | to end]
step2!: [to stop2! | to end]

directive!: [
  opt #"^/" any spc! #"#" [
    "define" some spc!
    func-call! (macro-decl: t)
    step2!
    any [
      [ func-call!
        (if all[t macro-decl] [emit macro-decl t])
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
  [ func-decl! (if all [t not indent] [func-decl: t])
  | func-call!
    (if all[t func-decl] [emit func-decl t])
  | name!
  | directive!
  | comment!
  | and "^/}" skip (func-decl: none)
  | and "^/ " skip (indent: true)
  | and ["^/" not spc!] skip (indent: false)
  | skip
  ] step2!
] ]

; GLOBALS
macro-decl: func-decl: none
args: system/options/args
calls: make map! 1024
is-called: make map! 1024
p: none
indent: false

; FUNCS
emit: func [caller called] [
  called: to word! called
  caller: any [
    attempt [to word! caller]
    caller
  ]
  either is-called/(called)
  [append is-called/(called) caller]
  [is-called/(called): reduce [caller]]
  either calls/(caller)
  [append calls/(caller) called]
  [calls/(caller): reduce [called]]
]
make-call-maps: func [args /local text] [
  for-each f args [
    if 1 = index-of find (second split-path f) "tmp-" [continue]
    p: copy system/options/path
    text: to string! read append p f
    p: to file! find/reverse tail p "src"
    unless parse text rule!
    [print "ERROR!" quit]
  ]
  print "["
  for-each k calls [
    prin k prin space
    probe unique calls/(k)
  ]
  print "]["
  for-each k is-called [
    prin k prin space
    probe unique is-called/(k)
  ]
  print "]"
]
show: function [file-name function-name] [
  m: load to file! ajoin [system/options/path file-name]
  print "---IS CALLED---"
  t: reduce [to word! function-name none]
  l: none i: 1
  forever [
    if l = length t [break]
    l: length t
    while [i <= l] [
      k: t/(++ i) ++ i
      t2: m/2/(k)
      for-each k2 t2 [unless find t k2 [append t reduce [k2 k]]]
    ]
  ]
  is-called: make block! (length t) / 2
  for i 1 length t 2 [
    prin k: t/(i)
    forever [
      k: select t k
      unless k [break]
      prin " -> " prin k
    ]
    print ""
    append is-called t/(i)
  ]
  print "---CALLS---"
  t: reduce [to word! function-name none]
  l: none i: 1
  forever [
    if l = length t [break]
    l: length t
    while [i <= l] [
      k: t/(++ i) ++ i
      t2: m/1/(k)
      for-each k2 t2 [unless find t k2 [append t reduce [k2 k]]]
    ]
  ]
  calls: make block! (length t) / 2
  for i 1 length t 2 [
    prin k: t/(i)
    forever [
      k: select t k
      unless k [break]
      prin " <- " prin k
    ]
    print ""
    append calls t/(i)
  ]
  print "---CALLING EACH OTHER---"
  each-other: make block! (length t) / 2
  for-each t is-called [
    if find calls t [append each-other t]
  ]
  for-each t each-other [print t]
]
; MAIN
case [
any [empty? args   1 = index? find "-help" args/1]
  [usage]
1 = index? find "-make" args/1
  [make-call-maps next args]
2 = length args
  [show args/1 args/2]
]
; vim: set syn=rebol expandtab sw=2 nosmartindent autoindent:
