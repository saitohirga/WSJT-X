#ifndef COMMONS_H
#define COMMONS_H

#define NSMAX 22000

extern "C" {

extern struct {
  float ss[184*NSMAX];              //This is "common/jt9com/..." in fortran
  float savg[NSMAX];
  short int d2[1800*12000];
  int nutc;                         //UTC as integer, HHMM
  int ndiskdat;                     //1 ==> data read from *.wav file
  int ntrperiod;                    //TR period (seconds)
  int nfqso;                        //User-selected QSO freq (kHz)
  int newdat;                       //1 ==> new data, must do long FFT
  int npts8;                        //npts for c0() array
  int nfb;                          //High decode limit (kHz)
  int ntol;                         //+/- decoding range around fQSO (Hz)
  int kin;
  int nsynced;
  int ndecoded;
} jt9com_;

}

#endif // COMMONS_H
