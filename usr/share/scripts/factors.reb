pp: make object! [
  base: 0
  p: [2 3 5 7 11 13 17 19 23 29 31]
  get: does [base + p/1]
  next: does [
    p: lib/next p
    if tail? p [p: skip p -8  base: base + 30]
  ]
  reset: does [p: head p  base: 0]
]

for x 1965 2065 1 [
n: x
print/only [n ": "]
pp/reset 
forever [
  p: pp/get
  q: n / p
  if q < p [break]
  either integer? q
  [ print/only [p " "]  n: q ]
  [ pp/next ]
] print n
]

;; vim: set syn=rebol sw=2 ts=2 sts=2 expandtab:
