#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>
#include <stdint.h>
#include <time.h>

void unpack50( signed char *dat, int32_t *n1, int32_t *n2 );

void unpackcall( int32_t ncall, char *call );

void unpackgrid( int32_t ngrid, char *grid);

void unpackpfx( int32_t nprefix, char *call);

void deinterleave(unsigned char *sym);

// used by qsort
int floatcomp(const void* elem1, const void* elem2);

unsigned int nhash_( const void *key, size_t length, uint32_t initval);

int unpk_( signed char *message, char hashtab[32768][13], char *call_loc_pow, char *callsign);