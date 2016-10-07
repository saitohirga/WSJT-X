/*
qra64.c 
Encoding/decoding functions for the QRA64 mode

(c) 2016 - Nico Palermo, IV3NWV

-------------------------------------------------------------------------------

   qracodes is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.
   qracodes is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with qracodes source distribution.  
   If not, see <http://www.gnu.org/licenses/>.

-----------------------------------------------------------------------------

Code used in this sowftware release:

QRA13_64_64_IRR_E: K=13 N=64 Q=64 irregular QRA code (defined in 
qra13_64_64_irr_e.h /.c)

Codes with K=13 are designed to include a CRC as the 13th information symbol
and improve the code UER (Undetected Error Rate).
The CRC symbol is not sent along the channel (the codes are punctured) and the 
resulting code is a (12,63) code 
*/
//----------------------------------------------------------------------------

#include <stdlib.h>
#include <math.h>
#include <string.h>

#include "qra64.h"
#include "../qracodes/qracodes.h"
#include "../qracodes/qra13_64_64_irr_e.h"
#include "../qracodes/pdmath.h"

// Code parameters of the QRA64 mode 
#define QRA64_CODE  qra_13_64_64_irr_e
#define QRA64_NMSG  218        // Must much value indicated in QRA64_CODE.NMSG

#define QRA64_KC (QRA64_K+1)   // Information symbols (crc included)
#define QRA64_NC (QRA64_N+1)   // Codeword length (as defined in the code)
#define QRA64_NITER 100	       // max number of iterations per decode

// static functions declarations ----------------------------------------------
static int  calc_crc6(const int *x, int sz);
static void ix_mask(float *dst, const float *src, const int *mask, 
		    const int *x);
static int  qra64_do_decode(int *x, const float *pix, const int *ap_mask, 
			    const int *ap_x);

// a-priori information masks for fields in JT65-like msgs --------------------
#define MASK_CQQRZ      0xFFFFFFC // CQ/QRZ calls common bits
#define MASK_CALL1      0xFFFFFFF
#define MASK_CALL2      0xFFFFFFF
#define MASK_GRIDFULL	0xFFFF
#define MASK_GRIDFULL12	0x3FFC	  // less aggressive mask (to be used with full AP decoding)
#define MASK_GRIDBIT	0x8000	  // b[15] is 1 for free text, 0 otherwise
// ----------------------------------------------------------------------------

qra64codec *qra64_init(int flags)
{

  // Eb/No value for which we optimize the decoder metric
  const float EbNodBMetric = 2.8f; 
  const float EbNoMetric   = (float)pow(10,EbNodBMetric/10);
  const float R = 1.0f*(QRA64_KC)/(QRA64_NC);	

  qra64codec *pcodec = (qra64codec*)malloc(sizeof(qra64codec));

  if (!pcodec)
    return 0;	// can't allocate memory

  pcodec->decEsNoMetric   = 1.0f*QRA64_m*R*EbNoMetric;
  pcodec->apflags			= flags;

  memset(pcodec->apmsg_set,0,APTYPE_SIZE*sizeof(int));

  if (flags==QRA_NOAP)
    return pcodec;

  // for QRA_USERAP and QRA_AUTOAP modes we always enable [CQ/QRZ ? ?] mgs look-up.
  // encode CQ/QRZ AP messages 
  // NOTE: Here we handle only CQ and QRZ msgs. 
  // 'CQ nnn', 'CQ DX' and 'DE' msgs will be handled by the decoder 
  // as messages with no a-priori knowledge
  qra64_apset(pcodec, CALL_CQ, 0, GRID_BLANK, APTYPE_CQQRZ);

  // initialize masks for decoding with a-priori information
  encodemsg_jt65(pcodec->apmask_cqqrz,     MASK_CQQRZ, 0, MASK_GRIDBIT);     
  encodemsg_jt65(pcodec->apmask_cqqrz_ooo, MASK_CQQRZ, 0, MASK_GRIDFULL);
  encodemsg_jt65(pcodec->apmask_call1,     MASK_CALL1, 0, MASK_GRIDBIT);
  encodemsg_jt65(pcodec->apmask_call1_ooo, MASK_CALL1, 0, MASK_GRIDFULL);
  encodemsg_jt65(pcodec->apmask_call2,     0, MASK_CALL2, MASK_GRIDBIT);
  encodemsg_jt65(pcodec->apmask_call2_ooo, 0, MASK_CALL2, MASK_GRIDFULL);
  encodemsg_jt65(pcodec->apmask_call1_call2,     MASK_CALL1,MASK_CALL2, MASK_GRIDBIT);
  encodemsg_jt65(pcodec->apmask_call1_call2_grid,MASK_CALL1,MASK_CALL2, MASK_GRIDFULL12);
  encodemsg_jt65(pcodec->apmask_cq_call2,     MASK_CQQRZ, MASK_CALL2, MASK_GRIDBIT);
  encodemsg_jt65(pcodec->apmask_cq_call2_ooo, MASK_CQQRZ, MASK_CALL2, MASK_GRIDFULL12);

  return pcodec;
}

void qra64_close(qra64codec *pcodec)
{
	free(pcodec);
}

int qra64_apset(qra64codec *pcodec, const int mycall, const int hiscall, const int grid, const int aptype)
{
// Set decoder a-priori knowledge accordingly to the type of the message to look up for
// arguments:
//		pcodec    = pointer to a qra64codec data structure as returned by qra64_init
//		mycall    = mycall to look for
//		hiscall   = hiscall to look for
//		grid      = grid to look for
//		aptype    = define and masks the type of AP to be set accordingly to the following:
//			APTYPE_CQQRZ     set [cq/qrz ?       ?/blank]
//			APTYPE_MYCALL    set [mycall ?       ?/blank]
//			APTYPE_HISCALL   set [?      hiscall ?/blank]
//			APTYPE_BOTHCALLS set [mycall hiscall ?]
//			APTYPE_FULL		 set [mycall hiscall grid]
//			APTYPE_CQHISCALL set [cq/qrz hiscall ?/blank] and [cq/qrz hiscall grid]
// returns:
//		0   on success
//      -1  when qra64_init was called with the QRA_NOAP flag
//		-2  invalid apytpe

	if (pcodec->apflags==QRA_NOAP)
		return -1;

	switch (aptype) {
		case APTYPE_CQQRZ:
			encodemsg_jt65(pcodec->apmsg_cqqrz,  CALL_CQ, 0, GRID_BLANK);
			break;
		case APTYPE_MYCALL:
			encodemsg_jt65(pcodec->apmsg_call1,  mycall,  0, GRID_BLANK);
			break;
		case APTYPE_HISCALL:
			encodemsg_jt65(pcodec->apmsg_call2,  0, hiscall, GRID_BLANK);
			break;
		case APTYPE_BOTHCALLS:
			encodemsg_jt65(pcodec->apmsg_call1_call2,  mycall, hiscall, GRID_BLANK);
			break;
		case APTYPE_FULL:
			encodemsg_jt65(pcodec->apmsg_call1_call2_grid,  mycall, hiscall, grid);
			break;
		case APTYPE_CQHISCALL:
			encodemsg_jt65(pcodec->apmsg_cq_call2,      CALL_CQ, hiscall, GRID_BLANK);
			encodemsg_jt65(pcodec->apmsg_cq_call2_grid, CALL_CQ, hiscall, grid);
			break;
		default:
			return -2;	// invalid ap type
		}

	  pcodec->apmsg_set[aptype]=1;	// signal the decoder to look-up for the specified type


	  return 0;
}
void qra64_apdisable(qra64codec *pcodec, const int aptype)
{
	if (pcodec->apflags==QRA_NOAP)
		return;

	if (aptype<APTYPE_CQQRZ || aptype>=APTYPE_SIZE)
		return;

	pcodec->apmsg_set[aptype] = 0;	//  signal the decoder not to look-up to the specified type
}

void qra64_encode(qra64codec *pcodec, int *y, const int *x)
{
  int encx[QRA64_KC];	// encoder input buffer
  int ency[QRA64_NC];	// encoder output buffer

  int hiscall,mycall,grid;

  memcpy(encx,x,QRA64_K*sizeof(int));		// Copy input to encoder buffer
  encx[QRA64_K]=calc_crc6(encx,QRA64_K);	// Compute and add crc symbol
  qra_encode(&QRA64_CODE, ency, encx);	 // encode msg+crc using given QRA code

  // copy codeword to output puncturing the crc symbol 
  memcpy(y,ency,QRA64_K*sizeof(int));		// copy information symbols 
  memcpy(y+QRA64_K,ency+QRA64_KC,QRA64_C*sizeof(int)); // copy parity symbols 

  if (pcodec->apflags!=QRA_AUTOAP)
    return;

  // Here we handle the QRA_AUTOAP mode --------------------------------------------

  // When a [hiscall mycall ?] msg is detected we instruct the decoder
  // to look for [mycall hiscall ?] msgs
  // otherwise when a [cq mycall ?] msg is sent we reset the APTYPE_BOTHCALLS 

  // look if the msg sent is a std type message (bit15 of grid field = 0)
  if ((x[9]&0x80)==1)
    return;	// no, it's a text message, nothing to do

  // It's a [hiscall mycall grid] message

  // We assume that mycall is our call (but we don't check it)
  // hiscall the station we are calling or a general call (CQ/QRZ/etc..)
  decodemsg_jt65(&hiscall,&mycall,&grid,x);


  if ((hiscall>=CALL_CQ && hiscall<=CALL_CQ999) || hiscall==CALL_CQDX || 
      hiscall==CALL_DE) {
	// tell the decoder to look for msgs directed to us
	qra64_apset(pcodec,mycall,0,0,APTYPE_MYCALL);
    // We are making a general call and don't know who might reply 
    // Reset APTYPE_BOTHCALLS so decoder won't look for [mycall hiscall ?] msgs
    qra64_apdisable(pcodec,APTYPE_BOTHCALLS);
  } else {
    // We are replying to someone named hiscall
    // Set APTYPE_BOTHCALLS so decoder will try for [mycall hiscall ?] msgs
    qra64_apset(pcodec,mycall, hiscall, GRID_BLANK, APTYPE_BOTHCALLS);
  }

}

#define EBNO_MIN -10.0f		// minimum Eb/No value returned by the decoder (in dB)
int qra64_decode(qra64codec *pcodec, float *ebno, int *x, const float *rxen)
{
  int k;
  float *srctmp, *dsttmp;
  float ix[QRA64_NC*QRA64_M];		// (depunctured) intrisic information
  int   xdec[QRA64_KC];				// decoded message (with crc)
  int   ydec[QRA64_NC];				// re-encoded message (for snr calculations)
  float noisestd;					// estimated noise variance
  float msge;						// estimated message energy
  float ebnoval;					// estimated Eb/No
  int rc;
  
  if (QRA64_NMSG!=QRA64_CODE.NMSG)      // sanity check 
    return -16;				// QRA64_NMSG define is wrong

  // compute symbols intrinsic probabilities from received energy observations
  noisestd = qra_mfskbesselmetric(ix, rxen, QRA64_m, QRA64_N,pcodec->decEsNoMetric);

  // de-puncture observations adding a uniform distribution for the crc symbol

  // move check symbols distributions one symbol towards the end
  dsttmp = PD_ROWADDR(ix,QRA64_M, QRA64_NC-1);	//Point to last symbol prob dist
  srctmp = dsttmp-QRA64_M;              // source is the previous pd
  for (k=0;k<QRA64_C;k++) {
    pd_init(dsttmp,srctmp,QRA64_M);
    dsttmp -=QRA64_M;
    srctmp -=QRA64_M;
  }
  // Initialize crc prob to a uniform distribution
  pd_init(dsttmp,pd_uniform(QRA64_m),QRA64_M);

  // Attempt to decode without a-priori info --------------------------------
  rc = qra64_do_decode(xdec, ix, NULL, NULL);
  if (rc>=0) {
	  rc = 0; // successfull decode with AP0
	  goto decode_end;                        
	  }
  else
	  if (pcodec->apflags==QRA_NOAP) 
		  // nothing more to do
		  return rc; // rc<0 = unsuccessful decode

  // Here we handle decoding with AP knowledge

  // Attempt to decode CQ calls
  rc = qra64_do_decode(xdec,ix,pcodec->apmask_cqqrz, pcodec->apmsg_cqqrz); 
  if (rc>=0) { rc = 1; goto decode_end; };    // decoded [cq/qrz ? ?]
  rc = qra64_do_decode(xdec, ix, pcodec->apmask_cqqrz_ooo, 
		       pcodec->apmsg_cqqrz);	                        
  if (rc>=0) { rc = 2; goto decode_end; };    // decoded [cq ? ooo]

  // attempt to decode calls directed to us 
  if (pcodec->apmsg_set[APTYPE_MYCALL]) {
	rc = qra64_do_decode(xdec, ix, pcodec->apmask_call1, 
		       pcodec->apmsg_call1);		                
	if (rc>=0) { rc = 3; goto decode_end; };    // decoded [mycall ? ?]
	rc = qra64_do_decode(xdec, ix, pcodec->apmask_call1_ooo, 
		       pcodec->apmsg_call1);	                    
	if (rc>=0) { rc = 4; goto decode_end; };    // decoded [mycall ? ooo]
	}

  // attempt to decode [mycall srccall ?] msgs
  if (pcodec->apmsg_set[APTYPE_BOTHCALLS]) {
	rc = qra64_do_decode(xdec, ix, pcodec->apmask_call1_call2, 
		       pcodec->apmsg_call1_call2);	                
	if (rc>=0) { rc = 5; goto decode_end; };    // decoded [mycall srccall ?]	
	}

  // attempt to decode [? hiscall ?/b] msgs
  if (pcodec->apmsg_set[APTYPE_HISCALL]) {
	rc = qra64_do_decode(xdec, ix, pcodec->apmask_call2, 
		       pcodec->apmsg_call2);		                
	if (rc>=0) { rc = 6; goto decode_end; };    // decoded [? hiscall ?]
	rc = qra64_do_decode(xdec, ix, pcodec->apmask_call2_ooo, 
		       pcodec->apmsg_call2);	                    
	if (rc>=0) { rc = 7; goto decode_end; };    // decoded [? hiscall ooo]
	}

  // attempt to decode [cq/qrz hiscall ?/b/grid] msgs
  if (pcodec->apmsg_set[APTYPE_CQHISCALL]) {

	rc = qra64_do_decode(xdec, ix, pcodec->apmask_cq_call2, 
				pcodec->apmsg_cq_call2);		                
	if (rc>=0) { rc = 9; goto decode_end; };    // decoded [cq/qrz hiscall ?]

	rc = qra64_do_decode(xdec, ix, pcodec->apmask_cq_call2_ooo, 
		       pcodec->apmsg_cq_call2_grid);	
	if (rc>=0) {
		// Full AP mask need special handling
		// To minimize false decodes we check the decoded message
		// with what passed in the ap_set call
		if (memcmp(pcodec->apmsg_cq_call2_grid,xdec, QRA64_K*sizeof(int))!=0) 
			return -1;
		rc = 11; goto decode_end; 
		};    // decoded [cq/qrz hiscall grid]

	rc = qra64_do_decode(xdec, ix, pcodec->apmask_cq_call2_ooo, 
		       pcodec->apmsg_cq_call2);	                    
	if (rc>=0) { 
		// Full AP mask need special handling
		// To minimize false decodes we check the decoded message
		// with what passed in the ap_set call
		if (memcmp(pcodec->apmsg_cq_call2,xdec, QRA64_K*sizeof(int))!=0) 
			return -1;
		rc = 10; goto decode_end; };    // decoded [cq/qrz hiscall ]
	}

  // attempt to decode [mycall hiscall grid]
  if (pcodec->apmsg_set[APTYPE_FULL]) {
	rc = qra64_do_decode(xdec, ix, pcodec->apmask_call1_call2_grid, 
		       pcodec->apmsg_call1_call2_grid); 
	if (rc>=0) { 
		// Full AP mask need special handling
		// All the three msg fields were given.
		// To minimize false decodes we check the decoded message
		// with what passed in the ap_set call
		if (memcmp(pcodec->apmsg_call1_call2_grid,xdec, QRA64_K*sizeof(int))!=0) 
			return -1;
		rc = 8; goto decode_end; 
		};    // decoded [mycall hiscall grid]
	}

  // all decoding attempts failed
  return rc;

decode_end: // successfull decode 
  
  // copy decoded message (without crc) to output buffer
  memcpy(x,xdec,QRA64_K*sizeof(int));

  if (ebno==0)	// null pointer indicates we are not interested in the Eb/No estimate
	  return rc;

  // reencode message and estimate Eb/No
  qra_encode(&QRA64_CODE, ydec, xdec);	 
  // puncture crc
  memmove(ydec+QRA64_K,ydec+QRA64_KC,QRA64_C*sizeof(int)); 
  // compute total power of decoded message
  msge = 0;
  for (k=0;k<QRA64_N;k++) {
	  msge +=rxen[ydec[k]];	// add energy of current symbol
	  rxen+=QRA64_M;			// ptr to next symbol
	  }

  // NOTE:
  // To make a more accurate Eb/No estimation we should compute the noise variance
  // on all the rxen values but the transmitted symbols.
  // Noisestd is compute by qra_mfskbesselmetric assuming that
  // the signal power is much less than the total noise power in the QRA64_M tones
  // but this is true only if the Eb/No is low.
  // Here, in order to improve accuracy, we linearize the estimated Eb/No value empirically
  // (it gets compressed when it is very high as in this case the noise variance 
  // is overestimated)

  // this would be the exact value if the noisestd were not overestimated at high Eb/No
  ebnoval = (0.5f/(QRA64_K*QRA64_m))*msge/(noisestd*noisestd)-1.0f; 

  // Empirical linearization (to remove the noise variance overestimation)
  // the resulting SNR is accurate up to +20 dB (51 dB Eb/No)
  if (ebnoval>57.004f)
	  ebnoval=57.004f;
  ebnoval = ebnoval*57.03f/(57.03f-ebnoval);

  // compute value in dB
  if (ebnoval<=0)
	  ebnoval = EBNO_MIN; // assume a minimum, positive value
  else
	  ebnoval = 10.0f*(float)log10(ebnoval);
	  if (ebnoval<EBNO_MIN)
		  ebnoval = EBNO_MIN;
  
  *ebno = ebnoval;

  return rc;	
}

// Static functions definitions ----------------------------------------------

// Decode with given a-priori information 
static int qra64_do_decode(int *xdec, const float *pix, const int *ap_mask, 
			   const int *ap_x)
{
  int rc;
  const float *ixsrc;
  float ix_masked[QRA64_NC*QRA64_M];  // Masked intrinsic information
  float ex[QRA64_NC*QRA64_M];	      // Extrinsic information from the decoder

  float v2cmsg[QRA64_NMSG*QRA64_M];   // buffers for the decoder messages
  float c2vmsg[QRA64_NMSG*QRA64_M];

  if (ap_mask==NULL) {   // no a-priori information
    ixsrc = pix;	 // intrinsic source is what passed as argument
  } else {	
    // a-priori information provided
    // mask channel observations with a-priori 
    ix_mask(ix_masked,pix,ap_mask,ap_x);
    ixsrc = ix_masked;	// intrinsic source is the masked version
  }

  // run the decoding algorithm
  rc = qra_extrinsic(&QRA64_CODE,ex,ixsrc,QRA64_NITER,v2cmsg,c2vmsg);
  if (rc<0)
    return -1;	// no convergence in given iterations

  // decode 
  qra_mapdecode(&QRA64_CODE,xdec,ex,ixsrc);

  // verify crc
  if (calc_crc6(xdec,QRA64_K)!=xdec[QRA64_K]) // crc doesn't match (detected error)
    return -2;	// decoding was succesfull but crc doesn't match

  return 0;
}
// crc functions --------------------------------------------------------------
// crc-6 generator polynomial
// g(x) = x^6 + a5*x^5 + ... + a1*x + a0

// g(x) = x^6 + x + 1  
#define CRC6_GEN_POL 0x30  // MSB=a0 LSB=a5    

// g(x) = x^6 + x^2 + x + 1 (See:  https://users.ece.cmu.edu/~koopman/crc/)
// #define CRC6_GEN_POL 0x38  // MSB=a0 LSB=a5. Simulation results are similar

static int calc_crc6(const int *x, int sz)
{
  // todo: compute it faster using a look up table
  int k,j,t,sr = 0;
  for (k=0;k<sz;k++) {
    t = x[k];
    for (j=0;j<6;j++) {
      if ((t^sr)&0x01)
	sr = (sr>>1) ^ CRC6_GEN_POL;
      else
	sr = (sr>>1);
      t>>=1;
    }
  }
  return sr;
}

static void ix_mask(float *dst, const float *src, const int *mask, 
		    const int *x)
{
  // mask intrinsic information (channel observations) with a priori knowledge
	
  int k,kk, smask;
  float *row;

  memcpy(dst,src,(QRA64_NC*QRA64_M)*sizeof(float));

  for (k=0;k<QRA64_K;k++) {	// we can mask only information symbols distrib
    smask = mask[k];
    row = PD_ROWADDR(dst,QRA64_M,k);
    if (smask) {
      for (kk=0;kk<QRA64_M;kk++) 
	if (((kk^x[k])&smask)!=0)
	  *(row+kk) = 0.f;

      pd_norm(row,QRA64_m);
    }
  }
}

// encode/decode msgs as done in JT65
void encodemsg_jt65(int *y, const int call1, const int call2, const int grid)
{
  y[0]= (call1>>22)&0x3F;
  y[1]= (call1>>16)&0x3F;
  y[2]= (call1>>10)&0x3F;
  y[3]= (call1>>4)&0x3F;
  y[4]= (call1<<2)&0x3F;

  y[4] |= (call2>>26)&0x3F;
  y[5]= (call2>>20)&0x3F;
  y[6]= (call2>>14)&0x3F;
  y[7]= (call2>>8)&0x3F;
  y[8]= (call2>>2)&0x3F;
  y[9]= (call2<<4)&0x3F;

  y[9] |= (grid>>12)&0x3F;
  y[10]= (grid>>6)&0x3F;
  y[11]= (grid)&0x3F;

}
void decodemsg_jt65(int *call1, int *call2, int *grid, const int *x)
{
  int nc1, nc2, ng;

  nc1 = x[4]>>2;
  nc1 |= x[3]<<4;
  nc1 |= x[2]<<10;
  nc1 |= x[1]<<16;
  nc1 |= x[0]<<22;

  nc2 = x[9]>>4;
  nc2 |= x[8]<<2;
  nc2 |= x[7]<<8;
  nc2 |= x[6]<<14;
  nc2 |= x[5]<<20;
  nc2 |= (x[4]&0x03)<<26;

  ng   = x[11];
  ng  |= x[10]<<6;
  ng  |= (x[9]&0x0F)<<12;

  *call1 = nc1;
  *call2 = nc2;
  *grid  = ng;
}
