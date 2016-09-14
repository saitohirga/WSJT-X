subroutine opdetmsk144(cbig,n,lines,nmessages,nutc,ntol,t00)
  use timer_module, only: timer

  parameter (NSPM=864, NPTS=7*NSPM, MAXCAND=16)
  character*22 msgreceived,allmessages(20)
  character*80 lines(100)
  complex cbig(n)
  complex cdat(NPTS)                    !Analytic signal
  complex cdat2(NPTS)
  complex c(NSPM)
  complex ct(NSPM)
  complex cs(NSPM)
  complex cb(42)                        !Complex waveform for sync word 
  complex cfac,cca,ccb
  complex cc1(0:NSPM-1)
  complex cc2(0:NSPM-1)
  complex bb(6)
  integer s8(8),hardbits(144)
  integer, dimension(1) :: iloc
  integer*1 decoded(80)   
  integer ipeaks(10)
  real cbi(42),cbq(42)
  real rcw(12)
  real ccm(0:NSPM-1)
  real ccms(0:NSPM-1)
  real dd(0:NSPM-1)
  real pp(12)                          !Half-sine pulse shape
  real*8 dt, fs, pi, twopi
  real softbits(144)
  real*8 lratio(128)
  real llr(128)
  logical first
  data first/.true./
  data s8/0,1,1,1,0,0,1,0/
  save first,cb,fs,pi,twopi,dt,s8,rcw,pp,nmatchedfilter

  if(first) then
     nmatchedfilter=1
! define half-sine pulse and raised-cosine edge window
     pi=4d0*datan(1d0)
     twopi=8d0*datan(1d0)
     fs=12000.0
     dt=1.0/fs

     do i=1,12
       angle=(i-1)*pi/12.0
       pp(i)=sin(angle)
       rcw(i)=(1-cos(angle))/2
     enddo

! define the sync word waveforms
     s8=2*s8-1  
     cbq(1:6)=pp(7:12)*s8(1)
     cbq(7:18)=pp*s8(3)
     cbq(19:30)=pp*s8(5)
     cbq(31:42)=pp*s8(7)
     cbi(1:12)=pp*s8(2)
     cbi(13:24)=pp*s8(4)
     cbi(25:36)=pp*s8(6)
     cbi(37:42)=pp(1:6)*s8(8)
     cb=cmplx(cbi,cbq)

     first=.false.
  endif

  nmessages=0
  allmessages=char(0)
  lines=char(0)
  nshort=0
!  write(*,*) "number of points in opdetmsk144",n
  if( n .lt. 24000 .or. n .gt. 49000) return  
  nsteps=2*n/6000-1
!  write(*,*) 'nsteps ',nsteps
  nsnr=-4
  
  do istep=1,nsteps 
    ib=(istep-1)*NPTS/2+1 
    if( ib+NPTS-1 .gt. n ) ib=n-NPTS+1
    cdat=cbig(ib:ib+NPTS-1)
  
    xmax=0.0
    bestf=0.0
    do if=-200,200   ! search for frequency that maximizes sync correlation 
      ferr=if
! shift analytic signal to baseband
      call tweak1(cdat,NPTS,-(1500+ferr),cdat2)
      c=0
      do i=1,7
        ib=(i-1)*NSPM+1
        ie=ib+NSPM-1
        c(1:NSPM)=c(1:NSPM)+cdat2(ib:ie)
      enddo 

      cc1=0
      cc2=0
      do ish=0,NSPM-1
        ct=cshift(c,ish) 
        cc1(ish)=sum(ct(1:42)*conjg(cb))
        cc2(ish)=sum(ct(56*6:56*6+41)*conjg(cb))
      enddo
      ccm=abs(cc1+cc2)
      dd=abs(cc1)*abs(cc2)
      xb=maxval(ccm)
      if( xb .gt. xmax ) then
        xmax=xb
        bestf=ferr
        cs=c
        ccms=ccm
        endif
    enddo

    fest=1500+bestf
    t0=t00+1.0
    c=cs
    ccm=ccms

! Find 2 largest peaks
    do ipk=1, 2
      iloc=maxloc(ccm)
      ic2=iloc(1)
      ipeaks(ipk)=ic2
      ccm(max(0,ic2-7):min(NSPM-1,ic2+7))=0.0
    enddo

    do ipk=1,2
      do is=1,3

        ic0=ipeaks(ipk)
        if( is.eq.2 ) ic0=max(1,ic0-1)
        if( is.eq.3 ) ic0=min(NSPM,ic0+1)
        ct=cshift(c,ic0-1)

! Estimate final frequency error and carrier phase. 
        cca=sum(ct(1:1+41)*conjg(cb))
        ccb=sum(ct(1+56*6:1+56*6+41)*conjg(cb))
        cfac=ccb*conjg(cca)
        ffin=atan2(imag(cfac),real(cfac))/(twopi*56*6*dt)
        phase0=atan2(imag(cca+ccb),real(cca+ccb))

! Remove phase error - want constellation rotated so that sample points lie on I/Q axes
          cfac=cmplx(cos(phase0),sin(phase0))
          ct=ct*conjg(cfac)

          if( nmatchedfilter .eq. 0 ) then
! sample to get softsamples
            do i=1,72
              softbits(2*i-1)=imag(c(1+(i-1)*12))
              softbits(2*i)=real(c(7+(i-1)*12))  
            enddo
          else
! matched filter - 
            softbits(1)=sum(imag(ct(1:6))*pp(7:12))+sum(imag(ct(864-5:864))*pp(1:6))
            softbits(2)=sum(real(ct(1:12))*pp)
            do i=2,72
              softbits(2*i-1)=sum(imag(ct(1+(i-1)*12-6:1+(i-1)*12+5))*pp)
              softbits(2*i)=sum(real(ct(7+(i-1)*12-6:7+(i-1)*12+5))*pp)
            enddo
          endif

! sync word hard error weight is a good discriminator for 
! frames that have reasonable probability of decoding
          hardbits=0
          do i=1,144
            if( softbits(i) .ge. 0.0 ) then
              hardbits(i)=1
            endif
          enddo
          nbadsync1=(8-sum( (2*hardbits(1:8)-1)*s8 ) )/2
          nbadsync2=(8-sum( (2*hardbits(1+56:8+56)-1)*s8 ) )/2
          nbadsync=nbadsync1+nbadsync2
!write(*,*) 'peak index ',ipk,' pk loc: ',ic0,' nbadsync ',nbadsync
          if( nbadsync .gt. 4 ) cycle

! normalize the softsymbols before submitting to decoder
          sav=sum(softbits)/144
          s2av=sum(softbits*softbits)/144
          ssig=sqrt(s2av-sav*sav)
          softbits=softbits/ssig

          sigma=0.75
          lratio(1:48)=softbits(9:9+47)
          lratio(49:128)=softbits(65:65+80-1)
          llr=2.0*lratio/(sigma*sigma)
          lratio=exp(2.0*lratio/(sigma*sigma))
  
          max_iterations=10
          max_dither=1
          call timer('bpdec144 ',0)
          call bpdecode144(llr,max_iterations,decoded,niterations)
          call timer('bpdec144 ',1)
          if( niterations .ge. 0.0 ) then
            call extractmessage144(decoded,msgreceived,nhashflag)
            if( nhashflag .gt. 0 ) then  ! CRCs match, so print it 
              ndupe=0
              do im=1,nmessages
                if( allmessages(im) .eq. msgreceived ) ndupe=1
              enddo
              if( ndupe .eq. 0 ) then
                nmessages=nmessages+1
                allmessages(nmessages)=msgreceived
                write(lines(nmessages),1020) nutc,nsnr,t0,nint(fest),msgreceived
1020            format(i6.6,i4,f5.1,i5,' ^ ',a22)
              endif
              goto 999
            else
              msgreceived=' '
              ndither=-99             ! -99 is bad hash flag
            endif
          endif
      enddo ! slicer dither
    enddo     ! peak loop 
  enddo
  msgreceived=' '
  ndither=-98   
999 continue
  return
end subroutine opdetmsk144
