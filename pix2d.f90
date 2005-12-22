subroutine pix2d(d2,jz,mousebutton,s2,nchan,nz,b)

! Compute pixels to represent the 2-d spectrum s2(nchan,nz), and the
! green line.

  integer*2 d2(jz)                   !Raw input data
  real s2(nchan,nz)                  !2-d spectrum
  integer*2 b(60000)                 !Pixels corresponding to 2-d spectrum

  tbest=s2(2,1)
  s2(1,1)=s2(3,1)
  s2(2,1)=s2(3,1)

  gain=100.
  offset=0.0

  if(mousebutton.eq.0) then
     k=0
     do i=54,7,-1
        do j=1,nz
           k=k+1
           n=0
           if(s2(i,j).gt.0) n=gain*log10(s2(i,j)) + offset
           n=min(252,max(0,n))
           b(k)=n
        enddo
        k=k+500-nz
     enddo
     do i=k+1,60000
        b(i)=0
     enddo

  else
! This is a mouse-picked decode, so we compute the "zoomed" region.
     k=50*500
     do i=54,7,-1
        do j=1,nz
           k=k+1
           n=0
           if(s2(i,j).gt.0) n=gain*log10(s2(i,j)) + offset
           n=min(252,max(0,n))
           b(k)=n
        enddo
        k=k+500-nz
     enddo
  endif

  if(mousebutton.eq.0) then
! Compute the green curve
     sum=0.
     do i=1,jz
        sum=sum+d2(i)
     enddo
     nave=nint(sum/jz)
     nadd=661
     ngreen=min(jz/nadd,500)
     k=0
     j=0
     do i=1,ngreen
        sq=0.
        do n=1,nadd
           k=k+1
           d2(k)=d2(k)-nave
           x=d2(k)
           sq=sq + x*x
        enddo
        x=0.0001*sq/nadd
        j=j+1
        x=120.0-40.0*log10(0.01*x)
        if(x.lt.1.0) x=1.0
        if(x.gt.119.) x=119.
        ng=nint(x)
        ng=min(ng,120)
        nx=i
        if(nx.eq.1) ng0=ng
        if(abs(ng-ng0).le.1) then
           b((ng-1)*500+nx)=255
        else
           ist=1
           if(ng.lt.ng0) ist=-1
           jmid=(ng+ng0)/2
           ii=max(1,nx-1)
           do j=ng0+ist,ng,ist
              b((j-1)*500+ii)=255
              if(j.eq.jmid) ii=ii+1
           enddo
           ng0=ng
        endif
     enddo
! Insert yellow tick marks at frequencies of the FSK441 tones
     do i=2,5
        f=441*i
        ich=58-nint(f/43.066)
        do j=1,5
           b((ich-1)*500+j+2)=254
           b((ich-1)*500+j+248)=254
           b((ich-1)*500+j+495)=254
        enddo
     enddo

! Mark the best ping with a red tick
     if(tbest.gt.0.0) then
        nx=tbest/0.060 + 1
        do j=110,120
           b((j-1)*500+nx0)=0
           b((j-1)*500+nx)=253
        enddo
        nx0=nx
     endif
  endif

  return
end subroutine pix2d
