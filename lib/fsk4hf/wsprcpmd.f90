program wsprcpmd

! Decode WSPRCPM data read from *.c2 or *.wav files.

! WSPRCPM is a WSPR-like mode based on full-response CPM. 
!
! Modulation Capabilities include:
!   support for multi-h cpm with two modulation indexes: [h1,h2]. 
!   h1,h2 (modulation index) are variable; h1=h2=0.5 is MSK, h1=h2=1.0 is standard
!     fsk intended for noncoherent demodulation. 
!   demodulator uses noncoherent sequence detection with variable window size.
!     symbol demodulation is done symbol-by-symbol - each symbol is 
!     estimated using a data frame comprising N symbol intervals, where N can 
!     be 1, 3, 5, 7, 9, 11. The central symbol is estimated and then the window
!     is stepped forward by one symbol. 
!   soft symbols are decoded by log-domain belief propagation followed by ordered-
!     statistics decoding. 
!
! Currently configured to use (204,68) r=1/3 LDPC code, regular column weight 3.
!   50 data bits + 14 bit CRC + 4 "0" bits. The 4 "0" bits are unused bits that 
!   are not transmitted. At the decoder, these bits are treated as "AP" bits. 
!   This shortens the code to (200,64) r=0.32, slightly decreasing the code rate.
! 
! Frame format is:
! s32 d200 p32 (264)  channel symbols
!
  use crc
  include 'wsprcpm_params.f90'
  parameter(NMAX=120*12000)
  character arg*8,message*22,cbits*50,infile*80,fname*16,datetime*11
  character*120 data_dir
  character*32 uwbits
  character*68 dmsg
  complex csync(0:32*100-1)                 !Sync symbols only, from cbb
  complex cpreamble(0:32*100-1)             !Sync symbols only, from cbb
  complex cp2(0:32*100-1)
  complex ctwks(0:32*100-1)
  complex ctwkp(0:32*100-1)
  complex c2(0:120*12000/53-1)              !Complex waveform
  complex ctmp(0:4*32*100-1)
  complex cframe(0:264*100-1)               !Complex waveform
  complex cd(0:264*100-1)                   !Complex waveform
  complex c1(0:9,1:2),c0(0:9,1:2)
  complex ccor(0:1,264)
  complex csum,cp(0:1,1:2),cterm
  complex ccohs(0:31)
  complex ccohp(0:31)
  real*8 fMHz
  real rxdata(ND),llr(204)               !Soft symbols
  real sbits(264),sbits1(264),sbits3(264)
  real ps(0:8191),psbest(0:8191)
  integer iuniqueword0
  integer isync(32)                     !Unique word
  integer ipreamble(32)                 !Preamble vector
  integer ihdr(11)
  integer*2 iwave(NMAX)                 !Generated full-length waveform  
  integer*1,target ::  idat(9)
  integer*1 decoded(68),apmask(204),cw(204)
  integer*1 hbits(264),hbits1(264),hbits3(264)
  data ipreamble/1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1/
  data iuniqueword0/z'30C9E8AD'/

  write(uwbits,'(b32.32)') iuniqueword0
  read(uwbits,'(32i1)') isync
  ipreamble=2*ipreamble-1
  isync=2*isync-1

  fs=12000.0/NDOWN                       !Sample rate
  dt=1.0/fs                              !Sample interval (s)
  tt=NSPS*dt                             !Duration of "itone" symbols (s)
  baud=1.0/tt                            !Keying rate for "itone" symbols (baud)
  txt=NZ*dt                              !Transmission length (s)
  h1=0.80                                !h=0.8 seems to be optimum for AWGN sensitivity (not for fading)
  h2=0.80
  twopi=8.0*atan(1.0)
  dphi11=twopi*baud*(h1/2.0)*dt
  dphi01=-twopi*baud*(h1/2.0)*dt
  dphi12=twopi*baud*(h2/2.0)*dt
  dphi02=-twopi*baud*(h2/2.0)*dt
  k=0
  phi=0.0
  do i=1,32
    if( mod(i,2) .eq. 0 ) then
      dphi1=dphi11
      dphi0=dphi01
    else
      dphi1=dphi12
      dphi0=dphi02
    endif
    dphi=dphi0
    if( isync(i) .eq. 1 ) dphi=dphi1
    do j=1,100 
      phi=mod(phi+dphi,twopi)
      csync(k)=cmplx(cos(phi),sin(phi))
      k=k+1
    enddo
  enddo

  k=0
  phi=0.0
  do i=1,32
    if( mod(i,2) .eq. 0 ) then
      dphi1=dphi11
      dphi0=dphi01
    else
      dphi1=dphi12
      dphi0=dphi02
    endif
    dphi=dphi0
    if( ipreamble(i) .eq. 1 ) dphi=dphi1
    do j=1,100 
      phi=mod(phi+dphi,twopi)
      cpreamble(k)=cmplx(cos(phi),sin(phi))
      k=k+1
    enddo
  enddo

  dphi1=twopi*baud*(h1/2.0)*dt*10  ! dt*10 is samp interval after downsample
  dphi2=twopi*baud*(h2/2.0)*dt*10  ! dt*10 is samp interval after downsample
  cp(1,1)=cmplx(cos(dphi1*10),sin(dphi1*10))
  cp(0,1)=conjg(cp(1,1))
  cp(1,2)=cmplx(cos(dphi2*10),sin(dphi2*10))
  cp(0,2)=conjg(cp(1,2))
  do j=1,2
    if( j.eq.1 ) then
      dphi=dphi1
    else
      dphi=dphi2
    endif
    phi0=0.0
    phi1=0.0
    do i=0,9
      c1(i,j)=cmplx(cos(phi1),sin(phi1))
      c0(i,j)=cmplx(cos(phi0),sin(phi0))
      phi1=mod(phi1+dphi,twopi)
      phi0=mod(phi0-dphi,twopi)
    enddo
  enddo

  nargs=iargc()
  if(nargs.lt.1) then
     print*,'Usage:   wsprcpmd [-a <data_dir>] [-f fMHz] [-c ncoh] file1 [file2 ...]'
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
  npdi=32
  if(arg(1:2).eq.'-c') then
     call getarg(iarg+1,arg)
     read(arg,*) ncoh
     iarg=iarg+2
     npdi=32/ncoh
  endif
  write(*,*) 'ncoh: ',ncoh,' npdi: ',npdi
  
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
       call wsprcpm_downsample(iwave,c2)
    else
       print*,'Wrong file format?'
       go to 999
    endif
    close(10)

    fa=-100.0
    fb=100.0
    fs=12000.0/53.0
    npts=120*12000/53
    nsync=32

    call getcandidate2(c2,npts,fs,fa,fb,fc1,xsnr)         !First approx for freq

    fcest=fc1
do iii=1,2
    izero=226
    dphi=twopi*fcest*dt
    ctwks=cmplx(0.0,0.0)
    ctwkp=cmplx(0.0,0.0)
    phi=0
    do i=0,nsync*NSPS-1
      phi=mod(phi+dphi,twopi)
      ctwks(i)=csync(i)*cmplx(cos(phi),sin(phi))
      ctwkp(i)=cpreamble(i)*cmplx(cos(phi),sin(phi))
    enddo
    imax=100
    xcmax=-1e32
    do it = -imax,imax
      its=izero+it
      ccohs=0.0
      do k=0,npdi-1  
        is=k*ncoh*nsps
        ccohs(k)=sum(c2(its+is:its+is+ncoh*nsps-1)*conjg(ctwks(is:is+ncoh*nsps-1)))
        ccohs(k)=ccohs(k)/(ncoh*nsps)
      enddo
!      term1=sum(abs(ccohs(0:npdi-1))**2)

      itp=izero+it+232*100
      ccohp=0.0
      do k=0,npdi-1  
        is=k*ncoh*nsps
        ccohp(k)=sum(c2(itp+is:itp+is+ncoh*nsps-1)*conjg(ctwkp(is:is+ncoh*nsps-1)))
        ccohp(k)=ccohp(k)/(ncoh*nsps)
      enddo

      csum=0.0
      terms=0.0
      do n=1,npdi-1
         do k=n,npdi-1
            csum=csum+ccohs(k)*conjg(ccohs(k-n)) 
         enddo
         terms=terms+abs(csum)
      enddo
      csum=0.0
      termp=0.0
      do n=1,npdi-1
         do k=n,npdi-1
            csum=csum+ccohp(k)*conjg(ccohp(k-n)) 
         enddo
         termp=termp+abs(csum)
      enddo
!write(23,*) it,terms,termp
      xmetric=sqrt(terms*termp)

      if( xmetric .gt. xcmax ) then
        xcmax=xmetric
        ibestt=it
      endif
    enddo

    istart=izero+ibestt
if(iii .eq. 2) goto 887

    ctmp=0.0
    ctmp(0:32*100-1)=c2(istart+232*100:istart+264*100-1)*conjg(ctwkp)
    call four2a(ctmp,4*32*100,1,-1,1)             !c2c FFT to freq domain
    xmax=0.0
    ctmp=cshift(ctmp,-200)
    do i=150,250
      xa=abs(ctmp(i))
      if(xa.gt.xmax) then
        ishift=i
        xmax=xa
      endif
    enddo
    dfp=1/(4*5300.0/12000.0*32)
    delta=(ishift-200)*dfp
! need to add bounds protection
    xm1=abs(ctmp(ishift-1))
    x0=abs(ctmp(ishift))
    xp1=abs(ctmp(ishift+1))
    xint=(log(xm1)-log(xp1))/(log(xm1)+log(xp1)-2*log(x0))
    delta2=delta+xint*dfp/2.0
    fcest=fcest+delta2
enddo

887    write(*,'(i4,i5,5(2x,f9.5))') ifile,istart,xcmax,fc1,fcest
    xdt=(istart-226)/100.0
    if(abs(xdt).le.0.1) ngood=ngood+1
    xs1=xs1+xdt
    xs2=xs2+xdt**2
    fr1=fr1+fc1
    fr2=fr2+fc1**2
    nav=nav+1
!**************
!    fcest=0.0
!    istart=226

do ijitter=0,2
    io=ijitter
    if(ijitter.eq.2) io=-1
    cframe=c2(istart+io:istart+io+264*100-1) 
    call downsample2(cframe,fcest,cd)

    dts=10*dt
    s2=sum(cd*conjg(cd))/(10*264)
    cd=cd/sqrt(s2)

    do nseq=1,7
      if( nseq.eq.1 ) then  ! noncoherent single-symbol detection
        sbits1=0.0
        do ibit=1,264
          if( mod(ibit,2).eq.0 ) j=1
          if( mod(ibit,2).eq.1 ) j=2
          ib=(ibit-1)*10
          ccor(1,ibit)=sum(cd(ib:ib+9)*conjg(c1(0:9,j)))        
          ccor(0,ibit)=sum(cd(ib:ib+9)*conjg(c0(0:9,j)))   
          sbits1(ibit)=abs(ccor(1,ibit))-abs(ccor(0,ibit))
          hbits1(ibit)=0
          if(sbits1(ibit).gt.0) hbits1(ibit)=1
        enddo 
        sbits=sbits1
        hbits=hbits1
        sbits3=sbits1
        hbits3=hbits1
      elseif( nseq.ge.2 ) then
        ps=0
        if( nseq.eq. 2 ) nbit=3
        if( nseq.eq. 3 ) nbit=5
        if( nseq.eq. 4 ) nbit=7
        if( nseq.eq. 5 ) nbit=9
        if( nseq.eq. 6 ) nbit=11
        if( nseq.eq. 7 ) nbit=13
        numseq=2**(nbit)
        do ibit=nbit/2+1,264-nbit/2
          ps=0.0
          pmax=0.0
          do iseq=0,numseq-1
            csum=0.0
            cterm=cmplx(1.0,0.0)
            k=1
            do i=nbit-1,0,-1
              ibb=iand(iseq/(2**i),1) 
              csum=csum+ccor(ibb,ibit-(nbit/2+1)+k)*cterm
              if( mod(ibit-(nbit/2+1)+k,2) .eq. 0 ) j=1
              if( mod(ibit-(nbit/2+1)+k,2) .eq. 1 ) j=2
              cterm=cterm*conjg(cp(ibb,j))
              k=k+1
            enddo
            ps(iseq)=abs(csum) 
            if( ps(iseq) .gt. pmax ) then
              pmax=ps(iseq)
              ibflag=1
            endif
          enddo
          if( ibflag .eq. 1 ) then
            psbest=ps
            ibflag=0
          endif
          call getmetric2(2**(nbit/2),psbest,numseq,sbits3(ibit))
          hbits3(ibit)=0
          if(sbits3(ibit).gt.0) hbits3(ibit)=1
        enddo
        sbits=sbits3
        hbits=hbits3
      endif
      rxdata(1:200)=sbits(33:232)
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
        nsnr=nint(xsnr)
        freq=fMHz + 1.d-6*(fc1+fbest)
        nfdot=0
        write(13,1210) datetime,0,nsnr,xdt,freq,message,nfdot
1210    format(a11,2i4,f6.2,f12.7,2x,a22,i3)
        write(*,1212) datetime(8:11),nsnr,xdt,freq,nfdot,message,'*',idf,nseq,ijitter,nharderror,nhardmin
1212    format(a4,i4,f5.1,f11.6,i3,2x,a22,a1,i5,i5,i5,i5,i5)
        goto 888
      endif
    enddo ! nseq
enddo !jitter
888 continue
  enddo !files

  avshift=xs1/nav
  varshift=xs2/nav
  stdshift=sqrt(varshift-avshift**2)
  avfr=fr1/nav
  varfr=fr2/nav
  stdfr=sqrt(varfr-avfr**2)
  write(*,*) 'ngood: ',ngood
  write(*,'(a7,f7.3,f7.3)') 'shift: ',avshift,stdshift
  write(*,*) 'freq:  ',avfr,stdfr

  write(*,1120)
1120 format("<DecodeFinished>")

999 end program wsprcpmd

subroutine getmetric2(ib,ps,ns,xmet)
  real ps(0:ns-1)
  xm1=0
  xm0=0
  do i=0,ns-1
    if( iand(i/ib,1) .eq. 1 .and. ps(i) .gt. xm1 ) xm1=ps(i)
    if( iand(i/ib,1) .eq. 0 .and. ps(i) .gt. xm0 ) xm0=ps(i)
  enddo
  xmet=xm1-xm0
  return
end subroutine getmetric2

subroutine downsample2(ci,f0,co)
  parameter(NI=264*100,NH=NI/2,NO=NI/10)  ! downsample from 100 samples per symbol to 10
  complex ci(0:NI-1),ct(0:NI-1) 
  complex co(0:NO-1)
  fs=12000.0/53.0
  df=fs/NI
  ct=ci
  call four2a(ct,NI,1,-1,1)             !c2c FFT to freq domain
  i0=nint(f0/df)
  ct=cshift(ct,i0)
  co=0.0
  co(0)=ct(0)
!  b=3.4*0.875/0.715
!  b=2.6*0.5625/0.715
  b=12.0
  do i=1,NO/2
     arg=(i*df/b)**2
     filt=exp(-arg)
!     filt=0.0
!     if( i*df .le. b ) filt=1.0
     co(i)=ct(i)*filt
     co(NO-i)=ct(NI-i)*filt
  enddo
  co=co/NO
  call four2a(co,NO,1,1,1)            !c2c FFT back to time domain
  return
end subroutine downsample2

subroutine getcandidate2(c,npts,fs,fa,fb,fc1,xsnr)
  parameter(NDAT=100,NFFT1=8*NDAT,NH1=NFFT1/2)
  complex c(0:npts-1)                   !Complex waveform
  complex c2(0:NFFT1-1)                 !Short spectra
  real s(-NH1+1:NH1)                    !Coarse spectrum
  real ss(-NH1+1:NH1)                   !Smoothed coarse spectrum
  real w(0:NFFT1-1)
  real pi
  logical first
  data first/.true./
  save first,w

  if(first) then
    pi=4.0*atan(1.0)
    do i=0,NFFT1-1
      w(i)=sin(pi*i/(NDAT-1))**2
    enddo
    first=.false.
  endif

  nspec=int((npts-NFFT1)/NDAT)+1
  df1=fs/NFFT1
  s=0.
  do k=1,nspec
     ia=(k-1)*NDAT
     ib=ia+NFFT1-1
     c2(0:NFFT1-1)=c(ia:ib)*w
     call four2a(c2,NFFT1,1,-1,1)
     do i=0,NFFT1-1
        j=i
        if(j.gt.NH1) j=j-NFFT1
        s(j)=s(j) + real(c2(i))**2 + aimag(c2(i))**2
     enddo
  enddo
  do i=-NH1+1+4,NH1-4
    ss(i)=sum(s(i-4:i+4))/9.0
  enddo
!  do i=-NH1+1+8,NH1-8
!    ss(i)=sum(ss(i-4:i+4))/9.0
!  enddo
do i=-20,20
write(52,*) i*df1,ss(i)
enddo
    
  smax=0.
  ipk=0
  fc1=0.
  ia=nint(fa/df1)
  ib=nint(fb/df1)
  do i=ia,ib
     f=i*df1
     if(ss(i).gt.smax) then
        smax=ss(i)
        ipk=i
        fc1=f
     endif
  enddo

  xint=(log(ss(ipk-1))-log(ss(ipk+1)))/(log(ss(ipk-1))+log(ss(ipk+1))-2*log(ss(ipk)))
  fc1=fc1+xint*df1/2.0
! The following is for testing SNR calibration:
  sp3n=sum(s(ipk-5:ipk+5))          
  base=(sum(s)-sp3n)/(NFFT1-11.0)
  psig=sp3n-11*base              
  pnoise=(2500.0/df1)*base
  xsnr=db(psig/pnoise)
  return
end subroutine getcandidate2

subroutine wsprcpm_downsample(iwave,c)

! Input: i*2 data in iwave() at sample rate 12000 Hz
! Output: Complex data in c(), sampled at 400 Hz

  include 'wsprcpm_params.f90'
  parameter (NMAX=120*12000,NFFT2=NMAX/53)
  integer*2 iwave(NMAX)
  complex c(0:NZ-1)
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
  c=c1(0:NZ-1)
  
  return
end subroutine wsprcpm_downsample

