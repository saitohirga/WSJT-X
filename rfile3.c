#include <stdio.h>

void rfile3_(char *infile, char buf[], int *nbytes0)
{
  int n,nbytes;
  static int first=1;
  static FILE *fd=NULL;

  nbytes=*nbytes0;
  if(first) {
    fd = fopen(infile,"rb");
    if(fd == NULL) {
      printf("Cannot open %s\n",infile);
      exit(0);
    }
    first=0;
  }

  n=fread(buf,1,nbytes,fd);
  printf("b: %d   %d\n",nbytes,n);
  return(n);
}
