#include "reb-ext.h"
#include "reb-lib.h"

const char *init_block =
"void memrot (REBYTE *start REBCNT len REBINT shift) {"
"^-REBYTE *to, *p;"
"^-REBINT c, l, r;"
""
"^-if(shift == 0 || len == 0) return;"
""
"^-while (1) {"
"^-^-c = abs(shift) % len;"
"^-^-if (c == 0) return;"
"^-^-if (c + c < len) shift = (shift > 0 ? c : -c);"
"^-^-else {"
"^-^-^-c = len - c;"
"^-^-^-shift = (shift > 0 ? -c : c);"
"^-^-}"
"^-^-if (c <= BUF_LEN) {"
"^-^-^-if (shift < 0) {"
"^-^-^-^-memcpy(buf, start + len - c, c);"
"^-^-^-^-memmove(start + c, start, len - c);"
"^-^-^-^-memcpy(start, buf, c);"
"^-^-^-} else { // shift > 0"
"^-^-^-^-memcpy(buf, start, c);"
"^-^-^-^-memmove(start, start + c, len - c);"
"^-^-^-^-memcpy(start + len - c, buf, c);"
"^-^-^-}"
"^-^-^-return;"
"^-^-}"
"^-^-l = BUF_LEN;"
"^-^-r = len % c;"
""
"^-^-if (shift < 0) {"
"^-^-^-p = start;"
"^-^-^-while (c > 0) {"
"^-^-^-^-if (c < l) l = c;"
"^-^-^-^-memcpy(buf, start + len - c, l);"
"^-^-^-^-for (to = start + len - c; to + shift >= p; to += shift) {"
"^-^-^-^-^-memcpy(to, to + shift, l);"
"^-^-^-^-}"
"^-^-^-^-memcpy(to, buf, l);"
"^-^-^-^-c -= l; p+=l;"
"^-^-^-}"
"^-^-^-if (r == 0) return;"
"^-^-^-len = r - shift;"
"^-^-} else { // shift > 0"
"^-^-^-p = start + len;"
"^-^-^-while (c > 0) {"
"^-^-^-^-if (c < l) l = c;"
"^-^-^-^-memcpy(buf, start + c - l , l);"
"^-^-^-^-for (to = start + c - l; to + shift + l <= p; to += shift) {"
"^-^-^-^-^-memcpy(to, to + shift, l);"
"^-^-^-^-}"
"^-^-^-^-memcpy(to, buf, l);"
"^-^-^-^-c -= l; p -= l;"
"^-^-^-}"
"^-^-^-if (r == 0) return;"
"^-^-^-start += len - shift -r; len = shift + r;"
"^-^-}"
"^-}"
"}";
RXIEXT const char *RX_Init(int opts, RL_LIB *lib) {
	RL = lib;
	if (!CHECK_STRUCT_ALIGN) {
		printf ( "CHECK_STRUCT_ALIGN failed\n" );
		return 0;
	}
	return init_block;
}
RL_LIB *RL = NULL;
RXIEXT int RX_Call(int cmd, RXIFRM *frm, void *data){
switch (cmd) {
default: return RXR_NO_COMMAND;
}};
