#include <stdio.h>
//#ifdef CVF
#include "samplerate.h"
//#else
//#include <samplerate.h>
//#endif

int resample_(float din[], int *jzin, int *conv_type, int *channels, 
	      double *samfac, float dout[], int *jzout)
{
  SRC_DATA src_data;
  int input_len;
  int output_len;
  int ierr;
  double src_ratio;

  src_ratio=*samfac;
  input_len=*jzin;
  output_len=(int) (input_len*src_ratio);

  src_data.data_in=din;
  src_data.data_out=dout;
  src_data.src_ratio=src_ratio;
  src_data.input_frames=input_len;
  src_data.output_frames=output_len;

  ierr=src_simple(&src_data,*conv_type,*channels);
  *jzout=output_len;
  return ierr;
}
