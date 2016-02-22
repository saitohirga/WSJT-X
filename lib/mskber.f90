program mskber

! Generate an MSK waveform, pass it through an AWGN channel, apply coherent 
! MSK receiver, and count number of errors at each Eb/No.

  parameter (NSYM=100000)                 !Number of symbols to test
  parameter (NSPS=6)                      !Samples per symbol
  real ct(-NSPS:NSPS*NSYM-1)              !cos(pi*t/2T)
  real st(-NSPS:NSPS*NSYM-1)              !sin(pi*t/2T)
  real r(NSYM)                            !Random numbers to determine test bits
  real xsym(0:NSYM-1)                     !Soft Rx symbols

  complex xt(0:NSPS*(NSYM+1)-1)           !Complex baseband Tx waveform
  complex nt(0:NSPS*(NSYM+1)-1)           !Generated AWGN channel noise
  complex yt(0:NSPS*(NSYM+1)-1)           !Received signal, yt = xt + fac*nt

  integer sym0(0:NSYM-1)                  !Generated test bits
  integer sym(0:NSYM-1)                   !Hard-copy received bits

  pi=4.0*atan(1.0)
  iz=NSPS*(NSYM+1)

  do i=-NSPS,NSPS*NSYM-1                  !Define ct, st arrays
     t=i*pi/(2.0*NSPS)
     ct(i)=cos(t)
     st(i)=sin(t)
  enddo
  fac=1.0/sqrt(float(NSPS))

  do iEbNo=0,10                            !Loop over a range of Eb/No
     sym0=0
     call random_number(r)
     where(r.gt.0.5) sym0=1                !Generate random data bits
     call mskmod(sym0,NSYM,NSPS,ct,st,xt)  !Generate Tx waveform at baseband
! NB: In WSJT-X, will mix xt upward from 0 to 1500 Hz.

     do i=0,iz-1                           !Generate Gaussian noise
        xx=0.707*gran()
        yy=0.707*gran()
        nt(i)=cmplx(xx,yy)
     enddo
     fac_noise=10.0**(-iEbNo/20.0)
     yt=xt + fac_noise*nt                  !Rx signal, with noise

     call mskdemod(yt,NSYM,NSPS,ct,st,xsym) !MSK demodulator

     sym=0
     where(xsym.gt.0.0) sym=1

! Count the hard errors
     nerr=count(sym(0:NSYM-1).ne.sym0(0:NSYM-1))
     thber=0.5*erfc(10.0**(iEbNo/20.0))
     write(*,1000) iEbNo,thber,float(nerr)/NSYM
1000 format(i3,2f10.6)
  enddo

end program mskber

subroutine mskmod(sym,nsym,nsps,ct,st,xt)

! Generate MSK Tx waveform at baseband.

  integer sym(0:nsym-1)                   !Hard-copy received bits
  complex xt(0:nsps*(nsym+1)-1)           !Complex baseband Tx waveform
  real ct(-nsps:nsps*nsym-1)              !cos(pi*t/2T)
  real st(-nsps:nsps*nsym-1)              !sin(pi*t/2T)
  real ai(0:nsps*(nsym+1)-1)              !Rectangular pulses for even symbols
  real aq(0:nsps*(nsym+1)-1)              !Rectangular pulses for odd symbols

  fac=1.0/sqrt(float(nsps))
  do j=0,nsym-1,2
     ia=j*nsps
     ib=ia+2*nsps-1
     ai(ia:ib)=2*sym(j)-1                !Even bits as rectangular pulses
     aq(ia+nsps:ib+nsps)=2*sym(j+1)-1    !Odd bits as rectangular pulses
  enddo
  ai(ib+1:)=0                            !Pad ai with zeros at end
  aq(0:nsps-1)=0                         !Pad aq with zeros at start
  xt=fac*cmplx(ai*ct,aq*st)              !Baseband Tx waveform

  return
end subroutine mskmod

subroutine mskdemod(yt,nsym,nsps,ct,st,xsym) 

! MSK demodulator
! Rx phase must be known and stable; symbol sync must be established.

  complex yt(0:nsps*(nsym+1)-1)           !Received signal
  real ct(-nsps:nsps*nsym-1)              !cos(pi*t/2T)
  real st(-nsps:nsps*nsym-1)              !sin(pi*t/2T)
  real xe(0:nsps*(nsym+3)-1)              !Temp array for received even symbols
  real xo(0:nsps*(nsym+3)-1)              !Temp array for received odd symbols
  real xsym(0:nsym-1)                     !Soft Rx symbols

  iz=nsps*(nsym+1)
  xe(0:iz-1)=real(yt)*ct
  xo(0:iz-1)=aimag(yt)*st
  do j=0,nsym-1,2
     ia=j*nsps
     ib=ia+2*nsps-1
     xsym(j)=sum(xe(ia:ib))             !Integrate over 2 successive symbols
     xsym(j+1)=sum(xo(ia+6:ib+6))
  enddo

  return
end subroutine mskdemod
