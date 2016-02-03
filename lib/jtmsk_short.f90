subroutine jtmsk_short(cdat,npts,narg,tbest,idfpk,decoded)

! Decode short-format messages in JTMSK mode.

  parameter (NMAX=15*12000,NSAVE=100)
  character*22 msg,decoded,msgsent
  character*3 rpt(0:7)
  complex cdat(0:npts-1)
  complex cw(0:209,0:4095)                !Waveforms of possible messages
  complex cb11(0:65)                      !Complex waveform of Barker 11
  complex cd(0:511)
  complex z1,z2a,z2b
  real*8 dt,twopi,freq,phi,dphi0,dphi1,dphi
  real r1(0:NMAX-1)
  real r2(0:4095)
  real r1save(NSAVE)
  integer itone(234)                      !Message bits
  integer jgood(NSAVE)
  integer indx(NSAVE)
  integer narg(0:13)
  logical first
  data rpt /'26 ','27 ','28 ','R26','R27','R28','RRR','73 '/
  data first/.true./,nrxfreq0/-1/,ttot/0.0/
  save first,cw,cb11,nrxfreq0,ttot

  nrxfreq=narg(10)                      !Target Rx audio frequency (Hz)
  ntol=narg(11)                         !Search range, +/- ntol (Hz)
  nhashcalls=narg(12)

  if(first .or. nrxfreq.ne.nrxfreq0) then
     dt=1.d0/12000.d0
     twopi=8.d0*atan(1.d0)
     freq=nrxfreq
     dphi0=twopi*(freq-500.d0)*dt       !Phase increment, lower tone
     dphi1=twopi*(freq+500.d0)*dt       !Phase increment, upper tone
     nsym=35                            !Number of symbols
     nspm=6*nsym                        !Samples per message

     msg="<C1ALL C2ALL> 73"
     do imsg=0,4095                     !Generate all possible message waveforms
        ichk=10000+imsg
        call genmsk(msg,ichk,msgsent,itone,itype) !Encode the message
        k=-1
        phi=0.d0
        do j=1,nsym
           dphi=dphi0
           if(itone(j).eq.1) dphi=dphi1
           do i=1,6
              k=k+1
              phi=phi + dphi
              if(phi.gt.twopi) phi=phi-twopi
              xphi=phi
              cw(k,imsg)=cmplx(cos(xphi),sin(xphi))
           enddo
        enddo
     enddo
     cb11=cw(0:65,0)
     first=.false.
     nrxfreq0=nrxfreq
  endif

  r1thresh=0.80
  maxdecodes=999

  r1max=0.
!  call timer('r1      ',0)
  do j=0,npts-210                         !Find the B11 sync vectors
     z1=0.
     ss=0.
     do i=0,65
        ss=ss + real(cdat(j+i))**2 + aimag(cdat(j+i))**2
        z1=z1 + cdat(j+i)*conjg(cb11(i))  !Signal matching B11
     enddo
     ss=sqrt(ss/66.0)*66.0
     r1(j)=abs(z1)/(0.908*ss)             !Goodness-of-fit to B11
     if(r1(j).gt.r1max) then
        r1max=r1(j)
        jpk=j
     endif
  enddo
!  call timer('r1      ',1)

  k=0
  do j=1,npts-211
     if(r1(j).gt.r1thresh .and. r1(j).ge.r1(j-1) .and. r1(j).ge.r1(j+1) ) then
        k=k+1
        jgood(k)=j
        r1save(k)=r1(j)
        if(k.ge.NSAVE) exit
     endif
  enddo
  kmax=k
  call indexx(r1save,kmax,indx)

  df=12000.0/512.0
  ibest2=-1
  idfbest=0
  u1best=0.
!  call timer('kk      ',0)
  do kk=1,min(kmax,10)
     k=indx(kmax+1-kk)
     j=jgood(k)
     if(j.lt.144 .or. j.gt.npts-210) cycle
     t=j/12000.0
     u1=0.
     u2=0.
     r2max=0.
     ibest=-1

     do iidf=0,10
        idf=20*((iidf+1)/2)
        if(idf.gt.ntol) exit
        if(iand(iidf,1).eq.1) idf=-idf
        call tweak1(cdat(j-144:j+209),354,float(-idf),cd)
        cd(354:)=0.
        do imsg=0,4095
           ssa=0.
           ssb=0.
           do i=0,209
              ssa=ssa + real(cd(144+i))**2 + aimag(cd(144+i))**2
              ssb=ssb + real(cd(i))**2 + aimag(cdat(i))**2
           enddo
        
           z2a=dot_product(cw(0:209,imsg),cd(144:353))
           z2b=dot_product(cw(0:65,imsg),cdat(144:209)) +                    &
                dot_product(cw(66:209,imsg),cdat(0:143))
           ssa=sqrt(ssa/210.0)*210.0
           ssb=sqrt(ssb/210.0)*210.0
           r2(imsg)=max(abs(z2a)/ssa,abs(z2b)/ssb)
           if(r2(imsg).gt.r2max) then
              r2max=r2(imsg)
              ibest=imsg
              u2=u1
              u1=r2max
              idfpk=idf
              t2=t
              n=0
              if(imsg.eq.2296 .or. imsg.eq.2302) n=1
!              write(51,3101) t,kk,nrxfreq+idf,ibest,n,    &
!                   r1(j),u1,u2,u2/u1,r1(j)/r2max,idf
!              flush(51)
           endif
        enddo
     enddo

     r1_r2=r1(j)/r2max
!     write(*,3101) t2,kk,nrxfreq+idfpk,ibest,0,    &
!          r1(j),u1,u2,u2/u1,r1(j)/r2max,idfpk
     if(u1.ge.0.71 .and. u2/u1.lt.0.91 .and. r1_r2.lt.1.3) then
        if(u1.gt.u1best) then
           irpt=iand(ibest,7)
           ihash=ibest/8
           narg(13)=ihash
           decoded="<...> "//rpt(irpt)
           tbest=t
           r1best=r1(j)
           u1best=u1
           u2best=u2
           ibest2=ibest
           idfbest=idfpk
           r1_r2best=r1_r2
           nn=0
           if(ihash.eq.narg(12) .and. iand(ibest2,7).eq.0) nn=1
        endif
     endif
!     if(r1best.gt.0.0) write(*,3101) tbest,kk,nrxfreq+idfbest,ibest,nn,    &
!          r1best,u1best,u2best,u2best/u1best,r1_r2best,idfbest
  enddo
!  call timer('kk      ',1)

!  if(r1best.gt.0.0) then
!     write(*,3101) tbest,kk,nrxfreq+idfbest,ibest,nn,r1best,u1best,u2best,   &
!          u2best/u1best,r1_r2best,idfbest
!3101 format(f6.2,4i5,5f8.2,i6)
!  endif

  return
end subroutine jtmsk_short
