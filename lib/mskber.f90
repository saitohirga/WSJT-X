program mskber

! Generate an MSK waveform, pass it through an AWGN channel, apply coherent 
! MSK receiver, and count number of errors at each Eb/No.

  parameter (MAXSYM=1000*1000)
  parameter (NSPS=5)                        !Samples per symbol
  real ct(-NSPS:NSPS*MAXSYM-1)              !cos(pi*t/2T)
  real st(-NSPS:NSPS*MAXSYM-1)              !sin(pi*t/2T)
  real r(0:MAXSYM-1)                        !Random numbers to set test bits
  real xsym(0:MAXSYM-1)                     !Soft Rx symbols

  complex xt(-NSPS:NSPS*MAXSYM-1)           !Complex baseband Tx waveform
  complex nt(-NSPS:NSPS*MAXSYM-1)           !Generated AWGN channel noise
  complex yt(-NSPS:NSPS*MAXSYM-1)           !Received signal, yt = xt + fac*nt
  complex cwave(-NSPS:NSPS*MAXSYM-1)        !Audio waveform, Tx real part
  complex z

  integer sym0(0:MAXSYM-1)                  !Generated test bits
  integer sym(0:MAXSYM-1)                   !Hard-copy received bits
  integer sym1(0:7)

  character*12 arg
  data sym1/1,1,0,0,0,1,1,1/

  nargs=iargc()
  if(nargs.ne.2) then
     print*,'Usage:  mskber nsym EbNo'
     go to 999
  endif
  call getarg(1,arg)
  read(arg,*) nsym
  call getarg(2,arg)
  read(arg,*) EbNo

  pi=4.0*atan(1.0)

  do i=-NSPS,NSPS*nsym-1                  !Define ct, st arrays
     t=i*pi/(2.0*NSPS)
     ct(i)=cos(t)
     st(i)=sin(t)
  enddo
  fac=1.0/sqrt(float(NSPS))

  do iEbNo=0,10                                  !Loop over a range of Eb/No
     sym0=0
     call random_number(r)
     where(r(0:nsym-1).gt.0.5) sym0(0:nsym-1)=1  !Generate random data bits
     if(nsym.eq.8) sym0(0:nsym-1)=sym1
     call mskmod(sym0,nsym,NSPS,ct,st,xt,cwave)  !Generate Tx waveform

     do i=-NSPS,NSPS*nsym-1                      !Generate Gaussian noise
        xx=0.707*gran()
        yy=0.707*gran()
        nt(i)=cmplx(xx,yy)
     enddo
     fac_noise=10.0**(-iEbNo/20.0)
     if(EbNo.ne.0.0) fac_noise=10.0**(-EbNo/20.0)
     yt=xt + fac_noise*nt                        !Rx signal, with noise

     call mskdemod(yt,nsym,NSPS,ct,st,xsym)      !MSK demodulator

     sym=0
     where(xsym.gt.0.0) sym=1

     if(nsym.le.160 .and. EbNo.ne.0.0) then
        write(*,1012) sym0(0:nsym-1)
        if(nsym.gt.50) write(*,1012) 
        write(*,1012) sym(0:nsym-1)
1012    format(50i1)
        do i=-nsps,nsps*nsym-1
           phi=i*2.0*pi*1500/12000.0
           z=cwave(i)*cmplx(cos(phi),sin(phi))    !Mix back to baseband
           write(51,1014) float(i)/nsps,xt(i),abs(xt(i)),cwave(i),z
1014       format(8f8.4)
        enddo
     endif

! Count the hard errors
     nerr=count(sym(0:nsym-1).ne.sym0(0:nsym-1))
     thber=0.5*erfc(10.0**(iEbNo/20.0))
     xEbNo=iEbNo
     if(EbNo.ne.0.0) xEbNo=EbNo
     write(*,1000) xEbNo,thber,float(nerr)/nsym
1000 format(f6.1,2f10.6)
     if(EbNo.ne.0.0) exit
  enddo

999 end program mskber

subroutine mskmod(sym,nsym,nsps,ct,st,xt,cwave)

! Generate MSK Tx waveform at baseband.

  integer sym(0:nsym-1)                   !Hard-copy received bits
  complex xt(-nsps:nsps*nsym-1)           !Complex baseband Tx waveform
  complex cwave(-nsps:nsps*nsym-1)        !Audio waveform, fc=1500 Hz.
  real ct(-nsps:nsps*nsym-1)              !cos(pi*t/2T)
  real st(-nsps:nsps*nsym-1)              !sin(pi*t/2T)
  real ai(-nsps:nsps*nsym-1)              !Rectangular pulses for even symbols
  real aq(-nsps:nsps*nsym-1)              !Rectangular pulses for odd symbols

  ai=0.
  aq=0.
  fac=1.0/sqrt(float(nsps))
  do j=0,nsym-1,2
     ia=(j-1)*nsps
     ib=ia+2*nsps-1
     ai(ia:ib)=2*sym(j)-1                !Even bits as rectangular pulses
     aq(ia+nsps:ib+nsps)=2*sym(j+1)-1    !Odd bits as rectangular pulses
  enddo
  xt=fac*cmplx(ai*ct,aq*st)                  !Baseband Tx waveform

  twopi=8.0*atan(1.0)
  do i=-nsps,nsps*nsym-1
     phi=i*twopi*1500/12000.0
     cwave(i)=xt(i)*cmplx(cos(phi),-sin(phi))
  enddo

  return
end subroutine mskmod

subroutine mskdemod(yt,nsym,nsps,ct,st,xsym) 

! MSK demodulator
! Rx phase must be known and stable; symbol sync must be established.

  complex yt(-nsps:nsps*nsym-1)           !Received signal
  real ct(-nsps:nsps*nsym-1)              !cos(pi*t/2T)
  real st(-nsps:nsps*nsym-1)              !sin(pi*t/2T)
  real xe(-nsps:nsps*nsym-1)              !Temp array for received even symbols
  real xo(-nsps:nsps*nsym-1)              !Temp array for received odd symbols
  real xsym(0:nsym-1)                     !Soft Rx symbols

  iz=nsps*(nsym+1)
  xe(-nsps:nsps*nsym-1)=real(yt)*ct       !Apply matched filters
  xo(-nsps:nsps*nsym-1)=aimag(yt)*st
  do j=0,nsym-1,2
     ia=(j-1)*nsps
     ib=ia+2*nsps-1
     xsym(j)=sum(xe(ia:ib))               !Integrate over 2 symbol lengths
     xsym(j+1)=sum(xo(ia+nsps:ib+nsps))
  enddo

  return
end subroutine mskdemod
