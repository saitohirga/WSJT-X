program wspr5d

! Decode WSPR-LF data read from *.c5 or *.wav files.

! WSPR-LF is a potential WSPR-like mode intended for use at LF and MF.
! It uses an LDPC (300,60) code, OQPSK modulation, and 5 minute T/R sequences.
!
! Still to do: find and decode more than one signal in the specified passband.

  include 'wsprlf_params.f90'
  parameter (NMAX=300*12000)
  character arg*8,message*22,cbits*50,infile*80,fname*16,datetime*11
  character*120 data_dir
  complex csync(0:NZ-1)                 !Sync symbols only, from cbb
  complex c(0:NZ-1)                     !Complex waveform
  complex cd(0:412*16-1)                    !Complex waveform
  complex ca(0:412*16-1)                    !Complex waveform
  real*8 fMHz
  real rxdata(ND),llr(ND)               !Soft symbols
  real pp(32)                       !Shaped pulse for OQPSK
  real ps(0:7),sbits(412)
  integer id(NS+ND)                     !NRZ values (+/-1) for Sync and Data
  integer isync(48)                     !Long sync vector
  integer ib13(13)                      !Barker 13 code
  integer ihdr(11)
  integer*8 n8
  integer*2 iwave(NMAX)                 !Generated full-length waveform  
  integer*1 idat(7)
  integer*1 decoded(KK),apmask(ND),cw(ND)
  integer*1 hbits(412),ebits(411),bits(5)
  data ib13/1,1,1,1,1,-1,-1,1,1,-1,1,-1,1/

  nargs=iargc()
  if(nargs.lt.2) then
     print*,'Usage:   wspr5d [-a <data_dir>] [-f fMHz] file1 [file2 ...]'
     go to 999
  endif
  iarg=1
  data_dir="."
  call getarg(iarg,arg)
  if(arg(1:2).eq.'-a') then
     call getarg(iarg+1,data_dir)
     iarg=iarg+2
  endif
  call getarg(iarg,arg)
  if(arg(1:2).eq.'-f') then
     call getarg(iarg+1,arg)
     read(arg,*) fMHz
     iarg=iarg+2
  endif
  
  open(13,file=trim(data_dir)//'/ALL_WSPR.TXT',status='unknown',   &
       position='append')
  maxn=8                                 !Default value
  twopi=8.0*atan(1.0)
  fs=NSPS*12000.0/NSPS0                  !Sample rate
  dt=1.0/fs                              !Sample interval (s)
  tt=NSPS*dt                             !Duration of "itone" symbols (s)
  ts=2*NSPS*dt                           !Duration of OQPSK symbols (s)
  baud=1.0/tt                            !Keying rate for "itone" symbols (baud)
  txt=NZ*dt                              !Transmission length (s)

  do i=1,32                              !Half-sine pulse shape
     pp(i)=sin(0.5*(i-1)*twopi/(32))
  enddo
  n8=z'cbf089223a51'
  do i=1,48
     isync(i)=-1
     if(iand(n8,1).eq.1) isync(i)=1
     n8=n8/2
  enddo

! Define array id() for sync symbols
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

  csync=0.
  do j=1,205
     if(abs(id(j)).eq.2) then
        ia=nint((j-0.5)*N2)
        ib=ia+N2-1
        csync(ia:ib)=pp*id(j)/abs(id(j))
     endif
  enddo

  do ifile=iarg,nargs
    call getarg(ifile,infile)
    open(10,file=infile,status='old',access='stream')
    j1=index(infile,'.c5')
    j2=index(infile,'.wav')
    if(j1.gt.0) then
       read(10,end=999) fname,ntrmin,fMHz,c
       read(fname(8:11),*) nutc
       write(datetime,'(i11)') nutc
    else if(j2.gt.0) then
       read(10,end=999) ihdr,iwave
       read(infile(j2-4:j2-1),*) nutc
       datetime=infile(j2-11:j2-1)
       call wspr5_downsample(iwave,c)
    else
       print*,'Wrong file format?'
       go to 999
    endif

    close(10)
    fa=100.0
    fb=170.0
    call getfc1w(c,fs,fa,fb,fc1,xsnr)         !First approx for freq
    call getfc2w(c,csync,fs,fc1,fc2,fc3)      !Refined freq

!write(*,*) fc1+fc2
    call downsample(c,fc1+fc2,cd)

  do ncoh=1,0,-1
    do is=0,9
      idt=is/2
      if( mod(is,2).eq. 1 ) idt=-is/2 
      xdt=idt/22.222
      k=-1
      ca=cshift(cd,22+idt)
      do i=1,408,4
        k=k+2
        j=(i+1)*16
        call mskseqdet(ca(j),pp,id(k),bits,ps,ncoh)
        r1=max(ps(1),ps(3),ps(5),ps(7))-max(ps(0),ps(2),ps(4),ps(6))
        r2=max(ps(2),ps(3),ps(6),ps(7))-max(ps(0),ps(1),ps(4),ps(5))
        r4=max(ps(4),ps(5),ps(6),ps(7))-max(ps(0),ps(1),ps(2),ps(3))
        hbits(i:i+4)=bits
        sbits(i:i+4)=bits
        sbits(i+1)=r4
        sbits(i+2)=r2
        if( id(k+1) .ne. 0 ) sbits(i+2)=id(k+1)*25
        sbits(i+3)=r1
      enddo

      j=1
      do i=1,205
        if( abs(id(i)) .ne. 2 ) then
          rxdata(j)=sbits(2*i-1)
          j=j+1
        endif
      enddo
      do i=1,204
        rxdata(j)=sbits(2*i)
        j=j+1
      enddo
      rxav=sum(rxdata)/ND
      rx2av=sum(rxdata*rxdata)/ND
      rxsig=sqrt(rx2av-rxav*rxav)
      rxdata=rxdata/rxsig
      sigma=0.84
      llr=2*rxdata/(sigma*sigma)
      apmask=0
      max_iterations=40
      ifer=0
      nbadcrc=0
      call bpdecode300(llr,apmask,max_iterations,decoded,niterations,cw)
      if(niterations.lt.0) call osd300(llr,3,decoded,niterations,cw)
      if(niterations.ge.0) call chkcrc10(decoded,nbadcrc)
      if(niterations.lt.0 .or. nbadcrc.ne.0) ifer=1
      if( ifer.eq.0 ) then
        write(cbits,1200) decoded(1:50)
1200 format(50i1)
        read(cbits,1202) idat
1202 format(6b8,b2)
        idat(7)=ishft(idat(7),6)
        call wqdecode(idat,message,itype)
        nsnr=nint(xsnr)
        freq=fMHz + 1.d-6*(fc1+fc2)
        nfdot=0
        write(13,1210) datetime,0,nsnr,xdt,freq,message,nfdot
1210 format(a11,2i4,f6.2,f12.7,2x,a22,i3)
        write(*,1212) datetime(8:11),nsnr,xdt,freq,nfdot,message,'*'
1212 format(a4,i4,f5.1,f11.6,i3,2x,a22,a1)
        goto 888
      endif
    enddo
enddo
888  enddo

  write(*,1120)
1120 format("<DecodeFinished>")

999 end program wspr5d

subroutine mskseqdet(cdat,pp,bsync,bestbits,cmbest,ncoh)
complex cdat(16*4),cbest(16*4),cideal(16*4)
complex cdf(16*4),cfac
real cm(0:7),cmbest(0:7)
real pp(32)
integer*1 bits(5),bestbits(5),sgn(5)
integer bsync(3)

twopi=8.0*atan(1.0)
dt=30.0*18.0/12000.0
cmax=0;
fbest=0.0;

idfmax=40
if( ncoh .eq. 1 ) idfmax=0
do idf=0,idfmax
  if( mod(idf,2).eq.1 ) deltaf=idf/2*0.02
  if( mod(idf,2).eq.1 ) deltaf=-(idf+1)/2*0.02
  dphi=twopi*deltaf*dt
  cfac=cmplx(cos(dphi),sin(dphi)) 
  cdf=1.0
  do i=2,16*4
    cdf(i)=cdf(i-1)*cfac
  enddo 

  cm=0
  ibflag=0
  do i=0,7
    bits(1)=(bsync(1)+2)/4
    bits(2)=iand(i/4,1)
    bits(3)=iand(i/2,1)
    if( bsync(2).ne.0 ) then ! force the barker bits
      bits(3)=(bsync(2)+2)/4
    endif
    bits(4)=iand(i/1,1)
    bits(5)=(bsync(3)+2)/4
    sgn=2*bits-1
    cideal(1:16)=cmplx(sgn(1)*pp(17:32),sgn(2)*pp(1:16))
    cideal(17:32)=cmplx(sgn(3)*pp(1:16),sgn(2)*pp(17:32))
    cideal(33:48)=cmplx(sgn(3)*pp(17:32),sgn(4)*pp(1:16))
    cideal(49:64)=cmplx(sgn(5)*pp(1:16),sgn(4)*pp(17:32))
    cideal=cideal*cdf
    cm(i)=abs(sum(cdat*conjg(cideal)))/1.e3
    if( cm(i) .gt. cmax ) then
      ibflag=1
      cmax=cm(i)
      bestbits=bits
      cbest=cideal
      fbest=deltaf
    endif
  enddo
  if( ibflag .eq. 1 ) then ! new best found
    cmbest=cm
  endif
enddo
end subroutine mskseqdet

subroutine downsample(ci,f0,co)
  parameter(NI=412*288,NO=NI/18)
  complex ci(0:NI-1),ct(0:NI-1) 
  complex co(0:NO-1)

  df=400.0/NI
  ct=ci
  call four2a(ct,NI,1,-1,1)             !r2c FFT to freq domain
  i0=nint(f0/df)
  co=0.0
  co(0)=ct(i0)
  b=4.0
  do i=1,NO/2
     arg=(i*df/b)**2
     filt=exp(-arg)
     co(i)=ct(i0+i)*filt
     co(NO-i)=ct(i0-i)*filt
  enddo
  co=co/NO
  call four2a(co,NO,1,1,1)            !c2c FFT back to time domain
  return
end subroutine downsample
