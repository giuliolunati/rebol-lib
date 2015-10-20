heapsort: function [ar] [
	ir: length? ar
	l: to integer! ir / 2 + 1
	forever [
		either l > 1 [
			-- l
			bak: ar/(l)
		][
			bak: ar/(ir)
			ar/(ir): ar/1
			-- ir
			if ir = 1 [ar/1: bak return ar]
		]
		i: l
		j: l + l
		while [j <= ir] [
			if all[j < ir ar/(j) < ar/(j + 1)] ++ j
			either bak < ar/(j) [
				ar/(i): ar/(j)
				i: j
				j: j + j
			][j: ir + 1]
		]
		ar/(i): bak
	]
]
n: 16
a: make block! n
loop n [append a random 999]
print a
print heapsort a


			
; vim: set syn=rebol ts=2 sw=2 sts=2:
