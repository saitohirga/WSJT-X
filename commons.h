#ifndef COMMONS_H
#define COMMONS_H

#define NFFT 32768

extern "C" {

extern struct {
  short int d2[1800*12000];         //This is "common/jt8com/..." in fortran
  float ss[184*32768];
  float savg[32768];
  double fcenter;                   //USB dial freq (kHz)
  int nutc;                         //UTC as integer, HHMM
  int mousedf;                      //User-selected DF
  int mousefqso;                    //User-selected QSO freq (kHz)
  int nagain;                       //1 ==> decode only at fQSO +/- Tol
  int ndepth;                       //How much hinted decoding to do?
  int ndiskdat;                     //1 ==> data read from *.tf2 or *.iq file
  int newdat;                       //1 ==> new data, must do long FFT
  int nfa;                          //Low decode limit (kHz)
  int nfb;                          //High decode limit (kHz)
  int ntol;                         //+/- decoding range around fQSO (Hz)
  int map65RxLog;                   //Flags to control log files
  int nfsample;                     //Input sample rate
  int ntrperiod;
  int nsave;                        //Number of s3(64,63) spectra saved
  int kin;
  int kline;
  char datetime[20];
} jt8com_;

}

#endif // COMMONS_H
