// qra64_subs.c 
// Fortran interface routines for QRA64

#include "qra64.h"
#include <stdio.h>

void qra64_enc_(int x[], int y[])
{
  int ncall=0xf70c238;                          //K1ABC
  qra64codec *codec = qra64_init(0,ncall);	//codec for ncall
  qra64_encode(codec, y, x);
}

void qra64_dec_(float r[], int* nmycall, int xdec[], int* rc)
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

  static ncall0=-1;
  int ncall=*nmycall;
  static qra64codec *codec;

  if(ncall!=ncall0) {
    codec = qra64_init(1,ncall);	//codec for ncall
    ncall0=ncall;
  }
  *rc = qra64_decode(codec,xdec,r);
}
