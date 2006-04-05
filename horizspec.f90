
!------------------------------------------------------ horizspec
subroutine horizspec(x,brightness,contrast,a)

  real x(4096)
  integer brightness,contrast
  integer*2 a(750,300)
  real y(512),ss(128)
  complex c(0:256)
  equivalence (y,c)
  include 'gcom1.f90'
  include 'gcom2.f90'
  save

  nfft=512
  nq=nfft/4
  gain=50.0 * 3.0**(0.36+0.01*contrast)
  gamma=1.3 + 0.01*contrast
  offset=0.5*(brightness+30.0)
!  offset=0.5*(brightness+60.0)
  df=11025.0/512.0
  if(ntr.ne.ntr0) then
     if(lauto.eq.0 .or. ntr.eq.TxFirst) then
        call hscroll(a,nx)
        nx=0
     endif
     ntr0=ntr
  endif

  i0=0
  do iter=1,5
     if(nx.lt.750) nx=nx+1
     if(nx.eq.1) then
        t0curr=Tsec
     endif
     do i=1,nfft
        y(i)=1.4*x(i+i0)
     enddo
     call xfft2(y,nfft)
     nq=nfft/4
     do i=1,nq
        ss(i)=real(c(i))**2 + aimag(c(i))**2
     enddo

     p=0.
     do i=21,120
        p=p+ss(i)
        n=0
! Use the gamma formula here!
        if(ss(i).gt.0.) n=gain*log10(0.05*ss(i)) + offset
!        if(ss(i).gt.0.) n=(0.2*ss(i))**gamma + offset
        n=min(252,max(0,n))
        j=121-i
        a(nx,j)=n
     enddo
     if(nx.eq.7 .or. nx.eq.378 .or. nx.eq.750) then
! Put in yellow ticks at the standard tone frequencies for FSK441, or
! at the sync-tone frequency for JT65, JT6M.
        do i=nx-4,nx
           if(mode.eq.'FSK441') then
              do n=2,5
                 j=121-nint(n*441/df)
                 a(i,j)=254
              enddo
           else if(mode(1:4).eq.'JT65') then
              j=121-nint(1270.46/df)
              a(i,j)=254
           else if(mode.eq.'JT6M') then
              j=121-nint(1076.66/df)
              a(i,j)=254
           endif
        enddo
     endif

     ng=140 - 30*log10(0.00033*p+0.001)
     ng=min(ng,150)
     if(nx.eq.1) ng0=ng
     if(abs(ng-ng0).le.1) then
        a(nx,ng)=255
     else
        ist=1
        if(ng.lt.ng0) ist=-1
        jmid=(ng+ng0)/2
        i=max(1,nx-1)
        do j=ng0+ist,ng,ist
           a(i,j)=255
           if(j.eq.jmid) i=i+1
        enddo
        ng0=ng
     endif
     i0=i0+441
  enddo

  return
end subroutine horizspec
