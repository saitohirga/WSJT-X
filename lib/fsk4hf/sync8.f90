subroutine sync8(iwave,xdt,f1,s)

  include 'ft8_params.f90'
  parameter (IZ=10,JZ=20)
  character*1 line(-JZ:JZ),mark(0:6)
  complex cx(0:NH1)
  real s(NH1,NHSYM)
  real savg(NH1)
  real x(NFFT1)
  real sync2d(-IZ:IZ,-JZ:JZ)
  integer*2 iwave(NMAX)
  integer iloc(1)
  integer icos7(0:6)
  data icos7/2,5,6,0,4,1,3/                   !Costas 7x7 tone pattern
  data mark/' ',' ','.','-','+','X','$'/
  equivalence (x,cx)

! Compute symbol spectra at half-symbol steps.  
  savg=0.
  istep=NSPS/2
  tstep=istep/12000.0
  df=12000.0/NFFT1

  fac=1.0/300.0
  do j=1,NHSYM
     ia=(j-1)*istep + 1
     ib=ia+NSPS-1
     x(1:NSPS)=fac*iwave(ia:ib)
     x(NSPS+1:)=0.
     call four2a(x,NFFT1,1,-1,0)              !r2c FFT
     do i=1,NH1
        s(i,j)=real(cx(i))**2 + aimag(cx(i))**2
     enddo
     savg=savg + s(1:NH1,j)
  enddo

  ia=nint(30.0/df)
  ib=nint(3000.0/df)
  savg=savg/NHSYM
  pmax=0.
  i0=0
  do i=ia,ib
     p=sum(savg(i-8:i+8))/17.0
     if(p.gt.pmax) then
        pmax=p
        i0=i-7
     endif
  enddo

  tmax=0.
  ipk=0
  jpk=0
  j0=1 + nint(0.5/tstep)
  do i=-IZ,IZ
     do j=-JZ,JZ
        t=0.
        do n=0,6
           k=j0+j+2*n
           if(k.ge.1) t=t + s(i0+i+2*icos7(n),k)
           t=t + s(i0+i+2*icos7(n),k+72)
           if(k+144.le.NHSYM) t=t + s(i0+i+2*icos7(n),k+144)
        enddo
        sync2d(i,j)=t
        if(t.gt.tmax) then
           tmax=t
           jpk=j
           ipk=i
        endif
     enddo
  enddo
  f0=i0*df
  f1=(i0+ipk)*df
  xdt=jpk*tstep

  return
end subroutine sync8
