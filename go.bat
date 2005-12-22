cl /c /DBIGSYM=1 /Foinit_rs.obj init_rs.c
cl /c /DBIGSYM=1 /Foencode_rs.obj encode_rs.c
cl /c /DBIGSYM=1 /Ox /Zd /Fodecode_rs.obj decode_rs.c
cl /c /DWIN32=1 wrapkarn.c
df /exe:JT65code.exe JT65code_all.f /link wrapkarn.obj init_rs.obj encode_rs.obj decode_rs.obj
