!---------------------------------------------------- spec
subroutine spec(brightness,contrast,logmap,ngain,nspeed,a)

! Called by SpecJT in its TopLevel Python code.  
! Probably should use the "!f2py intent(...)" structure here.

! Input:
  integer brightness,contrast   !Display parameters
  integer ngain                 !Digital gain for input audio
  integer nspeed                !Scrolling speed index
! Output:
  integer*2 a(225000)           !Pixel values for 750 x 300 array

  real a0(225000)               !Save the last 300 spectra
  integer nstep(5)
  integer b0,c0
  real x(4096)                  !Data for FFT
  complex c(0:2048)             !Complex spectrum
  real ss(2048)                 !Power spectrum
  logical first
  include 'gcom1.f90'
  include 'gcom2.f90'
  include 'gcom3.f90'
  include 'gcom4.f90'
  data jz/0/                    !Number of spectral lines available
  data nstep/15,10,5,2,1/       !Integration limits
  data first/.true./

  equivalence (x,c)
  save

  if(first) then
     istep=2205
     nfft=4096
     nh=nfft/2
     do i=1,nh
        ss(i)=0.
     enddo
     df=11025.0/nfft
     fac=2.0/10000.
     nsum=0
     iread=0
     first=.false.
     b0=-999
     c0=-999
     logmap0=-999
     nspeed0=-999
     nx=0
     ncall=0
     jza=0
     rms=0.
  endif

  nmode=1
  if(mode(1:4).eq.'JT65') nmode=2
  if(mode.eq.'Echo') nmode=3
  if(mode.eq.'JT6M') nmode=4

  nlines=0
  newdat=0
  npts=iwrite-iread
  if(ndiskdat.eq.1) then
     npts=jzc/2048
     npts=2048*npts
     kread=0
     if(nspeed.ge.6) then
        call hscroll(a,nx)
        nx=0
     endif
  endif
  if(npts.lt.0) npts=npts+nmax
  if(npts.lt.nfft) go to 900               !Not enough data available

10 continue
  if(ndiskdat.eq.1) then
! Data read from disk
     k=kread
     do i=1,nfft
        k=k+1
        x(i)=0.4*d2c(k)
     enddo
     kread=kread+istep                       !Update pointer
  else
! Real-time data
     dgain=2.0*10.0**(0.005*ngain)
     k=iread
     do i=1,nfft
        k=k+1
        if(k.gt.nmax) k=k-nmax
        x(i)=0.5*dgain*y1(k)
     enddo
     iread=iread+istep                       !Update pointer
     if(iread.gt.nmax) iread=iread-nmax
  endif

  sum=0.                                     !Get ave, rms of data
  do i=1,nfft
     sum=sum+x(i)
  enddo
  ave=sum/nfft
  sq=0.
  do i=1,nfft
     d=x(i)-ave
     sq=sq+d*d
     x(i)=fac*d
  enddo
  rms1=sqrt(sq/nfft)
  if(rms.eq.0) rms=rms1
  rms=0.25*rms1 + 0.75*rms
  
  if(ndiskdat.eq.0) then
     level=0                                    !Compute S-meter level
     if(rms.gt.0.0) then                        !Scale 0-100, steps = 0.4 dB
        dB=20.0*log10(rms/800.0)
        level=50 + 2.5*dB
        if(level.lt.0) level=0
        if(level.gt.100) level=100
     endif
  endif

  if(nspeed.ge.6) then
     call horizspec(x,brightness,contrast,a)
     ncall=Mod(ncall+1,5)
     if(ncall.eq.1 .or. nspeed.eq.7) newdat=1
     if(ndiskdat.eq.1) then
        npts=jzc-kread
     else
        npts=iwrite-iread
        if(npts.lt.0) npts=npts+nmax
     endif
     if(npts.ge.4096) go to 10
     go to 900
  endif

  call xfft2(x,nfft)

  do i=1,nh                               !Accumulate power spectrum
     ss(i)=ss(i) + real(c(i))**2 + aimag(c(i))**2
  enddo
  nsum=nsum+1

  if(nsum.ge.nstep(nspeed)) then      !Integrate for specified time
     nlines=nlines+1
     do i=225000,751,-1               !Move spectra up one row
        a0(i)=a0(i-750)               ! (will be "down" on display)
     enddo
     if(ndiskdat.eq.1 .and. nlines.eq.1) then
        do i=1,750
           a0(i)=255
        enddo
        do i=225000,751,-1
           a0(i)=a0(i-750)
        enddo
     endif

     if(nflat.gt.0) call flat2(ss,nh,nsum)

     ia=1
     if(nfrange.eq.2000) then
        i0=182 + nint((nfmid-1500)/df)
        if(i0.lt.0) ia=1-i0
     else if(nfrange.eq.4000) then
        i0=nint(nfmid/df - 752.0)
        if(i0.lt.0) ia=1-i0/2
     endif
     do i=ia,750                       !Insert new data in top row
        if(nfrange.eq.2000) then
           a0(i)=5*ss(i+i0)/nsum
        else if(nfrange.eq.4000) then
           smax=max(ss(2*i+i0),ss(2*i+i0-1))
           a0(i)=5*smax/nsum
        endif
        xdb=-40.
        if(a0(i).gt.0.) xdb=10*log10(a0(i))
20   enddo
     nsum=0
     newdat=1                          !Flag for new spectrum available
     do i=1,nh                         !Zero the accumulating array
        ss(i)=0.
     enddo
     if(jz.lt.300) jz=jz+1
  endif

  if(ndiskdat.eq.1) then
     npts=jzc-kread
  else
     npts=iwrite-iread
     if(npts.lt.0) npts=npts+nmax
  endif

  if(npts.ge.4096) go to 10

!  Compute pixel values 
  iz=750
  logmap=0
  if(brightness.ne.b0 .or. contrast.ne.c0 .or. logmap.ne.logmap0 .or.    &
          nspeed.ne.nspeed0 .or. nlines.gt.1) then
     iz=225000
     gain=40*sqrt(nstep(nspeed)/5.0) * 5.0**(0.01*contrast)
     gamma=1.3 + 0.01*contrast
     offset=(brightness+64.0)/2
     b0=brightness
     c0=contrast
     logmap0=logmap
     nspeed0=nspeed
  endif

  do i=1,iz
     n=0
     if(a0(i).gt.0.0 .and. logmap.eq.1) n=gain*log10(0.001*a0(i)) + offset + 20
     if(a0(i).gt.0.0 .and. logmap.eq.0) n=(0.01*a0(i))**gamma + offset
     n=min(252,max(0,n))
     a(i)=n
  enddo

900 continue
  if(ndiskdat.eq.1) ndecoding=4
  return
end subroutine spec
