// qra65.h
// Encoding/decoding functions for the QRA65 mode
// 
// (c) 2016 - Nico Palermo, IV3NWV 
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

#ifndef _qra65_h_
#define _qra65_h_

// qra65_init(...) initialization flags
#define QRA_NOAP   0	// don't use a-priori knowledge
#define QRA_AUTOAP 1	// use  auto a-priori knowledge 

// QRA code parameters
#define QRA65_K  12	// information symbols
#define QRA65_N  63	// codeword length
#define QRA65_C  51	// (number of parity checks C=(N-K))
#define QRA65_M  64	// code alphabet size
#define QRA65_m  6	// bits per symbol

// packed predefined callsigns and fields as defined in JT65
#define CALL_CQ			0xFA08319 
#define CALL_QRZ		0xFA0831A 
#define CALL_CQ000      0xFA0831B
#define CALL_CQ999      0xFA08702
#define CALL_CQDX		0x5624C39
#define CALL_DE  		0xFF641D1
#define GRID_BLANK		0x7E91

typedef struct {
		float decEsNoMetric;
		int apflags;
		int apmycall;
		int apsrccall;
		int apmsg_cqqrz[12];		// [cq/qrz ? blank] 
		int apmsg_call1[12];		// [mycall ? blank] 
		int apmsg_call1_call2[12];	// [mycall srccall ?]
		int apmask_cqqrz[12];		
		int apmask_cqqrz_ooo[12];	
		int apmask_call1[12];        
		int apmask_call1_ooo[12];    
		int apmask_call1_call2[12];  
} qra65codec;

#ifdef __cplusplus
extern "C" {
#endif

qra65codec *qra65_init(int flags, const int mycall);
// QRA65 mode initialization function
// arguments:
//		flags: set the decoder mode
//				When flags = QRA_NOAP    no a-priori information will be used by the decoder
//				When flags = QRA_AUTOAP  the decoder will attempt to decode with the amount
//              of available a-priori information
//		mycall: 28-bit packed callsign of the user (as computed by JT65)
// returns:
//      Pointer to the qra65codec data structure allocated and inizialized by the function
//		this handle should be passed to the encoding/decoding functions
//
//		0   if unsuccessful (can't allocate memory)
// -------------------------------------------------------------------------------------------

void qra65_encode(qra65codec *pcodec, int *y, const int *x);
// QRA65 mode encoder
// arguments:
//		pcodec = pointer to a qra65codec data structure as returned by qra65_init
//      x      = pointer to the message to encode
//				 x must point to an array of integers (i.e. defined as int x[12])
//      y      = pointer to the encoded message
//				 y must point to an array of integers of lenght 63 (i.e. defined as int y[63])
// -------------------------------------------------------------------------------------------

int  qra65_decode(qra65codec *pcodec, int *x, const float *r);
// QRA65 mode decoder
// arguments:
//		pcodec = pointer to a qra65codec data structure as returned by qra65_init
//      x      = pointer to the array of integers where the decoded message will be stored
//				 x must point to an array of integers (i.e. defined as int x[12])
//		r      = pointer to the received symbols energies (squared amplitudes)
//               r must point to an array of QRA65_M*QRA65_N (=64*63=4032) float numbers.
//				 The first QRA_M entries should be the energies of the first symbol in the codeword
//               The last QRA_M entries should be the energies of the last symbol in the codeword
//
// return code:
//
//  The return code is <0 when decoding is unsuccessful
//  -16 indicates that the definition of QRA65_NMSG does not match what required by the code
//  If the decoding process is successfull the return code is accordingly to the following table
//		rc=0    [?    ?    ?] AP0	(decoding with no a-priori)
//		rc=1    [CQ   ?    ?] AP27
//		rc=2    [CQ   ?     ] AP44
//		rc=3    [CALL ?    ?] AP29
//		rc=4    [CALL ?     ] AP45
//		rc=5    [CALL CALL ?] AP57
//  return codes in the range 1-5 indicate the amount of a-priori information which was required
//  to decode the received message and are possible only when the QRA_AUTOAP mode has been enabled.
// -------------------------------------------------------------------------------------------

// encode/decode std msgs in 12 symbols as done in jt65
void encodemsg_jt65(int *y, const int call1, const int call2, const int grid);
void decodemsg_jt65(int *call1, int *call2, int *grid, const int *x);

#ifdef __cplusplus
}
#endif

#endif // _qra65_h_
