program wspr5d

! Simulate characteristics of a potential "WSPR-LF" mode using LDPC (300,60)
! code, OQPSK modulation, and 5 minute T/R sequences.

! Reception and Demodulation algorithm:
!   1. Compute coarse spectrum; find fc1 = approx carrier freq
!   2. Mix from fc1 to 0; LPF at +/- 0.75*R
!   3. Square, FFT; find peaks near -R/2 and +R/2 to get fc2
!   4. Mix from fc2 to 0
!   5. Fit cb13 (central part of csync) to c -> lag, phase
!   6. Fit complex ploynomial for channel equalization
!   7. Get soft bits from equalized data

  include 'wsprlf_params.f90'

! Q: Would it be better for central Sync array to use both I and Q channels?
  
  character arg*8,message*22,cbits*50
  complex csync(0:NZ-1)                 !Sync symbols only, from cbb
  complex c(0:NZ-1)                     !Complex waveform
  complex c1(0:NZ-1)                    !Complex waveform
  complex zz(NS+ND)                     !Complex symbol values (intermediate)
  complex z
  real rxdata(ND),llr(ND)               !Soft symbols
  real pp(2*NSPS)                       !Shaped pulse for OQPSK
  real a(5)                             !For twkfreq1
  real aa(20),bb(20)                    !Fitted polyco's
  integer id(NS+ND)                     !NRZ values (+/-1) for Sync and Data
  integer ierror(NS+ND)
  integer isync(48)                     !Long sync vector
  integer ib13(13)                      !Barker 13 code
  integer*8 n8
  integer*1 idat(7)
  integer*1 decoded(KK),apmask(ND),cw(ND)
  data ib13/1,1,1,1,1,-1,-1,1,1,-1,1,-1,1/
  
  nargs=iargc()
  if(nargs.ne.1) then
     print*,'Usage:   wspr5d maxn'
!     print*,'Example: wsprlfsim 0 0 0 5 10 -20'
     go to 999
  endif
  call getarg(1,arg)
  read(arg,*) maxn

  twopi=8.0*atan(1.0)
  fs=NSPS*12000.0/NSPS0                  !Sample rate
  dt=1.0/fs                              !Sample interval (s)
  tt=NSPS*dt                             !Duration of "itone" symbols (s)
  ts=2*NSPS*dt                           !Duration of OQPSK symbols (s)
  baud=1.0/tt                            !Keying rate for "itone" symbols (baud)
  txt=NZ*dt                              !Transmission length (s)

  do i=1,N2                              !Half-sine pulse shape
     pp(i)=sin(0.5*(i-1)*twopi/(2*NSPS))
  enddo
  n8=z'cbf089223a51'
  do i=1,48
     isync(i)=-1
     if(iand(n8,1).eq.1) isync(i)=1
     n8=n8/2
  enddo

! Defind array id() for sync symbols
  id=0
  do j=1,48                             !First group of 48
     id(2*j-1)=2*isync(j)
  enddo
  do j=1,13                             !Barker 13 code
     id(j+96)=2*ib13(j)
  enddo
  do j=1,48                             !Second group of 48
     id(2*j+109)=2*isync(j)
  enddo

  do ifile=1,9999
     read(10,end=999) c
!     do i=0,NZ-1
!        write(40,4001) i,c(i)
!4001    format(i8,2f10.6)
!     enddo
     call getfc1w(c,fs,fc1)               !First approx for freq
     call getfc2w(c,csync,fs,fc1,fc2,fc3) !Refined freq

!NB: Measured performance is about equally good using fc2 or fc3 here:
     a(1)=-(fc1+fc2)
     a(2:5)=0.
     call twkfreq1(c,NZ,fs,a,c)       !Mix c down by fc1+fc2

!---------------------------------------------------------------- DT
! Not presently used:
     amax=0.
     jpk=0
     iaa=0
     ibb=NZ-1
     do j=-20*NSPS,20*NSPS,NSPS/8
        ia=j
        ib=NZ-1+j
        if(ia.lt.0) then
           ia=0
           iaa=-j
        else
           iaa=0
        endif
        if(ib.gt.NZ-1) then
           ib=NZ-1
           ibb=NZ-1-j
        endif
        z=sum(c(ia:ib)*conjg(csync(iaa:ibb)))
        if(abs(z).gt.amax) then
           amax=abs(z)
           jpk=j
        endif
     enddo
     xdt=jpk/fs
!-----------------------------------------------------------------        

     nterms=maxn
     c1=c
!     do itry=1,1000
     do itry=1,20
        idf=itry/2
        if(mod(itry,2).eq.0) idf=-idf
        nhard0=0
        nhardsync0=0
        ifer=1
        a(1)=idf*0.00085
        a(2:5)=0.
        call twkfreq1(c1,NZ,fs,a,c)       !Mix c1 into c
        call cpolyfitw(c,pp,id,maxn,aa,bb,zz,nhs)
        call msksoftsymw(zz,aa,bb,id,nterms,ierror,rxdata,nhard0,nhardsync0)
        if(nhardsync0.gt.35) cycle
        rxav=sum(rxdata)/ND
        rx2av=sum(rxdata*rxdata)/ND
        rxsig=sqrt(rx2av-rxav*rxav)
        rxdata=rxdata/rxsig
        ss=0.84
        llr=2.0*rxdata/(ss*ss)
        apmask=0
        max_iterations=40
        ifer=0
        call bpdecode300(llr,apmask,max_iterations,decoded,niterations,cw)
        nbadcrc=0
        if(niterations.ge.0) call chkcrc10(decoded,nbadcrc)
        if(niterations.lt.0 .or. nbadcrc.ne.0) ifer=1
        if(ifer.eq.0) exit
     enddo                                !Freq dither loop
     message='                      '
     if(ifer.eq.0) then
        write(cbits,1100) decoded(1:50)
1100    format(50i1)
        read(cbits,1102) idat
1102    format(6b8,b2)
        idat(7)=ishft(idat(7),6)
        call wqdecode(idat,message,itype)
     endif
     write(*,1110) nsnr,xdt,fc1+fc2,message
1110 format(i4,f7.2,f7.2,2x,a22)
  enddo

999 end program wspr5d
