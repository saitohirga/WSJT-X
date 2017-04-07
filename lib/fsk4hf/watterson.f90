subroutine watterson(c,delay,fspread)

  parameter (NZ=3456000)
  complex c(0:NZ-1)
  complex c2(0:NZ-1)
  complex cs1(0:NZ-1)
  complex cs2(0:NZ-1)

  df=12000.0/NZ
  if(fspread.gt.0.0) then
     do i=0,NZ-1
        xx=gran()
        yy=gran()
        cs1(i)=cmplx(xx,yy)
        xx=gran()
        yy=gran()
        cs2(i)=cmplx(xx,yy)
     enddo
     call four2a(cs1,NZ,1,-1,1)     !To freq domain
     call four2a(cs2,NZ,1,-1,1)
     do i=0,NZ-1
        f=i*df
        if(i.gt.NZ/2) f=(i-NZ)*df
        x=(f/fspread)**2
        a=0.
        if(x.le.50.0) then
           a=exp(-x)
        endif
        cs1(i)=a*cs1(i)
        cs2(i)=a*cs2(i)
!        if(abs(f).lt.10.0) then
!           p1=real(cs1(i))**2 + aimag(cs1(i))**2
!           p2=real(cs2(i))**2 + aimag(cs2(i))**2
!           write(62,3101) f,db(p1+1.e-12)-60,db(p2+1.e-12)-60
!3101       format(3f10.3)
!        endif
     enddo
     call four2a(cs1,NZ,1,1,1)     !Back to time domain
     call four2a(cs2,NZ,1,1,1)
     cs1=cs1/NZ
     cs2=cs2/NZ
  endif
  
  nshift=0.001*delay*12000.0
  c2=cshift(c,nshift)

  sq=0.
  do i=0,NZ-1
     if(fspread.eq.0.0) c(i)=0.5*(c(i) + c2(i))
     if(fspread.gt.0.0) c(i)=0.5*(cs1(i)*c(i) + cs2(i)*c2(i))
     sq=sq + real(c(i))**2 + aimag(c(i))**2
!     write(61,3001) i/12000.0,c(i)
!3001 format(3f12.6)
  enddo
  rms=sqrt(sq/NZ)
  c=c/rms

  return
end subroutine watterson
