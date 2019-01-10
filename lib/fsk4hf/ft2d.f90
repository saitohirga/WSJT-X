program ft2d

  use crc
  use packjt77
  include 'ft2_params.f90'
  character arg*8,message*37,c77*77,infile*80,fname*16,datetime*11
  character*37 decodes(100)
  character*120 data_dir
  character*90 dmsg
  complex c2(0:3*1200-1)                  !Complex waveform
  complex cd(0:144*10-1)                  !Complex waveform
  complex c1(0:9),c0(0:9)
  complex ccor(0:1,144)
  complex csum,cterm,cc0,cc1
  real*8 fMHz

  real rxdata(128),llr(128)               !Soft symbols
  real llr2(128)
  real sbits(144),sbits1(144),sbits3(144)
  real ps(0:8191),psbest(0:8191)
  real candidates(100,2)
  integer ihdr(11)
  integer*2 iwave(NMAX)                 !Generated full-length waveform  
  integer*1 message77(77),apmask(128),cw(128)
  integer*1 hbits(144),hbits1(144),hbits3(144)
  logical unpk77_success

  fs=12000.0/NDOWN                       !Sample rate
  dt=1/fs                                !Sample interval after downsample (s)
  tt=NSPS*dt                             !Duration of "itone" symbols (s)
  baud=1.0/tt                            !Keying rate for "itone" symbols (baud)
  txt=NZ*dt                              !Transmission length (s)
  twopi=8.0*atan(1.0)
  h=0.8                                  !h=0.8 seems to be optimum for AWGN sensitivity (not for fading)

  dphi=twopi/2*baud*h*dt*16  ! dt*16 is samp interval after downsample
  dphi0=-1*dphi
  dphi1=+1*dphi
  phi0=0.0
  phi1=0.0
  do i=0,9
    c1(i)=cmplx(cos(phi1),sin(phi1))
    c0(i)=cmplx(cos(phi0),sin(phi0))
    phi1=mod(phi1+dphi1,twopi)
    phi0=mod(phi0+dphi0,twopi)
  enddo
  the=twopi*h/2.0
  cc1=cmplx(cos(the),-sin(the))
  cc0=cmplx(cos(the),sin(the))
  nargs=iargc()
  if(nargs.lt.1) then
     print*,'Usage:   ft2d [-a <data_dir>] [-f fMHz] [-c ncoh] file1 [file2 ...]'
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
  
  xs1=0.0
  xs2=0.0
  fr1=0.0
  fr2=0.0
  nav=0
  ngood=0

  do ifile=iarg,nargs
     call getarg(ifile,infile)
     j2=index(infile,'.wav')
     open(10,file=infile,status='old',access='stream')
     read(10,end=999) ihdr,iwave
     read(infile(j2-4:j2-1),*) nutc
     datetime=infile(j2-11:j2-1)
     close(10)

     ndecodes=0
     ncand=1
     do icand=1,ncand
        fc0=1500.0
        xsnr=1.0
        istart=6000+8
        call ft2_downsample(iwave,c2) ! downsample from 160s/Symbol to 10s/Symbol

        ib=istart/16
        cd=c2(ib:ib+144*10-1) 
        s2=sum(cd*conjg(cd))/(10*144)
        cd=cd/sqrt(s2)
        do nseq=1,7
           if( nseq.eq.1 ) then  ! noncoherent single-symbol detection
              sbits1=0.0
              do ibit=1,144
                 ib=(ibit-1)*10
                 ccor(1,ibit)=sum(cd(ib:ib+9)*conjg(c1(0:9)))        
                 ccor(0,ibit)=sum(cd(ib:ib+9)*conjg(c0(0:9)))   
                 sbits1(ibit)=abs(ccor(1,ibit))-abs(ccor(0,ibit))
                 hbits1(ibit)=0
                 if(sbits1(ibit).gt.0) hbits1(ibit)=1
              enddo 
              sbits=sbits1
              hbits=hbits1
              sbits3=sbits1
              hbits3=hbits1
           elseif( nseq.ge.2 ) then
              nbit=2*nseq-1
              numseq=2**(nbit)
              ps=0
              do ibit=nbit/2+1,144-nbit/2
                 ps=0.0
                 pmax=0.0
                 do iseq=0,numseq-1
                    csum=0.0
                    cterm=1.0
                    k=1
                    do i=nbit-1,0,-1
                       ibb=iand(iseq/(2**i),1) 
                       csum=csum+ccor(ibb,ibit-(nbit/2+1)+k)*cterm
                       if(ibb.eq.0) cterm=cterm*cc0
                       if(ibb.eq.1) cterm=cterm*cc1
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
                 call getbitmetric(2**(nbit/2),psbest,numseq,sbits3(ibit))
                 hbits3(ibit)=0
                 if(sbits3(ibit).gt.0) hbits3(ibit)=1
              enddo
              sbits=sbits3
              hbits=hbits3
           endif
           rxdata(1:48)=sbits(9:56)
           rxdata(49:128)=sbits(65:144)
           rxav=sum(rxdata(1:128))/128.0
           rx2av=sum(rxdata(1:128)*rxdata(1:128))/128.0
           rxsig=sqrt(rx2av-rxav*rxav)
           rxdata=rxdata/rxsig
           sigma=0.90
           llr(1:128)=2*rxdata/(sigma*sigma)
           apmask=0
           max_iterations=40
           ifer=0
           do ibias=0,0
              llr2=llr
              if(ibias.eq.1) llr2=llr+0.4
              if(ibias.eq.2) llr2=llr-0.4
              call bpdecode128_90(llr2,apmask,max_iterations,message77,cw,nharderror,niterations)
              if(nharderror.ge.0) exit 
           enddo
           nhardmin=-1
           if(sum(message77).eq.0) cycle
           if( nharderror.ge.0 ) then
              write(c77,'(77i1)') message77(1:77)
              call unpack77(c77,message,unpk77_success)
              do i=1,ndecodes
                 if(decodes(i).eq.message) idupe=1 
              enddo
              if(idupe.eq.1) goto 888
              ndecodes=ndecodes+1 
              decodes(ndecodes)=message
              nsnr=nint(xsnr)
              freq=fMHz + 1.d-6*(fc1+fbest)
1210          format(a11,2i4,f6.2,f12.7,2x,a22,i3)
              write(*,1212) datetime(8:11),nsnr,xdt,freq,message,'*',idf,nseq,ijitter,nharderror,nhardmin
1212          format(a4,i4,f5.1,f11.6,2x,a22,a1,i5,i5,i5,i5,i5)
              goto 888
           endif
        enddo ! nseq
888     continue
     enddo !candidate list
  enddo !files

  write(*,1120)
1120 format("<DecodeFinished>")

999 end program ft2d

subroutine getbitmetric(ib,ps,ns,xmet)
  real ps(0:ns-1)
  xm1=0
  xm0=0
  do i=0,ns-1
    if( iand(i/ib,1) .eq. 1 .and. ps(i) .gt. xm1 ) xm1=ps(i)
    if( iand(i/ib,1) .eq. 0 .and. ps(i) .gt. xm0 ) xm0=ps(i)
  enddo
  xmet=xm1-xm0
  return
end subroutine getbitmetric

subroutine downsample2(ci,f0,co)
  parameter(NI=144*160,NH=NI/2,NO=NI/16)  ! downsample from 200 samples per symbol to 10
  complex ci(0:NI-1),ct(0:NI-1) 
  complex co(0:NO-1)
  fs=12000.0
  df=fs/NI
  ct=ci
  call four2a(ct,NI,1,-1,1)             !c2c FFT to freq domain
  i0=nint(f0/df)
  ct=cshift(ct,i0)
  co=0.0
  co(0)=ct(0)
  b=8.0
  do i=1,NO/2
     arg=(i*df/b)**2
     filt=exp(-arg)
     co(i)=ct(i)*filt
     co(NO-i)=ct(NI-i)*filt
  enddo
  co=co/NO
  call four2a(co,NO,1,1,1)            !c2c FFT back to time domain
  return
end subroutine downsample2

subroutine getcandidate2(c,npts,fs,fa,fb,ncand,candidates)
  parameter(NDAT=200,NFFT1=120*12000/32,NH1=NFFT1/2,NFFT2=120*12000/320,NH2=NFFT2/2)
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

subroutine ft2_downsample(iwave,c)

! Input: i*2 data in iwave() at sample rate 12000 Hz
! Output: Complex data in c(), sampled at 1200 Hz

  include 'ft2_params.f90'
  parameter (NFFT2=NMAX/16)
  integer*2 iwave(NMAX)
  complex c(0:NMAX/16-1)
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
  c=c1(0:NMAX/16-1)
  return
end subroutine ft2_downsample

