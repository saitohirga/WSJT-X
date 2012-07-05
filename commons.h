#ifndef COMMONS_H
#define COMMONS_H

#define NFFT 32768

extern "C" {

extern struct {                     //This is "common/datcom/..." in Fortran
  short int d2[30*48000];           //Raw data
  int kin;
  int ndiskdat;
} datcom_;
}

#endif // COMMONS_H
