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

void qra65_dec_(float r[], int xdec[], int* rc)
{
  //  int ncall=0xf70c238;                          //K1ABC
  int ncall=0x890c60c;                          //KA1ABC
  int i;
  qra65codec *codec = qra65_init(1,ncall);	//codec for ncall
  *rc = qra65_decode(codec,xdec,r);
}
