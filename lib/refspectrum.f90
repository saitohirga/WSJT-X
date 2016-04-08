subroutine refspectrum(id2,brefspec)

! Input:
!  id2       i*2        Raw 16-bit integer data, 12000 Hz sample rate
!  brefspec  logical    True when accumulating a reference spectrum

  parameter (NFFT=6912,NH=NFFT/2)
  integer*2 id2(NH)
  logical brefspec,brefspec0
  real x(NFFT)
  real s(0:NH)
  complex cx(0:NH)
  equivalence(x,cx)
  data nsave/0/,brefspec0/.false./
  save brefspec0,nsave,s

  if(brefspec) then
     if(.not.brefspec0) then
        nsave=0
        s=0.
        brefspec0=.true.
     endif
     
     x(1:NH)=0.001*id2
     x(NH+1:)=0.0
     call four2a(x,NFFT,1,-1,0)                 !r2c FFT

     do i=1,NH
        s(i)=s(i) + real(cx(i))**2 + aimag(cx(i))**2
     enddo
     nsave=nsave+1

     if(mod(nsave,34).eq.0) then                   !About 9.8 sec 
        df=12000.0/NFFT
!        ia=nint(500.0/df)
!        ib=nint(2500.0/df)
!        call pctile(s(ia),ib-ia+1,50,xmed)
!        db0=db(xmed)
!        nhadd=10
        open(16,file='refspec.dat',status='unknown')
        do i=1,NH
           freq=i*df
!           ia=max(1,i-nhadd)
!           ib=min(NH,i+nhadd)
!           smo=sum(s(ia:ib))/(ib-ia+1)
           write(16,1000) freq,s(i),db(s(i))
1000       format(f10.3,e12.3,f12.6)
        enddo
        close(16)
     endif
  endif

  return
end subroutine refspectrum
