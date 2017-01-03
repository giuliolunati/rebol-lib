import 'csv

f: to-file system/options/args/1
csv: read/string f
probe b: read-csv csv

demo: func [code] [
  for-each code code [
    case [
      string? code [
        for-each x split code [
          newline some space
        ] [print x]
      ]
      block? code [
        print [">> rem-html " mold code]
        print "==="
        print [mold rem-html/secure code]
        print "---"
      ]
      group? code [
        code: to block! code
        print [">>" mold/only code]
        do code
      ]
      code = _ [print/only newline]
      code = 'quit [quit]
    ]
  ]
]
demo [
]
;; vim: set syn=rebol sw=2 ts=2 sts=2 expandtab:
