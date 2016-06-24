// qra65_subs.c 
// Fortran interface routines for QRA65

#include "qra65.h"
#include <stdio.h>

void qra65_enc_(int x[], int y[])
{
  int ncall=0xf70c238;                          //K1ABC
  qra65codec *codec = qra65_init(0,ncall);	//codec for ncall
  qra65_encode(codec, y, x);
}

void qra65_dec_(float r[], int* nmycall, int xdec[], int* rc)
{
// Return codes:
//   rc=-16  failed sanity check
//   rc=-2   decoded, but crc check failed
//   rc=-1   no decode
//   rc=0    [?    ?    ?] AP0	(decoding with no a-priori information)
//   rc=1    [CQ   ?    ?] AP27
//   rc=2    [CQ   ?     ] AP42
//   rc=3    [CALL ?    ?] AP29
//   rc=4    [CALL ?     ] AP44
//   rc=5    [CALL CALL ?] AP57

  static int ncall0=0;
  int ncall;
  int x[63],y[12];

  ncall = *nmycall;
  qra65codec *codec = qra65_init(1,ncall);	//codec for ncall
/*
  if(ncall != ncall0) {
    memset(y,0,sizeof(y));
    qra65_encode(codec, y, x);
    printf("Updated codec %d\n",ncall);
  }
  ncall0=ncall;
*/
  *rc = qra65_decode(codec,xdec,r);
}
