subroutine jtmsk_short(cdat,npts,msg,decoded)

  parameter (NMAX=15*12000,NSAVE=100)
  character*22 msg,decoded,msgsent
  character*3 rpt(0:7)
  complex cdat(0:npts-1)
  complex cw(0:209,0:4096)                !Waveforms of possible messages
  complex cb11(0:65)                      !Complex waveform of Barker 11
  complex z1,z2a,z2b
  real*8 dt,twopi,freq,phi,dphi0,dphi1,dphi
  real r1(0:NMAX-1)
  real r2(0:4096)
  real r1save(NSAVE)
!  integer*8 count0,count1,clkfreq
  integer itone(234)                      !Message bits
  integer jgood(NSAVE)
  integer indx(NSAVE)
  logical first
  data rpt /'26 ','27 ','28 ','R26','R27','R28','RRR','73 '/
  data first/.true./
  save first,cw,cb11

  if(first) then
     dt=1.d0/12000.d0
     twopi=8.d0*atan(1.d0)
     freq=1500.d0
     dphi0=twopi*(freq-500.d0)*dt              !Phase increment, lower tone
     dphi1=twopi*(freq+500.d0)*dt              !Phase increment, upper tone
     nsym=35                                   !Number of symbols
     nspm=6*nsym                               !Samples per message

     do imsg=0,4096                     !Generate all possible message waveforms
        ichk=0
        if(imsg.lt.4096) ichk=10000+imsg
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
  endif

!  r1thresh=0.40
  r1thresh=0.80
  r2thresh=0.50
  rmax=0.9
  ngood=0
  nbad=0
  maxdecodes=999

!  call system_clock(count0,clkfreq)

  r1max=0.
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

  r2bad=0.
  do kk=1,kmax
     k=indx(kmax+1-kk)
     j=jgood(k)
     if(j.lt.144 .or. j.gt.npts-210) cycle
     u1=0.
     u2=0.
     r2max=0.
     ibest=-1
     do imsg=0,4096
        ssa=0.
        ssb=0.
        do i=0,209
           ssa=ssa + real(cdat(j+i))**2 + aimag(cdat(j+i))**2
           ssb=ssb + real(cdat(j+i-144))**2 + aimag(cdat(j+i-144))**2
        enddo
        z2a=dot_product(cw(0:209,imsg),cdat(j:j+209))
        z2b=dot_product(cw(0:65,imsg),cdat(j:j+65)) +                    &
             dot_product(cw(66:209,imsg),cdat(j-144:j-1))
        ssa=sqrt(ssa/210.0)*210.0
        ssb=sqrt(ssb/210.0)*210.0
        r2(imsg)=max(abs(z2a)/(0.908*ssa),abs(z2b)/(0.908*ssb))
        if(r2(imsg).gt.r2max) then
           r2max=r2(imsg)
           ibest=imsg
           u2=u1
           u1=r2max
        endif
     enddo
     r1or2=r1(j)/r2max
     if(r2max.ge.r2thresh .and. u2/u1.lt.rmax .and. r1or2.ge.0.91) then
        t=j/12000.0
        n=0
        irpt=iand(ibest,7)
        decoded="<...> "//rpt(irpt)
        if(r2max.eq.r2(4096)) then
           n=1
           decoded=msg(1:14)//rpt(irpt)
        endif
        print*,'a ', decoded
        go to 900

!        if(n.eq.0) nbad=nbad+1
!        if(n.eq.1) ngood=ngood+1
!        if(n.eq.0 .and. r2max.gt.r2bad) r2bad=r2max
!        write(52,3020) k,t,ibest,r1(j),r2max,u2/u1,r1or2,n,decoded
!3020    format(i3,f9.4,i5,4f7.2,i2,1x,a22)
!        if(ngood+nbad.ge.maxdecodes) exit
     endif
  enddo

!  print "('Worst false decode:',f6.3)",r2bad
!  print "('Good:',i3,'   Bad:',i3)",ngood,nbad

900 return
end subroutine jtmsk_short
