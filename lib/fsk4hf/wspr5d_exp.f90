program wspr5d

! Decode WSPR-LF data read from *.c5 or *.wav files.

! WSPR-LF is a potential WSPR-like mode intended for use at LF and MF.
! It uses an LDPC (300,60) code, OQPSK modulation, and 5 minute T/R sequences.
!
! Still to do: find and decode more than one signal in the specified passband.

!  include 'wsprlf_params.f90'

  parameter (NDOWN=30)
  parameter (KK=60)
  parameter (ND=300)
  parameter (NS=109)
  parameter (NR=3)
  parameter (NN=NR+NS+ND)
  parameter (NSPS0=8640)
  parameter (NSPS=16)
  parameter (N2=2*NSPS)
  parameter (NZ=NSPS*NN)
  parameter (NZ400=288*NN)
  parameter (NMAX=300*12000)

  character arg*8,message*22,cbits*50,infile*80,fname*16,datetime*11
  character*120 data_dir
  complex csync(0:NZ-1)                 !Sync symbols only, from cbb
  complex c400(0:NZ400-1)                     !Complex waveform
  complex c(0:NZ-1)                     !Complex waveform
  complex cd(0:NZ-1)                    !Complex waveform
  complex ca(0:NZ-1)                    !Complex waveform
  complex zz
  real*8 fMHz
  real rxdata(ND),llr(ND)               !Soft symbols
  real pp(32)                       !Shaped pulse for OQPSK
  real sbits(412),softbits(9)
  real fpks(20)
  integer id(NS+ND)                     !NRZ values (+/-1) for Sync and Data
  integer isync(48)                     !Long sync vector
  integer ib13(13)                      !Barker 13 code
  integer ihdr(11)
  integer*8 n8
  integer*2 iwave(NMAX)                 !Generated full-length waveform  
  integer*1 idat(7)
  integer*1 decoded(KK),apmask(ND),cw(ND)
  integer*1 hbits(412),bits(13)
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
       read(10,end=999) fname,ntrmin,fMHz,c400
       read(fname(8:11),*) nutc
       write(datetime,'(i11)') nutc
    else if(j2.gt.0) then
       read(10,end=999) ihdr,iwave
       read(infile(j2-4:j2-1),*) nutc
       datetime=infile(j2-11:j2-1)
       call wspr5_downsample(iwave,c400)
    else
       print*,'Wrong file format?'
       go to 999
    endif
    close(10)

    fa=100.0
    fb=150.0
    fs400=400.0
    call getfc1(c400,fs400,fa,fb,fc1,xsnr)         !First approx for freq
!write(*,*) datetime,'initial guess ',fc1
    npeaks=5
    call getfc2(c400,npeaks,fs400,fc1,fpks)      !Refined freq

    do idf=1,npeaks ! consider the top npeak peaks 
      fc2=fpks(idf)
      call downsample(c400,fc1+fc2,cd)
      s2=sum(cd*conjg(cd))/(16*412)
      cd=cd/sqrt(s2)
      do is=0,8 ! dt search range is narrow, to save time. 
        idt=is/2
        if( mod(is,2).eq. 1 ) idt=-(is+1)/2 
        xdt=real(22+idt)/22.222 - 1.0
        ca=cshift(cd,22+idt)
        do iseq=1,3  ! try sequence estimation lengths of 3, 6, and 9 bits.
          k=1-2*iseq
          nseq=iseq*3
          do i=1,408,iseq*4
            k=k+iseq*2
            j=(i+1)*16
            call mskseqdet(nseq,ca(j),pp,id(k),softbits,1,phase)
            hbits(i:i+iseq*4)=bits
            sbits(i:i+iseq*4)=bits

            sbits(i+1)=softbits(1)
            sbits(i+2)=softbits(2)
            if( id(k+1) .ne. 0 ) sbits(i+2)=id(k+1)*25
              sbits(i+3)=softbits(3)

            if( iseq .ge. 2 ) then
              sbits(i+5)=softbits(4)
              sbits(i+6)=softbits(5)
            if( id(k+3) .ne. 0 ) sbits(i+6)=id(k+3)*25
              sbits(i+7)=softbits(6)
              if( iseq .eq. 3 ) then
                sbits(i+9)=softbits(7)
                sbits(i+10)=softbits(8)
                if( id(k+5) .ne. 0 ) sbits(i+10)=id(k+5)*25
                sbits(i+11)=softbits(9)
              endif
            endif
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
!          sigma=0.84
          sigma=1.20
          llr=2*rxdata/(sigma*sigma)
          apmask=0
          max_iterations=40
          ifer=0
          nbadcrc=0
          call bpdecode300(llr,apmask,max_iterations,decoded,niterations,cw)
! niterations will be equal to the Hamming distance between hard received word and the codeword
          if(niterations.lt.0) call osd300(llr,3,decoded,niterations,cw)
          if(niterations.ge.0) call chkcrc10(decoded,nbadcrc)
          if(niterations.lt.0 .or. nbadcrc.ne.0) ifer=1
          if( ifer.eq.0 ) then
            write(cbits,1200) decoded(1:50)
1200        format(50i1)
            read(cbits,1202) idat
1202        format(6b8,b2)
            idat(7)=ishft(idat(7),6)
            call wqdecode(idat,message,itype)
            nsnr=nint(xsnr)
!            freq=fMHz + 1.d-6*(fc1+fc2)
            freq=fc1+fc2
            nfdot=0
            write(13,1210) datetime,0,nsnr,xdt,freq,message,nfdot
1210        format(a11,2i4,f6.2,f12.7,2x,a22,i3)
            write(*,1212) datetime(8:11),nsnr,xdt,freq,nfdot,message,'*',idf,nseq,is,niterations
!1212        format(a4,i4,f5.1,f11.6,i3,2x,a22,a1,i3,i3,i3,i4)
1212        format(a4,i4,f8.3,f8.3,i3,2x,a22,a1,i3,i3,i3,i4)
            goto 888
          endif
        enddo !iseq
      enddo
    enddo
888 continue
  enddo

  write(*,1120)
1120 format("<DecodeFinished>")

999 end program wspr5d

subroutine getmetric(ib,ps,xmet)
  real ps(0:511)
  xm1=0
  xm0=0
  do i=0,511
    if( iand(i/ib,1) .eq. 1 .and. ps(i) .gt. xm1 ) xm1=ps(i)
    if( iand(i/ib,1) .eq. 0 .and. ps(i) .gt. xm0 ) xm0=ps(i)
  enddo
  xmet=xm1-xm0
  return
end subroutine getmetric

subroutine mskseqdet(ns,cdat,pp,bsync,softbits,ncoh,phase)
!
! Detect sequences of 3, 6, or 9 bits (ns).
! Sync bits are assumed to be known. 
!
complex cdat(16*12),cbest(16*12),cideal(16*12)
complex cdf(16*12),cfac,zz
real cm(0:511),cmbest(0:511)
real pp(32),softbits(9)
integer bit(13),bestbits(13),sgn(13)
integer bsync(7)

twopi=8.0*atan(1.0)
dt=30.0*18.0/12000.0
cmax=0;
fbest=0.0;
np=2**ns-1
idfmax=40
if( ncoh .eq. 1 ) idfmax=0
do idf=0,idfmax
  if( mod(idf,2).eq.1 ) deltaf=idf/2*0.02
  if( mod(idf,2).eq.1 ) deltaf=-(idf+1)/2*0.02
  dphi=twopi*deltaf*dt
  cfac=cmplx(cos(dphi),sin(dphi)) 
  cdf=1.0
  do i=2,16*(ns-1)
    cdf(i)=cdf(i-1)*cfac
  enddo 

  cm=0
  ibflag=0
  do i=0,np
    bit(1)=(bsync(1)+2)/4
    bit(2)=iand(i/(2**(ns-1)),1)
    bit(3)=iand(i/(2**(ns-2)),1)
    if( bsync(2).ne.0 ) then ! force the barker bits
      bit(3)=(bsync(2)+2)/4
    endif
    bit(4)=iand(i/(2**(ns-3)),1)
    bit(5)=(bsync(3)+2)/4

    if( ns .ge. 6 ) then
      bit(6)=iand(i/(2**(ns-4)),1)
      bit(7)=iand(i/(2**(ns-5)),1)
      if( bsync(4).ne.0 ) then ! force the barker bits
        bit(7)=(bsync(4)+2)/4
      endif
      bit(8)=iand(i/(2**(ns-6)),1)
      bit(9)=(bsync(5)+2)/4
      if( ns .eq. 9 ) then
        bit(10)=iand(i/4,1)
        bit(11)=iand(i/2,1)
        if( bsync(6).ne.0 ) then ! force the barker bits
          bit(11)=(bsync(6)+2)/4
        endif
        bit(12)=iand(i/1,1)
        bit(13)=(bsync(7)+2)/4
      endif
    endif

    sgn=2*bit-1
    cideal(1:16)   =cmplx(sgn(1)*pp(17:32),sgn(2)*pp(1:16))
    cideal(17:32)  =cmplx(sgn(3)*pp(1:16),sgn(2)*pp(17:32))
    cideal(33:48)  =cmplx(sgn(3)*pp(17:32),sgn(4)*pp(1:16))
    cideal(49:64)  =cmplx(sgn(5)*pp(1:16),sgn(4)*pp(17:32))
    if( ns .ge. 6 ) then
      cideal(65:80)  =cmplx(sgn(5)*pp(17:32),sgn(6)*pp(1:16))
      cideal(81:96)  =cmplx(sgn(7)*pp(1:16),sgn(6)*pp(17:32))
      cideal(97:112) =cmplx(sgn(7)*pp(17:32),sgn(8)*pp(1:16))
      cideal(113:128)=cmplx(sgn(9)*pp(1:16),sgn(8)*pp(17:32))
      if( ns .eq. 9 ) then
        cideal(129:144)  =cmplx(sgn(9)*pp(17:32),sgn(10)*pp(1:16))
        cideal(145:160)  =cmplx(sgn(11)*pp(1:16),sgn(10)*pp(17:32))
        cideal(161:176) =cmplx(sgn(11)*pp(17:32),sgn(12)*pp(1:16))
        cideal(177:192)=cmplx(sgn(13)*pp(1:16),sgn(12)*pp(17:32))
      endif
    endif
    cideal=cideal*cdf
    cm(i)=abs(sum(cdat(1:64*ns/3)*conjg(cideal(1:64*ns/3))))/1.e3
    if( cm(i) .gt. cmax ) then
      ibflag=1
      cmax=cm(i)
      bestbits=bit
      cbest=cideal
      fbest=deltaf
      zz=sum(cdat*conjg(cbest))/1.e3
      phase=atan2(imag(zz),real(zz))
    endif
  enddo
  if( ibflag .eq. 1 ) then ! new best found
    cmbest=cm
  endif
enddo
softbits=0.0
call getmetric(1,cmbest,softbits(ns))
call getmetric(2,cmbest,softbits(ns-1))
call getmetric(4,cmbest,softbits(ns-2))
if( ns .ge. 6 ) then
  call getmetric(8,cmbest,softbits(ns-3))
  call getmetric(16,cmbest,softbits(ns-4))
  call getmetric(32,cmbest,softbits(ns-5))
  if( ns .eq. 9 ) then
    call getmetric(64,cmbest,softbits(3))
    call getmetric(128,cmbest,softbits(2))
    call getmetric(256,cmbest,softbits(1))
  endif
endif
end subroutine mskseqdet

subroutine downsample(ci,f0,co)
  parameter(NI=412*288,NO=NI/18)
  complex ci(0:NI-1),ct(0:NI-1) 
  complex co(0:NO-1)

  df=400.0/NI
  ct=ci
  call four2a(ct,NI,1,-1,1)             !c2c FFT to freq domain
  i0=nint(f0/df)
  co=0.0
  co(0)=ct(i0)
  b=3.0
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

subroutine getfc1(c,fs,fa,fb,fc1,xsnr)

!  include 'wsprlf_params.f90'
  parameter (NZ=288*412)
  parameter (NSPS=288)
  parameter (N2=2*NSPS)
  parameter (NFFT1=16*NSPS)
  parameter (NH1=NFFT1/2)

  complex c(0:NZ-1)                     !Complex waveform
  complex c2(0:NFFT1-1)                 !Short spectra
  real s(-NH1+1:NH1)                    !Coarse spectrum
  nspec=NZ/N2
  df1=fs/NFFT1
  s=0.
  do k=1,nspec
     ia=(k-1)*N2
     ib=ia+N2-1
     c2(0:N2-1)=c(ia:ib)
     c2(N2:)=0.
     call four2a(c2,NFFT1,1,-1,1)
     do i=0,NFFT1-1
        j=i
        if(j.gt.NH1) j=j-NFFT1
        s(j)=s(j) + real(c2(i))**2 + aimag(c2(i))**2
     enddo
  enddo
!        call smo121(s,NFFT1)
  smax=0.
  ipk=0
  fc1=0.
  ia=nint(fa/df1)
  ib=nint(fb/df1)
  do i=ia,ib
     f=i*df1
     if(s(i).gt.smax) then
        smax=s(i)
        ipk=i
        fc1=f
     endif
!            write(51,3001) f,s(i),db(s(i))
! 3001       format(f10.3,e12.3,f10.3)
  enddo

! The following is for testing SNR calibration:
  sp3n=(s(ipk-1)+s(ipk)+s(ipk+1))               !Sig + 3*noise
  base=(sum(s)-sp3n)/(NFFT1-3.0)                !Noise per bin
  psig=sp3n-3*base                              !Sig only
  pnoise=(2500.0/df1)*base                      !Noise in 2500 Hz
  xsnr=db(psig/pnoise)
  xsnr=xsnr+5.0
  return
end subroutine getfc1

subroutine getfc2(c,npeaks,fs,fc1,fpks)

!  include 'wsprlf_params.f90'
  parameter (NZ=288*412)
  parameter (NSPS=288)
  parameter (N2=2*NSPS)
  parameter (NFFT1=16*NSPS)
  parameter (NH1=NFFT1/2)

  complex c(0:NZ-1)                     !Complex waveform
  complex cs(0:NZ-1)                    !For computing spectrum
  real a(5)
  real freqs(413),sp2(413),fpks(npeaks)
  integer pkloc(1)

  df=fs/NZ
  baud=fs/NSPS
  a(1)=-fc1
  a(2:5)=0.
  call twkfreq1(c,NZ,fs,a,cs)         !Mix down by fc1

! Filter, square, then FFT to get refined carrier frequency fc2.
  call four2a(cs,NZ,1,-1,1)          !To freq domain

  ia=nint(0.75*baud/df) 
  cs(ia:NZ-1-ia)=0.                  !Save only freqs around fc1
!  do i=1,NZ/2
!    filt=1/(1+((i*df)**2/(0.50*baud)**2)**8)
!    cs(i)=cs(i)*filt
!    cs(NZ+1-i)=cs(NZ+1-i)*filt
!  enddo 
  call four2a(cs,NZ,1,1,1)           !Back to time domain
  cs=cs/NZ
  cs=cs*cs                           !Square the data
  call four2a(cs,NZ,1,-1,1)          !Compute squared spectrum
! Find two peaks separated by baud
  pmax=0.
  fc2=0.
!  ja=nint(0.3*baud/df)
  ja=nint(0.5*baud/df)
  k=1
  sp2=0.0
  do j=-ja,ja
     f2=j*df
     ia=nint((f2-0.5*baud)/df)
     if(ia.lt.0) ia=ia+NZ
     ib=nint((f2+0.5*baud)/df)
     p=real(cs(ia))**2 + aimag(cs(ia))**2 +                        &
          real(cs(ib))**2 + aimag(cs(ib))**2           
     if(p.gt.pmax) then
        pmax=p
        fc2=0.5*f2
     endif
     freqs(k)=0.5*f2
     sp2(k)=p
     k=k+1
!           write(52,1200) f2,p,db(p)
!1200       format(f10.3,2f15.3)
  enddo

  do i=1,npeaks
    pkloc=maxloc(sp2)
    ipk=pkloc(1)
    fpks(i)=freqs(ipk)
    ipk0=max(1,ipk-2)
    ipk1=min(413,ipk+2)
!    ipk0=ipk
!    ipk1=ipk
    sp2(ipk0:ipk1)=0.0
  enddo
  return
end subroutine getfc2
