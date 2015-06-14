/*
 This file is part of wsprd.
 
 File name: fano.h

 Description: Header file for sequential Fano decoder.

 Copyright 1994, Phil Karn, KA9Q
 Minor modifications by Joe Taylor, K1JT
*/

#ifndef FANO_H
#define FANO_H

int fano(unsigned int *metric, unsigned int *cycles, unsigned int *maxnp,
	unsigned char *data,unsigned char *symbols, unsigned int nbits,
	 int mettab[2][256],int delta,unsigned int maxcycles);

int encode(unsigned char *symbols,unsigned char *data,unsigned int nbytes);

extern unsigned char Partab[];

#endif
