subroutine dopspread(c,fspread)

  parameter (NFFT=268800,NH=NFFT/2)
  complex c(0:NFFT-1)
  complex cspread(0:NFFT-1)

  df=12000.0/nfft
  twopi=8*atan(1.0)
  cspread(0)=1.0
  cspread(NH)=0.
  b=6.0                                     !Lorenzian 3/28 onward
  do i=1,NH
     f=i*df
     x=b*f/fspread
     z=0.
     a=0.
     if(x.lt.3.0) then                          !Cutoff beyond x=3
        a=sqrt(1.111/(1.0+x*x)-0.1)             !Lorentzian
        call random_number(r1)
        phi1=twopi*r1
        z=a*cmplx(cos(phi1),sin(phi1))
     endif
     cspread(i)=z
     z=0.
     if(x.lt.50.0) then
        call random_number(r2)
        phi2=twopi*r2
        z=a*cmplx(cos(phi2),sin(phi2))
     endif
     cspread(NFFT-i)=z
  enddo

  izh=fspread/df
  do i=-izh,izh
     f=i*df
     j=i
     if(j.lt.0) j=j+nfft
     s=real(cspread(j))**2 + aimag(cspread(j))**2
!          write(23,3000) f,s,cspread(j)
!3000      format(f10.3,3f12.6)
  enddo

  call four2a(cspread,NFFT,1,1,1)             !Transform to time domain

  sum=0.
  do i=0,NFFT-1
     p=real(cspread(i))**2 + aimag(cspread(i))**2
     sum=sum+p
  enddo
  avep=sum/NFFT
  fac=sqrt(1.0/avep)
  cspread=fac*cspread                   !Normalize to constant avg power
  c=cspread*c                           !Apply Rayleigh fading to c()

  do i=0,NFFT-1
     p=real(cspread(i))**2 + aimag(cspread(i))**2
!     write(24,3010) i,p,cspread(i)
!3010 format(i8,3f12.6)
  enddo

  return
end subroutine dopspread
