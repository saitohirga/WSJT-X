program wsprdpskd

! Decode WSPRDPSK data read from *.c2 or *.wav files.

! Currently configured to use (204,68) r=1/3 LDPC code, regular column weight 3.
!   50 data bits + 14 bit CRC + 4 "0" bits. The 4 "0" bits are unused bits that 
!   are not transmitted. At the decoder, these bits are treated as "AP" bits. 
!   This shortens the code to (200,64) r=0.32, slightly decreasing the code rate.
! Frame format is:
! d100 p32 d100 (232)  channel symbols
!
  use crc
  include 'wsprdpsk_params.f90'
  parameter(NMAX=120*12000)
  character arg*8,message*22,cbits*50,infile*80,fname*16,datetime*11
  character*22 decodes(100)
  character*120 data_dir
  character*32 uwbits
  character*68 dmsg
  complex c2(0:120*12000/30-1)              !Complex waveform
  complex cframe(0:232*200-1)               !Complex waveform
  complex cd(0:240*10-1)                   !Complex waveform
  complex cs(0:240)
  complex c1(0:9,0:1),c0(0:9,0:1)
  complex ccor(0:1,232)
  complex csum,cterm  
  real*8 fMHz
  real rxdata(ND),llr(204)               !Soft symbols
  real sbits(232),sbits1(232),sbits3(232)
  real ps(0:8191),psbest(0:8191)
  real candidates(100,2)
  integer iuniqueword0
  integer isync(200)                     !Unique word
  integer isync2(232)
  integer ipreamble(16)                 !Preamble vector
  integer ihdr(11)
  integer*2 iwave(NMAX)                 !Generated full-length waveform  
  integer*1,target ::  idat(9)
  integer*1 decoded(68),apmask(204),cw(204)
  integer*1 hbits(232),hbits1(232),hbits3(232)
  integer*1 b(14),bbest(14)
  data ipreamble/1,1,1,1,0,0,0,0,0,0,0,0,1,1,1,1/
  data iuniqueword0/z'30C9E8AD'/

  write(uwbits,'(b32.32)') iuniqueword0
  read(uwbits,'(32i1)') isync(1:32)
  read(uwbits,'(32i1)') isync(33:64)
  read(uwbits,'(32i1)') isync(65:96)
  read(uwbits,'(32i1)') isync(97:128)
  read(uwbits,'(32i1)') isync(129:160)
  read(uwbits,'(32i1)') isync(161:192)
  read(uwbits,'(8i1)') isync(193:200)
  
  fs=12000.0/NDOWN                       !Sample rate
  dt=1.0/fs                              !Sample interval (s)
  tt=NSPS*dt                             !Duration of "itone" symbols (s)
  baud=1.0/tt                            !Keying rate for "itone" symbols (baud)
  txt=NZ*dt                              !Transmission length (s)
  h=1.00                                !h=0.8 seems to be optimum for AWGN sensitivity (not for fading)
  twopi=8.0*atan(1.0)

  isync2(1:100)=isync(1:100)
  isync2(101:104)=0  ! This is *not* backwards.
  isync2(105:112)=1
  isync2(113:116)=0
  isync2(117:216)=isync(101:200)

  dphi=twopi*baud*(h/2.0)*dt*20  ! dt*20 is samp interval after downsample
  do j=0,1
    if(j.eq.0) then
       dphi0=-3*dphi
       dphi1=+1*dphi
    else
       dphi0=-1*dphi
       dphi1=+3*dphi
    endif
    phi0=0.0
    phi1=0.0
    do i=0,9
      c1(i,j)=cmplx(cos(phi1),sin(phi1))
      c0(i,j)=cmplx(cos(phi0),sin(phi0))
      phi1=mod(phi1+dphi1,twopi)
      phi0=mod(phi0+dphi0,twopi)
    enddo
  enddo

  nargs=iargc()
  if(nargs.lt.1) then
     print*,'Usage:   wsprdpskd [-a <data_dir>] [-f fMHz] [-c ncoh] file1 [file2 ...]'
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
  ncoh=1
  npdi=16
  if(arg(1:2).eq.'-c') then
     call getarg(iarg+1,arg)
     read(arg,*) ncoh
     iarg=iarg+2
     npdi=16/ncoh
  endif
!  write(*,*) 'ncoh: ',ncoh,' npdi: ',npdi
  
  open(13,file=trim(data_dir)//'/ALL_WSPR.TXT',status='unknown',   &
       position='append')

  xs1=0.0
  xs2=0.0
  fr1=0.0
  fr2=0.0
  nav=0
  ngood=0

  do ifile=iarg,nargs
    call getarg(ifile,infile)
    open(10,file=infile,status='old',access='stream')
    j1=index(infile,'.c2')
    j2=index(infile,'.wav')
    if(j1.gt.0) then
       read(10,end=999) fname,ntrmin,fMHz,c2
       read(fname(8:11),*) nutc
       write(datetime,'(i11)') nutc
    else if(j2.gt.0) then
       read(10,end=999) ihdr,iwave
       read(infile(j2-4:j2-1),*) nutc
       datetime=infile(j2-11:j2-1)
       call wsprdpsk_downsample(iwave,c2)
    else
       print*,'Wrong file format?'
       go to 999
    endif
    close(10)

    fa=-10.0
    fb=10.0
    fs=12000.0/30.0
    npts=120*12000.0/30.0
!    call getcandidate2(c2,npts,fs,fa,fb,ncand,candidates)         !First approx for freq
    ncand=1
    candidates(1,1)=0.0
    candidates(1,2)=-28
    ndecodes=0
    do icand=1,ncand
      fc0=candidates(icand,1)
      xsnr=candidates(icand,2)
      call dsdpsk(c2,fc0,cd)
      i0=40
      do i=0,231
        cs(i)=cd(i0+10*i)/5e4 
      enddo 
! 2-bit differential detection
      do i=1,231
        sbits(i)=-real(cs(i)*conjg(cs(i-1)))
      enddo

! detect a differentially encoded block of symbols using the 
! Divsalar and Simon approach, except that we estimate only
! the central symbol of the block and then step the block forward
! by one symbol.
!
      sbits3=sbits
goto 100
      nbit=13  ! number of decoded bits to be derived from nbit+1 symbols
      numseq=2**nbit
      il=(nbit+1)/2
      ih=231-nbit/2
      do isym=il,ih
        rmax=-1e32
        b=0
        do iseq=0,numseq-1
          do i=1,nbit
            b(i)=merge(1,0,iand(iseq,2**(nbit-i))>0)
          enddo
          b(1:nbit)=2*b(1:nbit)-1
          i1=isym-(nbit+1)/2
          csum=cs(i1)
          do i=1,nbit
            bb=1
            do m=1,i
              bb=bb*b(m)
            enddo
            csum=csum+bb*cs(i1+i)
          enddo
          ps(iseq)=abs(csum)**2
          if(ps(iseq).gt.rmax) then
            bbest=b
            rmax=ps(iseq)
          endif
        enddo 
        if(isym.eq.il) then
          do i=1,isym-1
            call getmetric(2**(nbit-i),ps,numseq,xmet)
            sbits3(i)=-xmet
          enddo
        endif
        call getmetric(2**((nbit-1)/2),ps,numseq,xmet)
        sbits3(isym)=-xmet
        if(isym.eq.ih) then
          do i=ih+1,231
            call getmetric(2**(231-i),ps,numseq,xmet)
            sbits3(i)=-xmet
          enddo
        endif
      enddo
100 continue
      rxdata(1:100)=sbits3(1:100)
      rxdata(101:200)=sbits3(132:231);
      rxav=sum(rxdata(1:200))/200.0
      rx2av=sum(rxdata(1:200)*rxdata(1:200))/200.0
      rxsig=sqrt(rx2av-rxav*rxav)
      rxdata=rxdata/rxsig
      sigma=0.90
      llr(201:204)=-5.0
      llr(1:200)=2*rxdata/(sigma*sigma)
      apmask=0
      apmask(201:204)=1
      max_iterations=40
      ifer=0
      call bpdecode204(llr,apmask,max_iterations,decoded,cw,nharderror,niterations)
      nhardmin=-1
      if(nharderror.lt.0) call osd204(llr,apmask,5,decoded,cw,nhardmin,dmin)
      if(sum(decoded).eq.0) cycle
      if(nhardmin.ge.0 .or. nharderror.ge.0) then
        idat=0
        write(dmsg,'(68i1)') decoded
        read(dmsg(1:50),'(6b8.8,b2.2)') idat(1:7)
        idat(7)=idat(7)*64
        read(dmsg(51:64),'(b14.14)') ndec_crc
        ncalc_crc=iand(crc14(c_loc(idat),9),z'FFFF')
        nbadcrc=1
        if(ncalc_crc .eq. ndec_crc) nbadcrc=0
      else
        cycle
      endif 
      if( nbadcrc.eq.0 ) then
        write(cbits,1200) decoded(1:50)
1200    format(50i1)
        read(cbits,1202) idat
1202    format(8b8,b4)
        idat(7)=ishft(idat(7),6)
        call wqdecode(idat,message,itype)
        idupe=0
        do i=1,ndecodes
          if(decodes(i).eq.message) idupe=1 
        enddo
        if(idupe.eq.1) goto 888
        ndecodes=ndecodes+1 
        decodes(ndecodes)=message
        nsnr=nint(xsnr)
        freq=fMHz + 1.d-6*(fc1+fbest)
        nfdot=0
        write(13,1210) datetime,0,nsnr,xdt,freq,message,nfdot
1210    format(a11,2i4,f6.2,f12.7,2x,a22,i3)
        write(*,1212) datetime(8:11),nsnr,xdt,freq,nfdot,message,'*',idf,nseq,ijitter,nharderror,nhardmin
1212    format(a4,i4,f5.1,f11.6,i3,2x,a22,a1,i5,i5,i5,i5,i5)
        goto 888
      endif
888 continue
    enddo !candidate list
  enddo !files

  write(*,1120)
1120 format("<DecodeFinished>")

999 end program wsprdpskd

subroutine getmetric(ib,ps,ns,xmet)
  real ps(0:ns-1)
  xm1=-1e32
  xm0=-1e32
  do i=0,ns-1
    if( iand(i/ib,1) .eq. 1 .and. ps(i) .gt. xm1 ) then
      xm1=ps(i) 
    endif
    if( iand(i/ib,1) .eq. 0 .and. ps(i) .gt. xm0 ) then
      xm0=ps(i) 
    endif
  enddo
  xmet=xm1-xm0
  return
end subroutine getmetric

subroutine dsdpsk(ci,f0,co)
  parameter(NI=240*200,NH=NI/2,NO=NI/20)  ! downsample from 200 samples per symbol to 10
  complex ci(0:NI-1),ct(0:NI-1) 
  complex co(0:NO-1)

  pi=4.0*atan(1.0)
  fs=12000.0/30.0
  df=fs/NI
  ct=ci
  call four2a(ct,NI,1,-1,1)             !c2c FFT to freq domain
  i0=nint(f0/df)
  ct=cshift(ct,i0)
  co=0.0
  co(0)=ct(0)

  dt=20/fs
  beta=1.0
  tt=10*dt
  baud=1/tt
  bw=(1+beta)*baud/2.0
  bf=(1-beta)*baud/2.0
  iw=bw/df
  if=bf/df
  co=0.0
  co(0)=ct(0)
  do i=1,iw
     filt=((1.0+cos(pi*(i-if)/(iw-if)))/2.0)**0.5
     co(i)=ct(i)*filt
     co(NO-i)=ct(NI-i)*filt
  enddo
  co=co/NO
  call four2a(co,NO,1,1,1)            !c2c FFT back to time domain
  return
end subroutine dsdpsk

subroutine getcandidate2(c,npts,fs,fa,fb,ncand,candidates)
  parameter(NDAT=200,NFFT1=120*12000/30,NH1=NFFT1/2,NFFT2=120*12000/300,NH2=NFFT2/2)
  complex c(0:npts-1)                   !Complex waveform
  complex cc(0:NFFT1-1)
  complex csfil(0:NFFT2-1)
  complex cwork(0:NFFT2-1)
  real bigspec(0:NFFT2-1)
  complex c2(0:NFFT1-1)                 !Short spectra
  real s(-NH1+1:NH1)                    !Coarse spectrum
  real ss(-NH1+1:NH1)                   !Smoothed coarse spectrum
  real candidates(100,2)
  integer indx(NFFT2-1)
  logical first
  data first/.true./
  save first,w,df,csfil

  if(first) then
    df=10*fs/NFFT1
    csfil=cmplx(0.0,0.0)
    do i=0,NFFT2-1
       csfil(i)=exp(-((i-NH2)/20.0)**2)
    enddo
    csfil=cshift(csfil,NH2)
    call four2a(csfil,NFFT2,1,-1,1)
    first=.false.
  endif

  cc=cmplx(0.0,0.0)
  cc(0:npts-1)=c;
  call four2a(cc,NFFT1,1,-1,1)
  cc=abs(cc)**2
  call four2a(cc,NFFT1,1,-1,1)
  cwork(0:NH2)=cc(0:NH2)*conjg(csfil(0:NH2))
  cwork(NH2+1:NFFT2-1)=cc(NFFT1-NH2+1:NFFT1-1)*conjg(csfil(NH2+1:NFFT2-1))

  call four2a(cwork,NFFT2,1,+1,1)
  bigspec=cshift(real(cwork),-NH2)
  il=NH2+fa/df
  ih=NH2+fb/df 
  nnl=ih-il+1
  call indexx(bigspec(il:il+nnl-1),nnl,indx)
  xn=bigspec(il-1+indx(nint(0.3*nnl)))
  bigspec=bigspec/xn
  ncand=0
  do i=il,ih
    if((bigspec(i).gt.bigspec(i-1)).and. &
       (bigspec(i).gt.bigspec(i+1)).and. &
       (bigspec(i).gt.1.15).and.ncand.lt.100) then 
         ncand=ncand+1
         candidates(ncand,1)=df*(i-NH2)
         candidates(ncand,2)=10*log10(bigspec(i))-30.0
    endif
  enddo
!  do i=1,ncand
!    write(*,*) i,candidates(i,1),candidates(i,2)
!  enddo 
  return
end subroutine getcandidate2

subroutine wsprdpsk_downsample(iwave,c)

! Input: i*2 data in iwave() at sample rate 12000 Hz
! Output: Complex data in c(), sampled at 400 Hz

  include 'wsprdpsk_params.f90'
  parameter (NMAX=120*12000,NFFT2=NMAX/30)
  integer*2 iwave(NMAX)
  complex c(0:NMAX/30-1)
  complex c1(0:NFFT2-1)
  complex cx(0:NMAX/2)
  real x(NMAX)
  equivalence (x,cx)

  df=12000.0/NMAX
  x=iwave
  call four2a(x,NMAX,1,-1,0)             !r2c FFT to freq domain
  i0=nint(1500.0/df)
  c1(0)=cx(i0)
  do i=1,NFFT2/2
     c1(i)=cx(i0+i)
     c1(NFFT2-i)=cx(i0-i)
  enddo
  c1=c1/NFFT2
  call four2a(c1,NFFT2,1,1,1)            !c2c FFT back to time domain
  c=c1(0:NMAX/30-1)
  return
end subroutine wsprdpsk_downsample

