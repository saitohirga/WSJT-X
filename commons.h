#ifndef COMMONS_H
#define COMMONS_H

#define NFFT 32768

extern "C" {

extern struct {                     //This is "common/mscom/..." in Fortran
  short int d2[30*48000];           //Raw data from soundcard
  float s1[215];
  float s2[215];
  int kin;
  int ndiskdat;
  int kline;
} mscom_;
}

#endif // COMMONS_H
