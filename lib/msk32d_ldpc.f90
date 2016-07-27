program msk32d

  parameter (NZ=15*12000,NZ0=262144)
  parameter (NSPM=6*32)
  complex c0(0:NZ0-1)
  complex c(0:NZ-1)
  complex cmsg(0:NSPM-1,0:63)
  complex z
  real a(3)
  real p0(0:NSPM-1)
  real p(0:NSPM-1)
  real s0(0:63)
  real dd(NZ)
  integer itone(144)
  integer ihdr(11)
  integer ipk0(1)
  integer*2 id2(NZ)
  character*22 msg,msgsent
  character mycall*8,hiscall*6,arg*12,infile*80,datetime*13
  character*4 rpt(0:63)
  equivalence (ipk0,ipk)

  nargs=iargc()
  if(nargs.lt.5) then
     print*,'Usage:   msk32d Call_1 Call_2 f1   f2   file1 [file2 ...]'
     print*,'Example: msk32d  K9AN   K1JT 1500 1500 fort.61'
     go to 999
  endif
  call getarg(1,mycall)
  call getarg(2,hiscall)
  call getarg(3,arg)
  read(arg,*) nf1
  call getarg(4,arg)
  read(arg,*) nf2
  idf1=nf1-1500
  idf2=nf2-1500

  do i=0,30
    if( i.lt.5 ) then
       write(rpt(i),'(a1,i2.2,a1)') '-',abs(i-5)
       write(rpt(i+31),'(a2,i2.2,a1)') 'R-',abs(i-5)
    else
       write(rpt(i),'(a1,i2.2,a1)') '+',i-5
       write(rpt(i+31),'(a2,i2.2,a1)') 'R+',i-5
    endif
  enddo
  rpt(62)='RRR '
  rpt(63)='73  '

! Generate the test messages
  twopi=8.0*atan(1.0)
  nsym=32
  freq=1500.0
  dphi0=twopi*(freq-500.0)/12000.0
  dphi1=twopi*(freq+500.0)/12000.0
  do imsg=0,63
     i=index(hiscall," ")
     msg="<"//mycall//" "//hiscall(1:i-1)//"> "//rpt(imsg)
     call fmtmsg(msg,iz)
     ichk=0
     call genmsk32(msg,msgsent,ichk,itone,itype)

     phi=0.0
     k=0
     do i=1,nsym
        dphi=dphi0
        if(itone(i).eq.1) dphi=dphi1
        do j=1,6
           x=cos(phi)
           y=sin(phi)
           cmsg(k,imsg)=cmplx(x,y)
           k=k+1
           phi=phi+dphi
           if(phi.gt.twopi) phi=phi-twopi
        enddo
     enddo
  enddo

! Process the specified files
  nfiles=nargs-4
  do ifile=1,nfiles                         !Loop over all files
     call getarg(ifile+4,infile)
     open(10,file=infile,access='stream',status='old')
     read(10) ihdr,id2
     dd=0.03*id2
     npts=NZ
     n=log(float(npts))/log(2.0) + 1.0
     nfft=min(2**n,1024*1024)
     call analytic(dd,npts,nfft,c0)         !Convert to analytic signal
     sbest=0.
     do imsg=0, 63                          !Try all short messages
        do idf=idf1,idf2,10                 !Frequency dither
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
!              if(imsg.eq.30) write(13,1010) j/12000.0,s,k
!1010          format(2f12.6,i5)
              if(s.gt.smax) then
                 smax=s
                 jpk=j
                 f0=idf
                 if(smax.gt.sbest) then
                    sbest=smax
                    p0=p
                    ibest=imsg
                 endif
              endif
           enddo
           s0(imsg)=smax
        enddo
     enddo

     ipk0=maxloc(p0)
     ps=0.
     sq=0.
     ns=0
     pmax=0.
     do i=0,NSPM-1,2
        j=ipk-i
        if(j.gt.96) j=j-192
        if(j.lt.-96) j=j+192
        if(abs(j).gt.4) then
           ps=ps+p0(i)
           sq=sq+p0(i)**2
           ns=ns+1
        endif
     enddo
     avep=ps/ns
     rmsp=sqrt(sq/ns - avep*avep)
     p0=(p0-avep)/rmsp
     p1=maxval(p0)

     do i=0,NSPM-1,2
        write(14,1030) i,i/12000.0,p0(i)
1030    format(i5,f10.6,f10.3)
     enddo

     ave=(sum(s0)-sbest)/31
     s0=s0-ave
     s1=sbest-ave
     s2=0.
     do i=0,63
        if(i.ne.ibest .and. s0(i).gt.s2) s2=s0(i)
        write(15,1020) i,idf,jpk/12000.0,s0(i)
1020    format(2i6,2f10.2)
     enddo

     i=index(infile,".wav")
     datetime=infile(i-13:i-1)
     r1=s1/s2
     r2=r1+p1
     msg="                      "
!     if(r1.gt.2.2 .or. p1.gt.7.0) then
     if(r2.gt.10.0) then
        i=index(hiscall," ")
        msg="<"//mycall//" "//hiscall(1:i-1)//"> "//rpt(ibest)
        call fmtmsg(msg,iz)
     endif
     write(*,1040) datetime,r1,p1,r2,msg
1040 format(a13,3f7.1,2x,a22)
  enddo

999 end program msk32d
