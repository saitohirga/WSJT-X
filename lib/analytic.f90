subroutine analytic(d,npts,nfft,c,dpc,bseq,bdeq)

! Convert real data to analytic signal

  parameter (NFFTMAX=1024*1024)

  real d(npts)              ! passband signal
  real h(NFFTMAX/2)         ! real BPF magnitude
  real dpc(3),dpclast(3)    ! dynamic phase coeffs
  real spc(3),spclast(3)    ! static phase coeffs
  real ac(5)                ! currently unused static amp coeffs
  real fp     

  complex corrs(NFFTMAX/2)  ! allpass static phase correction 
  complex corrd(NFFTMAX/2)   ! allpass overall phase correction
  complex c(NFFTMAX)        ! analytic signal

  logical*1 bseq            ! boolean static equalizer flag
  logical*1 bdeq            ! boolean dynamic equalizer flag
  logical*1 bseqlast      

  data nfft0/0/
  data bseqlast/.false./
  data spclast/0.0,0.0,0.0/
  data spc/-0.952,0.768,-0.565/  ! baseline phase coeffs for TS2000
  data ac/1.0,0.05532,0.11438,0.12918,0.09274/ ! amp coeffs for TS2000

  save nfft0,h,spc,spclast,dpclast,ac,pi,t,beta

  df=12000.0/nfft
  nh=nfft/2
  if( nfft.ne.nfft0 ) then
     pi=4.0*atan(1.0)
     t=1.0/2000.0
     beta=0.1
     do i=1,nh+1
        ff=(i-1)*df
        f=ff-1500.0
        h(i)=1.0
        if(abs(f).gt.(1-beta)/(2*t) .and. abs(f).le.(1+beta)/(2*t)) then
           h(i)=h(i)*0.5*(1+cos((pi*t/beta )*(abs(f)-(1-beta)/(2*t))))
        endif
     enddo
     nfft0=nfft
  endif

  if( any(spclast .ne. spc) .or. any(dpclast .ne. dpc) ) then
     spclast=spc
     dpclast=dpc
     do i=1,nh+1
        ff=(i-1)*df
        f=ff-1500.0
        fp=f/1000.0
        ps=fp*fp*(spc(1)+fp*(spc(2)+fp*spc(3)))
        corrs(i)=cmplx(cos(ps),sin(ps))
        pd=fp*fp*(dpc(1)+fp*(dpc(2)+fp*dpc(3)))
        corrd(i)=cmplx(cos(pd),sin(pd))
     enddo
  endif

  fac=2.0/nfft
  c(1:npts)=fac*d(1:npts)
  c(npts+1:nfft)=0.
  call four2a(c,nfft,1,-1,1)               !Forward c2c FFT

  if( (.not. bseq) .and. (.not. bdeq) ) then
    c(1:nh+1)=h(1:nh+1)*c(1:nh+1)
  else if( bseq .and. (.not. bdeq) ) then
    c(1:nh+1)=h(1:nh+1)*corrs(1:nh+1)*c(1:nh+1)
  else if( (.not. bseq) .and. bdeq ) then
    c(1:nh+1)=h(1:nh+1)*corrd(1:nh+1)*c(1:nh+1)
  else if( bseq .and. bdeq ) then
    c(1:nh+1)=h(1:nh+1)*corrs(1:nh+1)*corrd(1:nh+1)*c(1:nh+1)
  endif

  c(1)=0.5*c(1)                            !Half of DC term
  c(nh+2:nfft)=0.                          !Zero the negative frequencies
  call four2a(c,nfft,1,1,1)                !Inverse c2c FFT
  spclast=spc
  dpclast=dpc
  return
end subroutine analytic
