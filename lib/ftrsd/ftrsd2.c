/*
 ftrsd2.c
 
 A soft-decision decoder for the JT65 (63,12) Reed-Solomon code.
 
 This decoding scheme is built around Phil Karn's Berlekamp-Massey
 errors and erasures decoder. The approach is inspired by a number of
 publications, including the stochastic Chase decoder described
 in "Stochastic Chase Decoding of Reed-Solomon Codes", by Leroux et al.,
 IEEE Communications Letters, Vol. 14, No. 9, September 2010 and
 "Soft-Decision Decoding of Reed-Solomon Codes Using Successive Error-
 and-Erasure Decoding," by Soo-Woong Lee and B. V. K. Vijaya Kumar.
 
 Steve Franke K9AN and Joe Taylor K1JT
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <time.h>
#include <string.h>
#include "rs2.h"

static void *rs;

void ftrsd2_(int mrsym[], int mrprob[], int mr2sym[], int mr2prob[], 
	     int* ntrials0, int* verbose0, int correct[], int param[],
	     int indexes[], double tt[], int ntry[])
{
  int rxdat[63], rxprob[63], rxdat2[63], rxprob2[63];
  int workdat[63];
  int era_pos[51];
  int i, j, numera, nerr, nn=63;
  FILE *logfile = NULL;
  int ntrials = *ntrials0;
  int verbose = *verbose0;
  int nhard=0,nhard_min=32768,nsoft=0,nsoft_min=32768;
  int nsofter=0,nsofter_min=32768,ntotal=0,ntotal_min=32768,ncandidates;
  int nera_best=0;
  clock_t t0=0,t1=0;
  static unsigned int nseed;

/* For JT exp(x) symbol metrics - gaussian noise, no fading
  int perr[8][8] = {
     {12,     31,     44,     52,     60,     57,     50,     50},
     {28,     38,     49,     58,     65,     69,     64,     80},
     {40,     41,     53,     62,     66,     73,     76,     81},
     {50,     53,     53,     64,     70,     76,     77,     81},
     {50,     50,     52,     60,     71,     72,     77,     84},
     {50,     50,     56,     62,     67,     73,     81,     85},
     {50,     50,     71,     62,     70,     77,     80,     85},
     {50,     50,     62,     64,     71,     75,     82,     87}};
*/

/* For JT exp(x) symbol metrics - hf conditions
  int perr[8][8] = {
     {10,     10,     10,     12,     13,     15,     15,      9},
     {28,     30,     43,     50,     61,     58,     50,     34},
     {40,     40,     50,     53,     70,     65,     58,     45},
     {50,     50,     53,     74,     71,     68,     66,     52},
     {50,     50,     52,     45,     67,     70,     70,     60},
     {50,     50,     56,     73,     55,     74,     69,     67},
     {50,     50,     70,     81,     81,     69,     76,     75},
     {50,     50,     62,     57,     77,     81,     73,     78}};
*/

// For SF power-percentage symbol metrics - composite gnnf/hf 
  int perr[8][8] = {
    {4,      9,     11,     13,     14,     14,     15,     15},
    {2,     20,     20,     30,     40,     50,     50,     50},
    {7,     24,     27,     40,     50,     50,     50,     50},
    {13,     25,     35,     46,     52,     70,     50,     50},
    {17,     30,     42,     54,     55,     64,     71,     70},
    {25,     39,     48,     57,     64,     66,     77,     77},
    {32,     45,     54,     63,     66,     75,     78,     83},
    {51,     58,     57,     66,     72,     77,     82,     86}};
//

/* For SF power-percentage symbol metrics - gaussian noise, no fading
  int perr[8][8] = {
      {1,     10,     10,     20,     30,     50,     50,     50},
      {2,     20,     20,     30,     40,     50,     50,     50},
      {7,     24,     27,     40,     50,     50,     50,     50},
     {13,     25,     35,     46,     52,     70,     50,     50},
     {17,     30,     42,     54,     55,     64,     71,     70},
     {25,     39,     48,     57,     64,     66,     77,     77},
     {32,     45,     54,     63,     66,     75,     78,     83},
     {51,     58,     57,     66,     72,     77,     82,     86}};
*/

/* For SF power-percentage symbol metrics - hf
  int perr[8][8] = {
      {4,      9,     11,     13,     14,     14,     15,     15},
      {9,     12,     14,     25,     28,     30,     50,     50},
     {18,     22,     22,     28,     32,     35,     50,     50},
     {30,     35,     38,     38,     57,     50,     50,     50},
     {43,     46,     45,     53,     50,     64,     70,     50},
     {56,     58,     58,     57,     67,     66,     80,     77},
     {65,     72,     73,     72,     67,     75,     80,     83},
     {70,     74,     73,     70,     75,     77,     80,     86}};
*/

  if(verbose) {
    logfile=fopen("/tmp/ftrsd.log","a");
    if( !logfile ) {
      printf("Unable to open ftrsd.log\n");
      exit(1);
    }
  }
    
// Initialize the KA9Q Reed-Solomon encoder/decoder
  unsigned int symsize=6, gfpoly=0x43, fcr=3, prim=1, nroots=51;
  rs=init_rs_int(symsize, gfpoly, fcr, prim, nroots, 0);

// Reverse the received symbol vector for BM decoder
  for (i=0; i<63; i++) {
    rxdat[i]=mrsym[62-i];
    rxprob[i]=mrprob[62-i];
    rxdat2[i]=mr2sym[62-i];
    rxprob2[i]=mr2prob[62-i];
  }
    
// Sort the mrsym probabilities to find the least reliable symbols
  int k, pass, tmp, nsym=63;
  int probs[63];
  for (i=0; i<63; i++) {
    indexes[i]=i;
    probs[i]=rxprob[i];
  }
  for (pass = 1; pass <= nsym-1; pass++) {
    for (k = 0; k < nsym - pass; k++) {
      if( probs[k] < probs[k+1] ) {
	tmp = probs[k];
	probs[k] = probs[k+1];
	probs[k+1] = tmp;
	tmp = indexes[k];
	indexes[k] = indexes[k+1];
	indexes[k+1] = tmp;
      }
    }
  }
  
// See if we can decode using BM HDD, and calculate the syndrome vector.
  memset(era_pos,0,51*sizeof(int));
  numera=0;
  memcpy(workdat,rxdat,sizeof(rxdat));
  nerr=decode_rs_int(rs,workdat,era_pos,numera,1);
  if( nerr >= 0 ) {
    nhard=0;
    for (i=0; i<63; i++) {
      if( workdat[i] != rxdat[i] ) nhard=nhard+1;
    }
    if(logfile) {
      fprintf(logfile,"BM decode nerrors= %3d : \n",nerr);
      fclose(logfile);
    }
    memcpy(correct,workdat,63*sizeof(int));
    param[0]=0;
    param[1]=nhard;
    param[2]=0;
    param[3]=0;
    param[4]=0;
    ntry[0]=0;
    return;
  }

/*
Generate random erasure-locator vectors and see if any of them
decode. This will generate a list of potential codewords. The
"soft" distance between each codeword and the received word is
used to decide which codeword is "best".
*/

  nseed=1;                                 //Seed for random numbers

  float ratio;
  int thresh, nsum;
  int thresh0[63];
  ncandidates=0;
  nsum=0;
  int ii,jj;
  for (i=0; i<nn; i++) {
    nsum=nsum+rxprob[i];
    j = indexes[62-i];
    ratio = (float)rxprob2[j]/((float)rxprob[j]+0.01);
    ii = 7.999*ratio;
    jj = (62-i)/8;
    thresh0[i] = 1.3*perr[ii][jj];
  }
  if(nsum==0) return;

  for (k=1; k<=ntrials; k++) {
    memset(era_pos,0,51*sizeof(int));
    memcpy(workdat,rxdat,sizeof(rxdat));

/* 
Mark a subset of the symbols as erasures.
Run through the ranked symbols, starting with the worst, i=0.
NB: j is the symbol-vector index of the symbol with rank i.
*/
    numera=0;
    for (i=0; i<nn; i++) {
      j = indexes[62-i];
      thresh=thresh0[i];
      long int ir;

// Generate a random number ir, 0 <= ir < 100 (see POSIX.1-2001 example).
      nseed = nseed * 1103515245 + 12345;
      ir = (unsigned)(nseed/65536) % 32768;
      ir = (100*ir)/32768;

      if((ir < thresh ) && numera < 51) {
        era_pos[numera]=j;
        numera=numera+1;
      }
    }

    t0=clock();
    nerr=decode_rs_int(rs,workdat,era_pos,numera,0);
    t1=clock();
    tt[0]+=(double)(t1-t0)/CLOCKS_PER_SEC;
        
    if( nerr >= 0 ) {
      ncandidates=ncandidates+1;
      nhard=0;
      nsoft=0;
      nsofter=0;
      for (i=0; i<63; i++) {
	if(workdat[i] != rxdat[i]) {
	  nhard=nhard+1;
	  nsofter=nsofter+rxprob[i];
	  if(workdat[i] != rxdat2[i]) {
	    nsoft=nsoft+rxprob[i];
	  }
	} else {
          nsofter=nsofter-rxprob[i];
        } 
      }
      nsoft=63*nsoft/nsum;
      nsofter=63*nsofter/nsum;
      ntotal=nsoft+nhard;
      if( ntotal<ntotal_min ) {
        nsoft_min=nsoft;
        nhard_min=nhard;
        nsofter_min=nsofter;
        ntotal_min=ntotal;
        memcpy(correct,workdat,63*sizeof(int));
        nera_best=numera;
        ntry[0]=k;
      }
//      if(ntotal_min<72 && nhard_min<42) break;  
      if(ntotal_min<76 && nhard_min<44) break;  
    }
    if(k == ntrials) ntry[0]=k;
  }
  
  if( ntotal_min>=76 || nhard_min>=44 ) {
    nhard_min=-1;
  }
  
  if(logfile) {
    fprintf(logfile,"ncand %4d nhard %4d nsoft %4d nhard+nsoft %4d nsum %8d\n",
      ncandidates,nhard_min,nsoft_min,ntotal_min,nsum);
    fclose(logfile);
  }

  param[0]=ncandidates;
  param[1]=nhard_min;
  param[2]=nsoft_min;
  param[3]=nera_best;
  param[4]=nsofter_min;
  if(param[0]==0) param[2]=-1;
  return;
}
