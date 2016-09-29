subroutine msk144sync(cdat,nframes,ntol,delf,navmask,npeaks,fc,fest,   &
     npklocs,nsuccess,c)

  parameter (NSPM=864)
  complex cdat(NSPM*nframes)
  complex cdat2(NSPM*nframes)
  complex c(NSPM)                    !Coherently averaged complex data
  complex ct2(2*NSPM)
  complex cs(NSPM)
  complex cb(42)                     !Complex waveform for sync word 
  complex cc(0:NSPM-1)

  integer*8 count0,count1,clkfreq
  integer s8(8)
  integer iloc(1)
  integer npklocs(npeaks)
  integer navmask(nframes)                 ! defines which frames to average
  integer OMP_GET_NUM_THREADS

  real cbi(42),cbq(42)
  real pkamps(npeaks)
  real xcc(0:NSPM-1)
  real xccs(0:NSPM-1)
  real pp(12)                        !Half-sine pulse shape
  logical first
  data first/.true./
  data s8/0,1,1,1,0,0,1,0/
  save first,cb,fs,pi,twopi,dt,s8,pp,t,ncall

  call system_clock(count0,clkfreq)
  if(first) then
     pi=4.0*atan(1.0)
     twopi=8.0*atan(1.0)
     fs=12000.0
     dt=1.0/fs

     do i=1,12                       !Define half-sine pulse
       angle=(i-1)*pi/12.0
       pp(i)=sin(angle)
     enddo

! Define the sync word waveforms
     s8=2*s8-1  
     cbq(1:6)=pp(7:12)*s8(1)
     cbq(7:18)=pp*s8(3)
     cbq(19:30)=pp*s8(5)
     cbq(31:42)=pp*s8(7)
     cbi(1:12)=pp*s8(2)
     cbi(13:24)=pp*s8(4)
     cbi(25:36)=pp*s8(6)
     cbi(37:42)=pp(1:6)*s8(8)
     cb=cmplx(cbi,cbq)

     ncall=0
     t=0.0
     first=.false.
  endif

  navg=sum(navmask) 
  xmax=0.0
  bestf=0.0
  n=nframes*NSPM
  nf=nint(ntol/delf)
  fac=1.0/(48.0*sqrt(float(navg)))

  do ifr=-nf,nf            !Find freq that maximizes sync
     ferr=ifr*delf
     call tweak1(cdat,n,-(fc+ferr),cdat2)
     c=0
     do i=1,nframes
        ib=(i-1)*NSPM+1
        ie=ib+NSPM-1
        if( navmask(i) .eq. 1 ) then
          c(1:NSPM)=c(1:NSPM)+cdat2(ib:ie)
        endif
     enddo

     cc=0
     ct2(1:NSPM)=c
     ct2(NSPM+1:2*NSPM)=c

!     nchunk=NSPM/2
!   !$OMP PARALLEL SHARED(cb,ct2,cc,nchunk) PRIVATE(ish)
!   !$OMP DO SCHEDULE(DYNAMIC,nchunk)
     do ish=0,NSPM-1
        cc(ish)=dot_product(ct2(1+ish:42+ish)+ct2(337+ish:378+ish),cb(1:42))
     enddo
!   !$OMP END DO NOWAIT
!     rewind 71; nt=OMP_GET_NUM_THREADS(); write(71,*) nt; flush(71)
!   !$OMP END PARALLEL

     xcc=abs(cc)
     xb=maxval(xcc)*fac
     if(xb.gt.xmax) then
        xmax=xb
        bestf=ferr
        cs=c
        xccs=xcc
     endif
  enddo

  fest=fc+bestf
  c=cs
  xcc=xccs

! Find npeaks largest peaks
  do ipk=1,npeaks
     iloc=maxloc(xcc)
     ic2=iloc(1)
     npklocs(ipk)=ic2
     pkamps(ipk)=xcc(ic2-1)
     xcc(max(0,ic2-7):min(NSPM-1,ic2+7))=0.0
  enddo

  if( xmax .lt. 0.7 ) then
    nsuccess=0
  else
    nsuccess=1
  endif

  ncall=ncall+1
  call system_clock(count1,clkfreq)
  t=t + float(count1-count0)/clkfreq
!  write(*,3001) t,20*t/ncall
!3001 format(2f8.3)

  return
end subroutine msk144sync
