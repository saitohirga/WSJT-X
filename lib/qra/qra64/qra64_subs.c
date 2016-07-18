// qra64_subs.c 
// Fortran interface routines for QRA64

#include "qra64.h"
#include <stdio.h>

#define NICO_WANTS_SNR_DUMP

static qra64codec *pqra64codec = NULL;

void qra64_enc_(int x[], int y[])
{
  if (pqra64codec==NULL)
	  pqra64codec = qra64_init(QRA_AUTOAP);
  
  qra64_encode(pqra64codec, y, x);
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
//   rc=6    [?    CALL ?] AP29
//   rc=7    [?    CALL  ] AP44
//   rc=8    [CALL CALL G] AP72

  static ncall0=-1;
  int ncall=*nmycall;
  float EbNodBEstimated;

#ifdef NICO_WANTS_SNR_DUMP  
  FILE *fout;
#endif
  
  if(ncall!=ncall0) {
	if (pqra64codec!=NULL)
		qra64_close(pqra64codec);
	pqra64codec = qra64_init(QRA_AUTOAP);
	// the following apset call is not strictly necessary
	// It enables AP decoding of messages directed to our call
	// also in the case we have never made a CQ
	qra64_apset(pqra64codec,ncall,0,0,APTYPE_MYCALL);
    ncall0=ncall;
  }
  *rc = qra64_decode(pqra64codec,&EbNodBEstimated,xdec,r);

#ifdef NICO_WANTS_SNR_DUMP  
  fout = fopen("C:\\JTSDK\\snrdump.txt","a+");
  if ((*rc)>=0) 
	  fprintf(fout,"rc=%d snr=%.2f dB\n",*rc,EbNodBEstimated-31.0f);
  fclose(fout);
#endif  
}
