subroutine subtractft8(dd0,itone,f0,dt,ldt)

! Subtract an ft8 signal.  If ldt==.true., refine DT first.
  
! Raw data         : dd(t)    = a(t)cos(2*pi*f0*t+theta(t))
! Reference signal : cref(t)  = exp( j*(2*pi*f0*t+phi(t)) )
  
  parameter (NMAX=15*12000,NFRAME=1920*79)
  real dd(NMAX),dd0(NMAX)
  complex cref(NFRAME)
  logical ldt

! Generate complex reference waveform
  call gen_ft8wave(itone,79,1920,2.0,12000.0,f0,cref,xjunk,1,NFRAME)

  if(ldt) then                           !Are we refining DT ?
     sqa=sqf(dd0,cref,f0,dt,ldt,-300,dd) !Yes
     sqb=sqf(dd0,cref,f0,dt,ldt,300,dd)
  endif
  sq0=sqf(dd0,cref,f0,dt,ldt,0,dd)       !Do the subtraction with idt=0
  if(ldt) then
     call peakup(sqa,sq0,sqb,dx)
     if(abs(dx).gt.1.0) goto 100         !No acceptable minimum: do not subtract
     i1=nint(300.0*dx)                   !First approximation of better idt
     sqa=sqf(dd0,cref,f0,dt,ldt,i1-60,dd)
     sqb=sqf(dd0,cref,f0,dt,ldt,i1+60,dd)
     sq0=sqf(dd0,cref,f0,dt,ldt,i1,dd)
     call peakup(sqa,sq0,sqb,dx)
     if(abs(dx).gt.1.0) then             !No acceptable minimum
        sq0=sqf(dd0,cref,f0,dt,ldt,0,dd) !Use idt=0 for subtraction
        go to 100
     endif
     i2=nint(60.0*dx) + i1               !Best estimate of idt
     sq0=sqf(dd0,cref,f0,dt,ldt,i2,dd)   !Do the subtraction with idt=i2
  endif
100 dd0=dd                               !Return dd0 with signal subtracted

  return
end subroutine subtractft8

real function sqf(dd0,cref,f0,dt,ldt,idt,dd)

! Raw data         : dd0(t)   = a(t)cos(2*pi*f0*t+theta(t))
! Reference signal : cref(t)  = exp( j*(2*pi*f0*t+phi(t)) )
! Complex amp      : cfilt(t) = LPF[ dd(t)*CONJG(cref(t)) ]
! Subtract         : dd(t)    = dd0(t) - 2*REAL{cref*cfilt}
  
  parameter (NMAX=15*12000,NFRAME=1920*79)
  parameter (NFFT=NMAX,NFILT=2800)
  real dd(NMAX),dd0(NMAX)
  real window(-NFILT/2:NFILT/2)
  real x(NFFT+2)
  complex cx(0:NFFT/2),cref(NFRAME)
  complex camp,cfilt,cw,z
  logical first,ldt
  data first/.true./
  common/heap8/camp(NMAX),cfilt(NMAX),cw(NMAX)
  equivalence (x,cx)
  save first,/heap8/

  if(first) then
! Create and normalize the filter
     pi=4.0*atan(1.0)
     fac=1.0/float(nfft)
     sumw=0.0
     do j=-NFILT/2,NFILT/2
        window(j)=cos(pi*j/NFILT)**2
        sumw=sumw+window(j)
     enddo
     cw=0.
     cw(1:NFILT+1)=window/sumw
     cw=cshift(cw,NFILT/2+1)
     call four2a(cw,nfft,1,-1,1)
     cw=cw*fac
     first=.false.
  endif
  
  nstart=dt*12000+1 + idt
  camp=0.
  dd=dd0
  do i=1,nframe
     j=nstart-1+i 
     if(j.ge.1.and.j.le.NMAX) camp(i)=dd(j)*conjg(cref(i))
  enddo
  cfilt(1:nframe)=camp(1:nframe)
  cfilt(nframe+1:)=0.0
  call four2a(cfilt,nfft,1,-1,1)
  cfilt(1:nfft)=cfilt(1:nfft)*cw(1:nfft)
  call four2a(cfilt,nfft,1,1,1)

  x=0.
  do i=1,nframe
     j=nstart+i-1
     if(j.ge.1 .and. j.le.NMAX) then
        z=cfilt(i)*cref(i)
        dd(j)=dd(j)-2.0*real(z)      !Subtract the reconstructed signal
        x(i)=dd(j)
     endif
  enddo
  sq=0.
  if(ldt) then
     call four2a(cx,NFFT,1,-1,0)                 !Forward FFT, r2c
     df=12000.0/NFFT
     ia=(f0-1.5*6.25)/df
     ib=(f0+8.5*6.25)/df
     do i=ia,ib
        sq=sq + real(cx(i))*real(cx(i)) + aimag(cx(i))*aimag(cx(i))
     enddo
  endif
  sqf=sq

  return
end function sqf
