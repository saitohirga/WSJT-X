// qra64_subs.c
// Fortran interface routines for QRA64

#include "qra64.h"
#include <stdio.h>

//#define NICO_WANTS_SNR_DUMP

static qra64codec *pqra64codec = NULL;

void qra64_enc_(int x[], int y[])
{
  if (pqra64codec==NULL) pqra64codec = qra64_init(QRA_USERAP);  
  qra64_encode(pqra64codec, y, x);
}

void qra64_dec_(float r[], int* nc1, int* nc2, int* ng2, int* APtype, 
		int* iset, int xdec[], float* snr, int* rc)
{
/*
  APtype:
     -1                         (no AP information)
      0    [CQ/QRZ  *     ?_]   (* means 26 or 28 bit info)
      1    [call1   *     ?_]   (?_ means 16-bit info or "blank")
      2    [*     call2   ?_]
      3    [call1 call2   ?_]
      4    [call1 call2 grid]

  Return codes:
    -16    Failed sanity check
     -2    Decoded, but crc check failed
     -1    No decode
      0    [?    ?    ?] AP0	(decoding with no a-priori information)
      1    [CQ   ?    ?] AP27
      2    [CQ   ?     ] AP42
      3    [CALL ?    ?] AP29
      4    [CALL ?     ] AP44
      5    [CALL CALL ?] AP57
      6    [?    CALL ?] AP29
      7    [?    CALL  ] AP44
      8    [CALL CALL G] AP72
*/
  static int nc1z=-1;
  float EbNodBEstimated;
  int err=0;
  int nSubmode=0;
  int nFadingModel=1;
  float b90=1.0;

#ifdef NICO_WANTS_SNR_DUMP  
  FILE *fout;
#endif

  if(pqra64codec==NULL) pqra64codec = qra64_init(QRA_USERAP);
  err=qra64_apset(pqra64codec,*nc1,*nc2,*ng2,*APtype);
  if(err<0) printf("ERROR: qra64_apset returned %d\n",err);

  if(*iset==0) {
    //    *rc = qra64_decode(pqra64codec,&EbNodBEstimated,xdec,r);
    *rc = qra64_decode_fastfading(pqra64codec,&EbNodBEstimated,xdec,r,
				  nSubmode,b90,nFadingModel);
    *snr = EbNodBEstimated - 31.0;

#ifdef NICO_WANTS_SNR_DUMP  
    fout = fopen("C:\\JTSDK\\snrdump.txt","a+");
    if ((*rc)>=0) fprintf(fout,"rc=%d snr=%.2f dB\n",*rc,EbNodBEstimated-31.0f);
    fclose(fout);
#endif
  }
}
