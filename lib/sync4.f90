subroutine sync4(dat,jz,mode4,minw)

! Synchronizes JT4 data, finding the best-fit DT and DF.  

  use jt4
  use timer_module, only: timer

  parameter (NFFTMAX=2520)         !Max length of FFTs
  parameter (NHMAX=NFFTMAX/2)      !Max length of power spectra
  parameter (NSMAX=525)            !Max number of half-symbol steps
  real dat(jz)
  real psavg(NHMAX)                !Average spectrum of whole record
  real s2(NHMAX,NSMAX)             !2d spectrum, stepped by half-symbols
  real tmp(1260)
  save

! Do FFTs of twice symbol length, stepped by half symbols.  Note that 
! we have already downsampled the data by factor of 2.

  nsym=207
  nfft=2520
  nh=nfft/2
  nq=nfft/4
  nsteps=jz/nq - 1
  df=0.5*11025.0/nfft
  psavg(1:nh)=0.

  call timer('ps4     ',0)
  do j=1,nsteps                 !Compute spectrum for each step, get average
     k=(j-1)*nq + 1
     call ps4(dat(k),nfft,s2(1,j))
     psavg(1:nh)=psavg(1:nh) + s2(1:nh,j)
  enddo
  call timer('ps4     ',1)

  call timer('flat1a  ',0)
  nsmo=min(10*mode4,150)
  call flat1a(psavg,nsmo,s2,nh,nsteps,NHMAX,NSMAX)        !Flatten spectra
  call timer('flat1a  ',1)

  call timer('smo     ',0)
  if(mode4.ge.9) call smo(psavg,nh,tmp,mode4/4)
  call timer('smo     ',1)

  ia=600.0/df
  ib=1600.0/df

!  ichmax=1.0+log(float(mode4))/log(2.0)
  do ich=minw+1,7                     !Find best width
     kz=nch(ich)/2
! Set istep>1 for wide submodes?
     do i=ia+kz,ib-kz                     !Find best frequency channel for CCF
        call timer('xcor4   ',0)
        call xcor4(s2,i,nsteps,nsym,ich,mode4)
        call timer('xcor4   ',1)
     enddo
  enddo

  return
end subroutine sync4

