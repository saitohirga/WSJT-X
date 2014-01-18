subroutine flat3(s0,iz,nfa,nfb,nterms,ynoise,s)

  implicit real*8 (a-h,o-z)
  parameter (NSMAX=6827)
  real*4 s0(iz)
  real*4 s(iz)
  real*4 ynoise,y4,db

  real*8 x(NSMAX)
  real*8 y(NSMAX)
  real*8 y0(NSMAX)
  real*8 yfit(NSMAX)
  real*8 a(10)
  integer ii(NSMAX)

  npts0=999999
  df=12000.0/16384.0

  do i=1,iz
     y0(i)=db(s0(i))
  enddo
  ia=(nfa+200.0)/df
  ib=5000.0/df
  if(nfb.gt.0) ib=nfb/df
  j=0
  do i=ia,ib
     j=j+1
     x(j)=i*df
     y(j)=y0(i)
     ii(j)=i
  enddo

  npts=j
  mode=0
  a=0.0

  do iter=1,99
     call polfit(x,y,y,npts,nterms,mode,a,chisqr)

     do i=1,ib
        f=i*df
        yfit(i)=a(nterms)
        do n=nterms-1,1,-1
           yfit(i)=f*yfit(i) + a(n)
        enddo
!        write(21,1010) f,y0(i),yfit(i),y0(i)-yfit(i)
!1010    format(4f12.3)
     enddo
     k=0
     do j=1,npts
        y1=y(j)-yfit(ii(j))
        if(y1.lt.ynoise) then
!        if(y1.lt.ynoise .and. y1.gt.-ynoise) then
           k=k+1
           x(k)=x(j)
           y(k)=y(j)
           ii(k)=ii(j)
        endif
     enddo
     npts=k
     if(npts.eq.npts0 .or. npts.lt.(ib-ia)/10) exit
     npts0=npts
  enddo

!  do j=1,npts
!     write(22,1010) x(j),y(j),yfit(ii(j)),y(j)-yfit(ii(j))
!  enddo

  do i=1,ib
     y4=y0(i)-yfit(i) - 10.0
     s(i)=10.0**(0.1*y4)
  enddo

end subroutine flat3
