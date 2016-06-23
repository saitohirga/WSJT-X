// qra65.c 
// Encoding/decoding functions for the QRA65 mode
// 
// (c) 2016 - Nico Palermo, IV3NWV
// 
// -------------------------------------------------------------------------------
//
//    qracodes is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, either version 3 of the License, or
//    (at your option) any later version.
//    qracodes is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//    GNU General Public License for more details.

//    You should have received a copy of the GNU General Public License
//    along with qracodes source distribution.  
//    If not, see <http://www.gnu.org/licenses/>.

// -----------------------------------------------------------------------------

// Code used in this sowftware release:

// QRA13_64_64_IRR_E: K=13 N=64 Q=64 irregular QRA code (defined in qra13_64_64_irr_e.h /.c)

// Codes with K=13 are designed to include a CRC as the 13th information symbol
// and improve the code UER (Undetected Error Rate).
// The CRC symbol is not sent along the channel (the codes are punctured) and the 
// resulting code is a (12,63) code 

// ------------------------------------------------------------------------------

#include <stdlib.h>
#include <math.h>

#include "qra65.h"
#include "../qracodes/qracodes.h"
#include "../qracodes/qra13_64_64_irr_e.h"
#include "../qracodes/pdmath.h"

// Code parameters of the QRA65 mode 
#define QRA65_CODE  qra_13_64_64_irr_e
#define QRA65_NMSG  218 // this must much  the value indicated in QRA65_CODE.NMSG

#define QRA65_KC (QRA65_K+1) // information symbols crc included (as defined in the code)
#define QRA65_NC (QRA65_N+1) // codeword length (as defined in the code)
#define QRA65_NITER 100		 // max number of iterations per decode



// static functions declarations -------------------------------------------------
static int  calc_crc6(const int *x, int sz);
static void ix_mask(float *dst, const float *src, const int *mask, const int *x);
static int  qra65_do_decode(int *x, const float *pix, const int *ap_mask, const int *ap_x);

// a-priori information masks for fields in jt65-like msgs -----------------------

#define MASK_CQQRZ      0xFFFFFFC // CQ/QRZ calls common bits
#define MASK_CALL1      0xFFFFFFF
#define MASK_CALL2      0xFFFFFFF
#define MASK_GRIDFULL	0xFFFF
#define MASK_GRIDBIT	0x8000	  // b[15] is 0 for all the messages which are not text

// -------------------------------------------------------------------------------

qra65codec *qra65_init(int flags, const int mycall)
{

	// Eb/No value for which we optimize the decoder metric
	const float EbNodBMetric = 2.8f; 
	const float EbNoMetric   = (float)pow(10,EbNodBMetric/10);
	const float R = 1.0f*(QRA65_KC)/(QRA65_NC);	

	qra65codec *pcodec = (qra65codec*)malloc(sizeof(qra65codec));

	if (!pcodec)
		return 0;	// can't allocate memory
	
	pcodec->decEsNoMetric   = 1.0f*QRA65_m*R*EbNoMetric;
	pcodec->apflags			= flags;

	if (flags!=QRA_AUTOAP)
		return pcodec;

	// initialize messages and mask for decoding with a-priori information

	pcodec->apmycall  = mycall;
	pcodec->apsrccall = 0;	

	// encode CQ/QRZ messages and masks
	// NOTE: Here we handle only CQ and QRZ msgs
	// 'CQ nnn', 'CQ DX' and 'DE' msgs 
	// will be handled by the decoder as messages with no a-priori knowledge
	encodemsg_jt65(pcodec->apmsg_cqqrz,	     CALL_CQ,	0, GRID_BLANK);
	encodemsg_jt65(pcodec->apmask_cqqrz,	 MASK_CQQRZ,0, MASK_GRIDBIT);	// AP27 (26+1)
	encodemsg_jt65(pcodec->apmask_cqqrz_ooo, MASK_CQQRZ,0, MASK_GRIDFULL);	// AP42	(26+16)

	// encode [mycall ? x] messages and set masks
	encodemsg_jt65(pcodec->apmsg_call1,      mycall,  0, GRID_BLANK);
	encodemsg_jt65(pcodec->apmask_call1,	 MASK_CALL1, 0, MASK_GRIDBIT);	// AP29 (28+1)
	encodemsg_jt65(pcodec->apmask_call1_ooo, MASK_CALL1, 0, MASK_GRIDFULL); // AP44	(28+16)

	// set mask for  [mycall srccall ?] messages
	encodemsg_jt65(pcodec->apmask_call1_call2,MASK_CALL1, MASK_CALL2, MASK_GRIDBIT); // AP56 (28+28)

	return pcodec;
}

void qra65_encode(qra65codec *pcodec, int *y, const int *x)
{
	int encx[QRA65_KC];	// encoder input buffer
	int ency[QRA65_NC];	// encoder output buffer

	int call1,call2,grid;

	memcpy(encx,x,QRA65_K*sizeof(int));			 // copy input to the encoder buffer
	encx[QRA65_K]=calc_crc6(encx,QRA65_K);	     // compute and add the crc symbol

	qra_encode(&QRA65_CODE, ency, encx);		 // encode msg+crc using the given QRA code

	// copy codeword to output puncturing the crc symbol 
	memcpy(y,ency,QRA65_K*sizeof(int));					 // copy the information symbols 
	memcpy(y+QRA65_K,ency+QRA65_KC,QRA65_C*sizeof(int)); // copy the parity check symbols 

	if (pcodec->apflags!=QRA_AUTOAP)
		return;

	// look if the msg sent is a std type message (bit15 of grid field = 0)
	if ((x[9]&0x80)==1)
		return;	// no, it's a text message

	// it's a [call1 call2 grid] message

	// we assume that call2 is our call (but we don't check it)
	// call1 the station callsign we are calling or indicates a general call (CQ/QRZ/etc..)
	decodemsg_jt65(&call1,&call2,&grid,x);
	
	if ((call1>=CALL_CQ && call1<=CALL_CQ999) || call1==CALL_CQDX || call1==CALL_DE) {
		// we are making a general call, so we still don't know who can reply us (srccall)
		// reset apsrccall to 0 so that the decoder won't look for [mycall srccall ?] msgs
		pcodec->apsrccall = 0;
		}
	else {
		// we are replying someone named call1
		// set apmsg_call1_call2 so that the decoder will attempt to decode [mycall call1 ?] msgs
		pcodec->apsrccall = call1;
		encodemsg_jt65(pcodec->apmsg_call1_call2, pcodec->apmycall, pcodec->apsrccall, 0);
		}

}

int qra65_decode(qra65codec *pcodec, int *x, const float *rxen)
{
	uint k;
	float *srctmp, *dsttmp;
	float ix[QRA65_NC*QRA65_M];		// (depunctured) intrisic information to the decoder
	int rc;

	// sanity check 
	if (QRA65_NMSG!=QRA65_CODE.NMSG)
		return -16;					// QRA65_NMSG define is wrong

	// compute symbols intrinsic probabilities from received energy observations
	qra_mfskbesselmetric(ix, rxen, QRA65_m, QRA65_N,pcodec->decEsNoMetric);

	// de-puncture observations adding a uniform distribution for the crc symbol ----------

	// move check symbols distributions one symbol towards the end
	dsttmp = PD_ROWADDR(ix,QRA65_M, QRA65_NC-1);	// point to the last symbol prob dist
	srctmp = dsttmp-QRA65_M; // source is the previous pd
	for (k=0;k<QRA65_C;k++) {
		pd_init(dsttmp,srctmp,QRA65_M);
		dsttmp -=QRA65_M;
		srctmp -=QRA65_M;
		}
	// init crc prob to a uniform distribution
	pd_init(dsttmp,pd_uniform(QRA65_m),QRA65_M);

	// attempt to decode without a-priori --------------------------------------------------
	rc = qra65_do_decode(x, ix, NULL, NULL);
	if (rc>=0) return 0; // successfull decode with 0 ap

	if (pcodec->apflags!=QRA_AUTOAP) return rc; // rc<0 = unsuccessful decode

	// attempt to decode CQ calls
	rc = qra65_do_decode(x, ix, pcodec->apmask_cqqrz, pcodec->apmsg_cqqrz);	    // 27 bit AP
	if (rc>=0) return 1;	// decoded [cq/qrz ? ?]
	rc = qra65_do_decode(x, ix, pcodec->apmask_cqqrz_ooo, pcodec->apmsg_cqqrz);	// 44 bit AP
	if (rc>=0) return 2;	// decoded [cq ? ooo]

	// attempt to decode calls directed to us (mycall)
	rc = qra65_do_decode(x, ix, pcodec->apmask_call1, pcodec->apmsg_call1);		// 29 bit AP
	if (rc>=0) return 3;	// decoded [mycall ? ?]
	rc = qra65_do_decode(x, ix, pcodec->apmask_call1_ooo, pcodec->apmsg_call1);	// 45 bit AP
	if (rc>=0) return 4;	// decoded [mycall ? ooo]

	// if apsrccall is set attempt to decode [mycall srccall ?] msgs
	if (pcodec->apsrccall==0) return rc; // nothing more to do

	rc = qra65_do_decode(x, ix, pcodec->apmask_call1_call2, pcodec->apmsg_call1_call2);	// 57 bit AP
	if (rc>=0) return 5;	// decoded [mycall srccall ?]	

	return rc;	
}

// static functions definitions ----------------------------------------------------------------

// decode with given a-priori information 
static int qra65_do_decode(int *x, const float *pix, const int *ap_mask, const int *ap_x)
{
	int rc;
	const float *ixsrc;
	float ix_masked[QRA65_NC*QRA65_M];	// (masked) intrinsic information to the decoder
	float ex[QRA65_NC*QRA65_M];			// extrinsic information from the decoder

	float v2cmsg[QRA65_NMSG*QRA65_M];	// buffers for the decoder messages
	float c2vmsg[QRA65_NMSG*QRA65_M];
	int   xdec[QRA65_KC];

	if (ap_mask==NULL) { // no a-priori information
		ixsrc = pix;	 // intrinsic source is what passed as argument
		}
	else {	// a-priori information provided
		// mask channel observations with a-priori 
		ix_mask(ix_masked,pix,ap_mask,ap_x);
		ixsrc = ix_masked;	// intrinsic source is the masked version
	}

	// run the decoding algorithm
	rc = qra_extrinsic(&QRA65_CODE,ex,ixsrc,QRA65_NITER,v2cmsg,c2vmsg);
	if (rc<0)
		return -1;	// no convergence in given iterations

	// decode 
	qra_mapdecode(&QRA65_CODE,xdec,ex,ixsrc);

	// verify crc
	if (calc_crc6(xdec,QRA65_K)!=xdec[QRA65_K]) // crc doesn't match (detected error)
		return -2;	// decoding was succesfull but crc doesn't match

	// success. copy decoded message to output buffer
	memcpy(x,xdec,QRA65_K*sizeof(int));

	return 0;

}
// crc functions -------------------------------------------------------------------------------
// crc-6 generator polynomial
// g(x) = x^6 + a5*x^5 + ... + a1*x + a0

// g(x) = x^6 + x + 1  
#define CRC6_GEN_POL 0x30  // MSB=a0 LSB=a5    

// g(x) = x^6 + x^2 + x + 1 (as suggested by Joe. See:  https://users.ece.cmu.edu/~koopman/crc/)
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

static void ix_mask(float *dst, const float *src, const int *mask, const int *x)
{
	// mask intrinsic information (channel observations) with a priori knowledge
	
	uint k,kk, smask;
	float *row;

	memcpy(dst,src,(QRA65_NC*QRA65_M)*sizeof(float));

	for (k=0;k<QRA65_K;k++) {	// we can mask only information symbols distrib
		smask = mask[k];
		row = PD_ROWADDR(dst,QRA65_M,k);
		if (smask) {
			for (kk=0;kk<QRA65_M;kk++) 
				if (((kk^x[k])&smask)!=0)
					*(row+kk) = 0.f;

			pd_norm(row,QRA65_m);
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


