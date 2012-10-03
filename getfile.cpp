#include "getfile.h"
#include <QDir>
#include <stdio.h>
#include <stdlib.h>
#include <math.h>

void getfile(QString fname, int ntrperiod)
{

  char name[80];
  strcpy(name,fname.toAscii());
  FILE* fp=fopen(name,"rb");

  int npts=ntrperiod*12000;
  memset(jt9com_.d2,0,2*npts);

  if(fp != NULL) {
// Read (and ignore) a 44-byte WAV header; then read data
    fread(jt9com_.d2,1,44,fp);
    int nrd=fread(jt9com_.d2,2,npts,fp);
    fclose(fp);
//    for(int i=0; i<npts; i++) jt9com_.d2[i]/=100;
  }
}

void savewav(QString fname, int ntrperiod)
{
  struct {
    char ariff[4];
    int nchunk;
    char awave[4];
    char afmt[4];
    int lenfmt;
    short int nfmt2;
    short int nchan2;
    int nsamrate;
    int nbytesec;
    short int nbytesam2;
    short int nbitsam2;
    char adata[4];
    int ndata;
  } hdr;

  int npts=ntrperiod*12000;
//  qint16* buf=(qint16*)malloc(2*npts);
  char name[80];
  strcpy(name,fname.toAscii());
  FILE* fp=fopen(name,"wb");

  if(fp != NULL) {
// Write a WAV header
    hdr.ariff[0]='R';
    hdr.ariff[1]='I';
    hdr.ariff[2]='F';
    hdr.ariff[3]='F';
    hdr.nchunk=0;
    hdr.awave[0]='W';
    hdr.awave[0]='A';
    hdr.awave[0]='V';
    hdr.awave[0]='E';
    hdr.afmt[0]='f';
    hdr.afmt[1]='m';
    hdr.afmt[2]='t';
    hdr.afmt[3]=' ';
    hdr.lenfmt=16;
    hdr.nfmt2=1;
    hdr.nchan2=1;
    hdr.nsamrate=12000;
    hdr.nbytesec=2*12000;
    hdr.nbytesam2=2;
    hdr.nbitsam2=16;
    hdr.adata[0]='d';
    hdr.adata[1]='a';
    hdr.adata[2]='t';
    hdr.adata[3]='a';
    hdr.ndata=2*npts;

    fwrite(&hdr,sizeof(hdr),1,fp);
//    memcpy(jt9com_.d2,buf,2*npts);
//    fwrite(buf,2,npts,fp);
    fwrite(jt9com_.d2,2,npts,fp);
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
