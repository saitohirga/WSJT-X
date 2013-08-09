#ifndef COMMONS_H
#define COMMONS_H

#define NSMAX 6827
#define NTMAX 120
#define RX_SAMPLE_RATE 12000

extern struct FortranCommon {
  float ss[184*NSMAX];              //This is "common/jt9com/..." in fortran
  float savg[NSMAX];
  short int d2[NTMAX*RX_SAMPLE_RATE];
  int nutc;                         //UTC as integer, HHMM
  int ndiskdat;                     //1 ==> data read from *.wav file
  int ntrperiod;                    //TR period (seconds)
  int nfqso;                        //User-selected QSO freq (kHz)
  int newdat;                       //1 ==> new data, must do long FFT
  int npts8;                        //npts for c0() array
  int nfa;                          //Low decode limit (Hz)
  int nfSplit;                      //JT65 | JT9 split frequency
  int nfb;                          //High decode limit (Hz)
  int ntol;                         //+/- decoding range around fQSO (Hz)
  int kin;
  int nzhsym;
  int nsave;
  int nagain;
  int ndepth;
  int ntxmode;
  int nmode;
  char datetime[20];
} jt9com_;

#endif // COMMONS_H
