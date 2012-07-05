#include "getfile.h"
#include <QDir>
#include <stdio.h>
#include <stdlib.h>
#include <math.h>

extern qint16 id[4*60*96000];

void getfile(QString fname, bool xpol, int dbDgrd)
{

  char name[80];
  strcpy(name,fname.toAscii());
  FILE* fp=fopen(name,"rb");

  int npts=30*48000;
  memset(datcom_.d2,0,2*npts);

  if(fp != NULL) {
//    Should read WAV header first
    fread(datcom_.d2,2,npts,fp);
    fclose(fp);
  }
}

void savewav(QString fname)
{
  int npts=30*48000;
//  qint16* buf=(qint16*)malloc(2*npts);
  char name[80];
  strcpy(name,fname.toAscii());
  FILE* fp=fopen(name,"wb");

  if(fp != NULL) {
// Write a WAV header
//    fwrite(&datcom_.fcenter,sizeof(datcom_.fcenter),1,fp);

//    memcpy(datcom_.d2,buf,2*npts);
//    fwrite(buf,2,npts,fp);
    fwrite(datcom_.d2,2,npts,fp);
    fclose(fp);
  }
//  free(buf);
}

//#define	MAX_RANDOM	0x7fffffff

/* Generate gaussian random float with mean=0 and std_dev=1 */
float gran()
{
  float fac,rsq,v1,v2;
  static float gset;
  static int iset;

  if(iset){
    /* Already got one */
    iset = 0;
    return gset;
  }
  /* Generate two evenly distributed numbers between -1 and +1
   * that are inside the unit circle
   */
  do {
    v1 = 2.0 * (float)rand() / RAND_MAX - 1;
    v2 = 2.0 * (float)rand() / RAND_MAX - 1;
    rsq = v1*v1 + v2*v2;
  } while(rsq >= 1.0 || rsq == 0.0);
  fac = sqrt(-2.0*log(rsq)/rsq);
  gset = v1*fac;
  iset++;
  return v2*fac;
}
