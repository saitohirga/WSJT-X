// qra65.h
// QRA65 modes encoding/decoding functions
// 
// (c) 2020 - Nico Palermo, IV3NWV - Microtelecom Srl, Italy
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

#ifndef _qra65_h
#define _qra65_h

#include "qracodes.h"

// Error codes returned by qra65_decode(...) 
#define QRA65_DECODE_INVPARAMS	 -1
#define QRA65_DECODE_FAILED		 -2
#define QRA65_DECODE_CRCMISMATCH -3

// maximum number of weights for the fast-fading metric evaluation
#define QRA65_FASTFADING_MAXWEIGTHS 65

typedef struct {
	const qracode *pQraCode; // qra code to be used by the codec
	float decoderEsNoMetric; // value for which we optimize the decoder metric
	int		*x;				 // codec input 
	int		*y;				 // codec output
	float	*qra_v2cmsg;	 // decoder v->c messages
	float	*qra_c2vmsg;	 // decoder c->v messages 
	float	*ix;			 // decoder intrinsic information
	float	*ex;			 // decoder extrinsic information 
	// variables used to compute the intrinsics in the fast-fading case
	int     nBinsPerTone;
	int		nBinsPerSymbol;
	float   ffNoiseVar;	
	float   ffEsNoMetric;
	int	    nWeights;
	float   ffWeight[QRA65_FASTFADING_MAXWEIGTHS]; 
} qra65_codec_ds;

int		qra65_init(qra65_codec_ds *pCodec, const qracode *pQraCode);
void	qra65_free(qra65_codec_ds *pCodec);

int		qra65_encode(const qra65_codec_ds *pCodec, int *pOutputCodeword, const int *pInputMsg);

int		qra65_intrinsics(qra65_codec_ds *pCodec, float *pIntrinsics, const float *pInputEnergies);

int		qra65_intrinsics_fastfading(qra65_codec_ds *pCodec, 
					float *pIntrinsics,				// intrinsic symbol probabilities output
					const float *pInputEnergies,	// received energies input
					const int submode,				// submode idx (0=A ... 4=E)
					const float B90,				// spread bandwidth (90% fractional energy)
					const int fadingModel);			// 0=Gaussian 1=Lorentzian fade model


int		qra65_decode(qra65_codec_ds *pCodec, 
					 int* pDecodedCodeword, 
					 int *pDecodedMsg, 
					 const float *pIntrinsics, 
					 const int *pAPMask, 
					 const int *pAPSymbols);

int		qra65_esnodb(const qra65_codec_ds *pCodec,
					float		*pEsNodB,
					const int *ydec, 
					const float *pInputEnergies);

int		qra65_esnodb_fastfading(
					const qra65_codec_ds *pCodec,
					float		*pEsNodB,
					const int   *ydec,
					const float *pInputEnergies);


#define qra65_get_message_length(pCodec)  _qra65_get_message_length((pCodec)->pQraCode)
#define qra65_get_codeword_length(pCodec) _qra65_get_codeword_length((pCodec)->pQraCode)
#define qra65_get_code_rate(pCodec)		  _qra65_get_code_rate((pCodec)->pQraCode)
#define qra65_get_alphabet_size(pCodec)	  _qra65_get_alphabet_size((pCodec)->pQraCode)
#define qra65_get_bits_per_symbol(pCodec) _qra65_get_bits_per_symbol((pCodec)->pQraCode)

// internally used but made publicly available for the defines above
int		_qra65_get_message_length(const qracode *pCode);
int		_qra65_get_codeword_length(const qracode *pCode);
float	_qra65_get_code_rate(const qracode *pCode);
void	_qra65_mask(const qracode *pcode, float *ix, const int *mask, const int *x);
int		_qra65_get_alphabet_size(const qracode *pCode);
int		_qra65_get_bits_per_symbol(const qracode *pCode);

#endif // _qra65_h