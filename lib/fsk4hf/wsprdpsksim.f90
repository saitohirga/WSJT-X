program wsprdpsksim

! Generate simulated data for a 2-minute "WSPR-DPSK" mode.  Output is saved 
! to a *.c2 or *.wav file.

  use wavhdr
  include 'wsprdpsk_params.f90'            !Set various constants
  parameter (NMAX=120*12000)
  type(hdr) hwav                          !Header for .wav file
  character arg*12,fname*16
  character msg*22,msgsent*22
  complex c0(0:NMAX/NDOWN-1)
  complex c(0:NMAX/NDOWN-1)
  complex c0wav(0:NMAX-1)
  complex cwav(0:NMAX-1)
  real*8 fMHz
  integer imessage(NN)
  integer*2 iwave(NMAX)                  !Generated full-length waveform  

! Get command-line argument(s)
  nargs=iargc()
  if(nargs.ne.8) then
     print*,'Usage:   wsprdpsksim "message"       f0  DT fsp del  nwav nfiles snr'
     print*,'Example: wsprdpsksim "K1ABC FN42 30" 50 0.0 0.1 1.0  1      10   -33'
     go to 999
  endif
  call getarg(1,msg)                     !Message to be transmitted
  call getarg(2,arg)
  read(arg,*) f0                         !Freq relative to WSPR-band center (Hz)
  call getarg(3,arg)
  read(arg,*) xdt                        !Time offset from nominal (s)
  call getarg(4,arg)
  read(arg,*) fspread                    !Watterson frequency spread (Hz)
  call getarg(5,arg)
  read(arg,*) delay                      !Watterson delay (ms)
  call getarg(6,arg)
  read(arg,*) nwav                       !1 for *.wav file, 0 for *.c2 file
  call getarg(7,arg)
  read(arg,*) nfiles                     !Number of files
  call getarg(8,arg)
  read(arg,*) snrdb                      !SNR_2500

  twopi=8.0*atan(1.0)
  pi=twopi/2.0
  fs=12000.0/NDOWN
  dt=1.0/fs                              !Sample interval (s)
  tt=NSPS*dt                             !Duration of "itone" symbols (s)
  baud=1.0/tt                            !Keying rate for "itone" symbols (baud)
  txt=NZ*dt                              !Transmission length (s)
  bandwidth_ratio=2500.0/(fs/2.0)
  sig=sqrt(bandwidth_ratio) * 10.0**(0.05*snrdb)
  if(snrdb.gt.90.0) sig=1.0
  txt=NN*NSPS0/12000.0

  call genwsprdpsk(msg,msgsent,imessage)       !Encode the message, get itone
  imessage=2*imessage-1
  write(*,1000) f0,xdt,txt,snrdb,fspread,delay,nfiles,msgsent
1000 format('f0:',f9.3,'   DT:',f6.2,'   txt:',f6.1,'   SNR:',f6.1,    &
          '   fspread:',f6.1,'   delay:',f6.1,'  nfiles:',i3,2x,a22)

 
  beta=1.0   ! excess bandwidth
  if(nwav.eq.0) then
     df=fs/(NMAX/NDOWN)                      !
     c=0
     bw=(1+beta)*baud/2.0
     bf=(1-beta)*baud/2.0
     iw=bw/df
     if=bf/df
     c(0:if-1)=1.0
     if(iw.gt.if) then
       do i=if,iw
         c(i)=((1.0+cos(pi*(i-if)/(iw-if)))/2.0)**0.5
       enddo
     endif
     c(NMAX/NDOWN-1:NMAX/NDOWN-iw:-1)=c(1:iw)

     istart=xdt/dt
     c0=0.0
     do i=1,NN
       c0(istart+(i-1)*200)=imessage(i)
     enddo
     call four2a(c0,NMAX/NDOWN,1,1,1)
     c0=c0*conjg(c)
     ic=f0/df
     c0=cshift(c0,ic)
     call four2a(c0,NMAX/NDOWN,1,-1,1)
     xx=sum(abs(c0(istart:istart+NN*200-1)**2))/(NN*200)
     c0=c0/sqrt(xx)

     call sgran()
     do ifile=1,nfiles
       c=c0
       if( fspread .ne. 0.0 .or. delay .ne. 0.0 ) then
          call watterson(c,NMAX/NDOWN,fs,delay,fspread)
       endif
       c=c*sig
       if(snrdb.lt.90) then
          do i=0,NMAX/NDOWN-1                   !Add gaussian noise at specified SNR
             xnoise=gran()
             ynoise=gran()
             c(i)=c(i) + cmplx(xnoise,ynoise)
          enddo
       endif
snrtest=sum(abs(c(istart:istart+NN*200-1)**2))/(NN*200)/2.0-1.0
write(*,*) 'sample SNR: ',10*log10(snrtest)+10*log10(0.4/2.5)
       write(fname,1100) ifile
1100   format('000000_',i4.4,'.c2')
       open(10,file=fname,status='unknown',access='stream')
       fMHz=10.1387d0
       nmin=2
       write(10) fname,nmin,fMHz,c      !Save to *.c2 file
       close(10)
     enddo
  else
     fs=12000.0
     df=fs/NMAX  
     dt=1/fs
     bandwidth_ratio=2500.0/(fs/2.0)
     sig=sqrt(2*bandwidth_ratio) * 10.0**(0.05*snrdb)
     if(snrdb.gt.90.0) sig=1.0
     cwav=0
     bw=(1+beta)*baud/2.0
     bf=(1-beta)*baud/2.0
     iw=bw/df
     if=bf/df
     cwav(0:if-1)=1.0
     if(iw.gt.if) then
       do i=if,iw
         cwav(i)=((1.0+cos(pi*(i-if)/(iw-if)))/2.0)**0.5
       enddo
     endif
     cwav(NMAX-1:NMAX-iw:-1)=cwav(1:iw)

     istart=xdt/dt
     c0wav=0.0
     do i=1,NN
       c0wav(istart+(i-1)*200*NDOWN)=imessage(i)
     enddo
     call four2a(c0wav,NMAX,1,1,1)
     c0wav=c0wav*conjg(cwav)
     ic=f0/df
     c0wav=cshift(c0wav,-ic)
     call four2a(c0wav,NMAX,1,-1,1)
     xx=sum(abs(c0wav(istart:istart+NN*200*NDOWN-1))**2)/(NN*200*NDOWN)
     c0wav=c0wav/sqrt(xx)
write(*,*) 'Peak power: ',maxval(abs(c0wav)**2)
write(*,*) 'Average power: ',sum(abs(c0wav(istart:istart+NN*200*NDOWN-1))**2)/(NN*200*NDOWN)
     call sgran()
     do ifile=1,nfiles
       cwav=c0wav
       if( fspread .ne. 0.0 .or. delay .ne. 0.0 ) then
          call watterson(cwav,NMAX,fs,delay,fspread)
       endif
       cwav=cwav*sig
       if(snrdb.lt.90) then
          do i=1,NMAX                   !Add gaussian noise at specified SNR
             xnoise=gran()
             iwave(i)=100*(real(cwav(i-1)) + xnoise)
          enddo
       endif
snrtest=sum(real(iwave(istart:istart+NN*200*NDOWN-1)**2)/(NN*200*NDOWN))/100.0**2-1
write(*,*) 'sample SNR: ',10*log10(snrtest)+10*log10(6.0/2.5)
       hwav=default_header(12000,NMAX)
       write(fname,1102) ifile
1102   format('000000_',i4.4,'.wav')
       open(10,file=fname,status='unknown',access='stream')
       write(10) hwav,iwave                !Save to *.wav file
       close(10)
     enddo
  endif
  write(*,1110) ifile,xdt,f0,snrdb,fname
1110 format(i4,f7.2,f8.2,f7.1,2x,a16)
       
999 end program wsprdpsksim
