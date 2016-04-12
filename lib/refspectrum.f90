subroutine refspectrum(id2,brefspec,buseref,fname)

! Input:
!  id2       i*2        Raw 16-bit integer data, 12000 Hz sample rate
!  brefspec  logical    True when accumulating a reference spectrum

  parameter (NFFT=6912,NH=NFFT/2)
  integer*2 id2(NH)
  logical*1 brefspec,buseref

  real x0(0:NH-1)                         !Input samples
  real x1(0:NH-1)                         !Output samples (delayed by one block)
  real x0s(0:NH-1)                        !Saved upper half of input samples
  real x1s(0:NH-1)                        !Saved upper half of output samples
  real x(0:NFFT-1)                        !Work array
  real*4 w(0:NFFT-1)                      !Window function
  real*4 s(0:NH)                          !Average spectrum
  real*4 fil(0:NH)
  logical first,firstuse
  complex cx(0:NH)                        !Complex frequency-domain work array
  character*(*) fname
  common/spectra/syellow(6827),ref(0:NH),filter(0:NH)
  equivalence(x,cx)
  data first/.true./,firstuse/.true./
  save

  if(first) then
     pi=4.0*atan(1.0)
     do i=0,NFFT-1
        ww=sin(i*pi/NFFT)
        w(i)=ww*ww/NFFT
     enddo
     nsave=0
     s=0.0
     filter=1.0
     x0s=0.
     x1s=0.
     first=.false.
  endif

  if(brefspec) then
     x(0:NH-1)=0.001*id2
     x(NH:NFFT-1)=0.0
     call four2a(x,NFFT,1,-1,0)                 !r2c FFT

     do i=1,NH
        s(i)=s(i) + real(cx(i))**2 + aimag(cx(i))**2
     enddo
     nsave=nsave+1

     fac0=0.9
     if(mod(nsave,4).eq.0) then
        df=12000.0/NFFT
        ia=nint(1000.0/df)
        ib=nint(2000.0/df)
        avemid=sum(s(ia:ib))/(ib-ia+1)
        do i=0,NH
           fil(i)=0.
           filter(i)=-60.0
           if(s(i).gt.0.0) then
              fil(i)=sqrt(avemid/s(i))
           endif
        enddo

! Modify these if spectrum falls off steeply inside these stated bounds:
        ia=nint(240.0/df)
        ib=nint(4000.0/df)

        fac=fac0
        do i=ia,1,-1
           fac=fac*fac0
           fil(i)=fac*fil(i)
        enddo

        fac=fac0
        do i=ib,NH
           fac=fac*fac0
           fil(i)=fac*fil(i)
        enddo

        do iter=1,1000                        !### ??? ###
           call smo121(fil,NH)
        enddo

        do i=0,NH
           filter(i)=-60.0
           if(s(i).gt.0.0) filter(i)=20.0*log10(fil(i))
        enddo

!        open(16,file='refspec.dat',status='unknown')
        open(16,file=fname,status='unknown')
        do i=1,NH
           freq=i*df
           ref(i)=db(s(i)/avemid)
           write(16,1000) freq,s(i),ref(i),fil(i),filter(i)
1000       format(f10.3,e12.3,f12.6,e12.3,f12.6)
        enddo
        close(16)
     endif
     return
  endif

  if(buseref) then
     if(firstuse) then
!        open(16,file='refspec.dat',status='unknown')
        fil=1.0
        open(16,file=fname,status='old',err=10)
        do i=1,NH
           read(16,1000,err=10,end=10) freq,s(i),ref(i),fil(i),filter(i)
        enddo
10      close(16)
      firstuse=.false.
     endif
     x0=id2
     x(0:NH-1)=x0s                         !Previous 2nd half to new 1st half
     x(NH:NFFT-1)=x0                       !New 2nd half
     x0s=x0                                !Save the new 2nd half
     x=w*x                                 !Apply window
     call four2a(x,NFFT,1,-1,0)            !r2c FFT (to frequency domain)
     cx=fil*cx
     call four2a(cx,NFFT,1,1,-1)           !c2r FFT (back to time domain)
     x1=x1s + x(0:NH-1)                    !Add previous segment's 2nd half
     id2=nint(x1)
     x1s=x(NH:NFFT-1)                      !Save the new 2nd half
  endif


  return
end subroutine refspectrum
