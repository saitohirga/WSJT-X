program msk32d

  parameter (NZ=15*12000)
  parameter (NSPM=6*32)
  complex c0(0:NZ-1)
  complex c(0:NZ-1)
  complex cmsg(0:NSPM-1,0:31)
  complex z
  real*8 twopi,freq,phi,dphi0,dphi1,dphi
  real a(3)
  real p0(0:NSPM-1)
  real p(0:NSPM-1)
  integer itone(144)
  character*22 msg,msgsent
  character*4 rpt(0:31)
  data rpt /'-04 ','-02 ','+00 ','+02 ','+04 ','+06 ','+08 ','+10 ','+12 ', &
            '+14 ','+16 ','+18 ','+20 ','+22 ','+24 ',                      &
            'R-04','R-02','R+00','R+02','R+04','R+06','R+08','R+10','R+12', &
            'R+14','R+16','R+18','R+20','R+22','R+24',                      &
            'RRR ','73  '/

  twopi=8.d0*atan(1.d0)
  nsym=32
  freq=1500.d0
  dphi0=twopi*(freq-500.d0)/12000.d0
  dphi1=twopi*(freq+500.d0)/12000.d0

  do imsg=0,31
     msg="<K9AN K1JT> "//rpt(imsg)
     ichk=0
     call genmsk32(msg,msgsent,ichk,itone,itype)

     phi=0.d0
     k=0
     do i=1,nsym
        dphi=dphi0
        if(itone(i).eq.1) dphi=dphi1
        do j=1,6
           xphi=phi
           x=cos(xphi)
           y=sin(xphi)
           cmsg(k,imsg)=cmplx(x,y)
           k=k+1
           phi=phi+dphi
           if(phi.gt.twopi) phi=phi-twopi
        enddo
     enddo
  enddo

  read(61) npts,c0(0:npts-1)

  sbest=0.
  do imsg=0,31
!  do idf=-50,50,10
 ! imsg=30
  idf=-5
     a(1)=-idf
     a(2:3)=0.
     call twkfreq(c0,c,npts,12000.0,a)

     smax=0.
     p=0.
     fac=1.0/192
     do j=0,npts-NSPM,2
        z=fac*dot_product(c(j:j+NSPM-1),cmsg(0:NSPM-1,imsg))
        s=real(z)**2 + aimag(z)**2
        k=mod(j,NSPM)
        p(k)=p(k)+s
        if(imsg.eq.30) write(13,1010) j/12000.0,s,k
1010    format(2f12.6,i5)
        if(s.gt.smax) then
           smax=s
           jpk=j
           f0=idf
           if(smax.gt.sbest) then
              sbest=smax
              p0=p
           endif
        endif
     enddo
     write(*,1020) imsg,idf,jpk/12000.0,smax
     write(15,1020) imsg,idf,jpk/12000.0,smax
1020 format(2i6,2f10.2)
  enddo

  imsg=30
   do i=0,NSPM-1,2
      write(14,1030) i,i/12000.0,p0(i)
1030  format(i5,f10.6,f10.3)
   enddo

 end program msk32d
