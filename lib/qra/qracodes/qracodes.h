// qracodes.h
// Q-ary RA codes encoding/decoding functions
// 
// (c) 2016 - Nico Palermo, IV3NWV - Microtelecom Srl, Italy
// ------------------------------------------------------------------------------
// This file is part of the qracodes project, a Forward Error Control
// encoding/decoding package based on Q-ary RA (Repeat and Accumulate) LDPC codes.
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

#ifndef _qracodes_h_
#define _qracodes_h_

typedef unsigned int uint;

// type of codes
#define QRATYPE_NORMAL			0x00 // normal code 
#define QRATYPE_CRC 			0x01 // code with crc - last information symbol is a CRC
#define QRATYPE_CRCPUNCTURED 	0x02 // the CRC symbol is punctured (not sent along the channel)


typedef struct {
	// code parameters
	const uint K;			// number of information symbols
	const uint N;			// codeword length in symbols
	const uint m;			// bits/symbol
	const uint M;			// Symbol alphabet cardinality (2^m)
	const uint a;			// code grouping factor
	const uint NC;			// number of check symbols (N-K)
	const uint V;			// number of variables in the code graph (N)
	const uint C;			// number of factors in the code graph (N +(N-K)+1)
	const uint NMSG;		// number of msgs in the code graph
	const uint MAXVDEG;		// maximum variable degree 
	const uint MAXCDEG;		// maximum factor degree
	const uint type;		// see QRATYPE_xx defines
	const float R;			// code rate (K/N)
	const char  name[64];	// code name
	// tables used by the encoder
	const int	 *acc_input_idx;	
	const uint   *acc_input_wlog;
	const int	 *gflog;
	const uint   *gfexp;
	// tables used by the decoder -------------------------
	const uint *msgw;
	const uint *vdeg;
	const uint *cdeg;
	const int  *v2cmidx;
	const int  *c2vmidx;
	const int  *gfpmat;
} qracode;
// Uncomment the header file of the code which needs to be tested

//#include "qra12_63_64_irr_b.h"  // irregular code (12,63) over GF(64)
//#include "qra13_64_64_irr_e.h"  // irregular code with good performance and best UER protection at AP56
//#include "qra13_64_64_reg_a.h"  // regular code with good UER but perf. inferior to that of code qra12_63_64_irr_b

#ifdef __cplusplus
extern "C" {
#endif

int  qra_encode(const qracode *pcode, uint *y, const uint *x);
void qra_mfskbesselmetric(float *pix, const float *rsq, const uint m, const uint N, float EsNoMetric);
int  qra_extrinsic(const qracode *pcode, float *pex, const float *pix, int maxiter,float *qra_v2cmsg,float *qra_c2vmsg);
void qra_mapdecode(const qracode *pcode, uint *xdec, float *pex, const float *pix);

#ifdef __cplusplus
}
#endif

#endif // _qracodes_h_
