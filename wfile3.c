#include <stdio.h>

void wfile3_(char *outfile, char buf[], int *nbytes0)
{
  int n,nbytes;
  static int first=1;
  static FILE *fp=NULL;

  nbytes=*nbytes0;
  fp = fopen(outfile,"wb");
  if(fp == NULL) {
    printf("Cannot create %s\n",outfile);
    exit(0);
  }

  n=fwrite(buf,1,nbytes,fp);
  fclose(fp);
  return(n);
}
