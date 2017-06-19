subroutine sync8(iwave,s,candidate,ncand)

  include 'ft8_params.f90'
  parameter (JZ=20)
  complex cx(0:NH1)
  real s(NH1,NHSYM)
  real savg(NH1)
  real x(NFFT1)
  real sync2d(NH1,-JZ:JZ)
  real red(NH1)
  real candidate(3,100)
  integer*2 iwave(NMAX)
  integer jpeak(NH1)
  integer indx(NH1)
  integer ii(1)
  integer icos7(0:6)
  data icos7/2,5,6,0,4,1,3/                   !Costas 7x7 tone pattern
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

  ia=nint(200.0/df)
  ib=nint(4000.0/df)
  savg=savg/NHSYM

  do i=ia,ib
     do j=-JZ,JZ
        t=0.
        do n=0,6
           k=j+2*n
           if(k.ge.1) t=t + s(i+2*icos7(n),k)
           t=t + s(i+2*icos7(n),k+72)
           if(k+144.le.NHSYM) t=t + s(i+2*icos7(n),k+144)
        enddo
        sync2d(i,j)=t
     enddo
  enddo

  red=0.
  do i=ia,ib
     ii=maxloc(sync2d(i,-JZ:JZ)) - 1 - JZ
     j0=ii(1)
     jpeak(i)=j0
     red(i)=sync2d(i,j0)
  enddo
  iz=ib-ia+1
  call indexx(red(ia:ib),iz,indx)
  ibase=indx(nint(0.40*iz)) - 1 + ia
  base=red(ibase)
  red=red/base

  candidate=0.
  k=0
  do i=1,100
     n=ia + indx(iz+1-i) - 1
     if(red(n).lt.2.0) exit
     do j=1,k                        !Eliminate near-dupe freqs
        f=n*df
        if(abs(f-candidate(1,j)).lt.3.0) go to 10
     enddo
     k=k+1
     candidate(1,k)=n*df
     candidate(2,k)=(jpeak(n)-1)*tstep
     candidate(3,k)=red(n)
!     write(*,3024) k,candidate(1:3,k)
!3024 format(i3,3f10.2)
10   continue
  enddo
  ncand=k
  fac=20.0/maxval(s)
  s=fac*s

  return
end subroutine sync8
