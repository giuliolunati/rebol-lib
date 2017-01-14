import %../recode.reb

;;; MAIN ;;;
t1: 0
args: system/options/args
r: load/all to file! system/options/args/1
rebol-ext r
quit
;; vim: set syn=rebol sw=2 ts=2 sts=2:
