subroutine msk40decodeframe(c,mycall,hiscall,xsnr,msgreceived,nsuccess)
!  use timer_module, only: timer

  parameter (NSPM=240)
  character*4 rpt(0:15)
  character*6 mycall,hiscall,mycall0,hiscall0
  character*22 hashmsg,msgreceived
  complex cb(42)
  complex cfac,cca
  complex c(NSPM)
  integer*1 cw(32)
  integer*1 decoded(16)
  integer s8r(8),hardbits(40)
  integer nhashes(0:15)
  real*8 dt, fs, pi, twopi
  real cbi(42),cbq(42)
  real pp(12)
  real softbits(40)
  real llr(32)
  logical first
  data first/.true./
  data s8r/1,0,1,1,0,0,0,1/
  data mycall0/'dummy'/,hiscall0/'dummy'/
  data rpt/"-03 ","+00 ","+03 ","+06 ","+10 ","+13 ","+16 ", &
           "R-03","R+00","R+03","R+06","R+10","R+13","R+16", &
           "RRR ","73  "/
  save first,cb,fs,nhashes,pi,twopi,dt,s8r,pp,rpt,mycall0,hiscall0

  if(first) then
! define half-sine pulse and raised-cosine edge window
     pi=4d0*datan(1d0)
     twopi=8d0*datan(1d0)
     fs=12000.0
     dt=1.0/fs

     do i=1,12
       angle=(i-1)*pi/12.0
       pp(i)=sin(angle)
     enddo

! define the sync word waveforms
     s8r=2*s8r-1  
     cbq(1:6)=pp(7:12)*s8r(1)
     cbq(7:18)=pp*s8r(3)
     cbq(19:30)=pp*s8r(5)
     cbq(31:42)=pp*s8r(7)
     cbi(1:12)=pp*s8r(2)
     cbi(13:24)=pp*s8r(4)
     cbi(25:36)=pp*s8r(6)
     cbi(37:42)=pp(1:6)*s8r(8)
     cb=cmplx(cbi,cbq)
     first=.false.
  endif

  if(mycall.ne.mycall0 .or. hiscall.ne.hiscall0) then
    do i=0,15
      hashmsg=trim(mycall)//' '//trim(hiscall)//' '//rpt(i)
      call fmtmsg(hashmsg,iz)
      call hash(hashmsg,22,ihash)
      nhashes(i)=iand(ihash,4095)
    enddo
    mycall0=mycall
    hiscall0=hiscall
  endif

  nsuccess=0
  msgreceived=' '

! Estimate carrier phase. 
  cca=sum(c(1:1+41)*conjg(cb))
  phase0=atan2(imag(cca),real(cca))

! Remove phase error - want constellation rotated so that sample points lie on I/Q axes
  cfac=cmplx(cos(phase0),sin(phase0))
  c=c*conjg(cfac)

! matched filter - 
  softbits(1)=sum(imag(c(1:6))*pp(7:12))+sum(imag(c(NSPM-5:NSPM))*pp(1:6))
  softbits(2)=sum(real(c(1:12))*pp)
  do i=2,20
    softbits(2*i-1)=sum(imag(c(1+(i-1)*12-6:1+(i-1)*12+5))*pp)
    softbits(2*i)=sum(real(c(7+(i-1)*12-6:7+(i-1)*12+5))*pp)
  enddo

! sync word hard error weight is used as a discriminator for 
! frames that have reasonable probability of decoding
  hardbits=0
  do i=1,40
    if( softbits(i) .ge. 0.0 ) then
      hardbits(i)=1
    endif
  enddo
  nbadsync1=(8-sum( (2*hardbits(1:8)-1)*s8r ) )/2
  nbadsync=nbadsync1
  if( nbadsync .gt. 3 ) then
    return
  endif

! normalize the softsymbols before submitting to decoder
  sav=sum(softbits)/40
  s2av=sum(softbits*softbits)/40
  ssig=sqrt(s2av-sav*sav)
  softbits=softbits/ssig

  sigma=0.75
  if(xsnr.lt.0.0) sigma=0.75-0.0875*xsnr
  llr(1:32)=softbits(9:40)
  llr=2.0*llr/(sigma*sigma)
  
  max_iterations=5
  call bpdecode40(llr,max_iterations,decoded,niterations)

  if( niterations .ge. 0.0 ) then
    call encode_msk40(decoded,cw)
    nhammd=0
    cord=0.0
    do i=1,32
      if( cw(i) .ne. hardbits(i+8) ) then
        nhammd=nhammd+1
        cord=cord+abs(softbits(i+8))
      endif
    enddo

    imsg=0
    do i=1,16
      imsg=ishft(imsg,1)+iand(1,decoded(17-i))
    enddo
    nrxrpt=iand(imsg,15)
    nrxhash=(imsg-nrxrpt)/16
!write(*,*) 'decodeframe ',nhammd,cord,nrxhash,nrxrpt,nhashes(nrxrpt)
    if(nhammd.le.5 .and. cord .lt. 1.7 .and. nrxhash.eq.nhashes(nrxrpt)) then
      nsuccess=1    
      write(msgreceived,'(a1,a,1x,a,a1,1x,a4)') "<",trim(mycall),   &
                                    trim(hiscall),">",rpt(nrxrpt)
      return
    endif 
  endif

  return
end subroutine msk40decodeframe
