#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

/* seed rand using urandom */
float sgran_()
{
  unsigned int seed;
  FILE *urandom;
  urandom = fopen ("/dev/urandom","r");
  fread (&seed, sizeof (seed), 1, urandom);
  srand (seed);

  return(0);
}
