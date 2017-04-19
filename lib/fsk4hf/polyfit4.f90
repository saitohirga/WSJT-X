subroutine polyfit4(x,y,sigmay,npts,nterms,mode,a,chisqr)

  parameter (MAXN=20)
  implicit real*8 (a-h,o-z)
  real x(npts), y(npts), sigmay(npts), a(nterms),chisqr
  real*8 sumx(2*MAXN-1), sumy(MAXN), array(MAXN,MAXN)

! Accumulate weighted sums
  nmax = 2*nterms-1
  sumx=0.
  sumy=0.
  chisq=0.
  do i=1,npts
     xi=x(i)
     yi=y(i)
     if(mode.lt.0) then
        weight=1./abs(yi)
     else if(mode.eq.0) then
        weight=1
     else
        weight=1./sigmay(i)**2
     end if
     xterm=weight
     do n=1,nmax
        sumx(n)=sumx(n)+xterm
        xterm=xterm*xi
     enddo
     yterm=weight*yi
     do n=1,nterms
        sumy(n)=sumy(n)+yterm
        yterm=yterm*xi
     enddo
     chisq=chisq+weight*yi**2
  enddo

! Construct matrices and calculate coefficients
  do j=1,nterms
     do k=1,nterms
        n=j+k-1
        array(j,k)=sumx(n)
     enddo
  enddo

  delta=determ4(array,nterms)
  if(delta.eq.0) then
     chisqr=0.
     a=0.
  else
     do l=1,nterms
        do j=1,nterms
           do k=1,nterms
              n=j+k-1
              array(j,k)=sumx(n)
           enddo
           array(j,l)=sumy(j)
        enddo
        a(l)=determ4(array,nterms)/delta
     enddo

! Calculate chi square

     do j=1,nterms
        chisq=chisq-2*a(j)*sumy(j)
        do k=1,nterms
           n=j+k-1
           chisq=chisq+a(j)*a(k)*sumx(n)
        enddo
     enddo
     free=npts-nterms
     chisqr=chisq/free
  end if
  
  return
end subroutine polyfit4

real*8 function determ4(array,norder)

  parameter (MAXN=20)
  implicit real*8 (a-h,o-z)
  real*8 array(MAXN,MAXN)

  determ4=1.
  do k=1,norder
     if (array(k,k).ne.0) go to 41
     do j=k,norder
        if(array(k,j).ne.0) go to 31
     enddo
     determ4=0.
     go to 60

31   do i=k,norder
        s8=array(i,j)
        array(i,j)=array(i,k)
        array(i,k)=s8
     enddo
     determ4=-1.*determ4
41   determ4=determ4*array(k,k)
     if(k.lt.norder) then
        k1=k+1
        do i=k1,norder
           do j=k1,norder
              array(i,j)=array(i,j)-array(i,k)*array(k,j)/array(k,k)
           enddo
        enddo
     end if
  enddo

60 return
end function determ4
