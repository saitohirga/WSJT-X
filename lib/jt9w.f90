program jt9w

  parameter (NSMAX=6827,NZMAX=60*12000)
  real ss(184,NSMAX)
  real ref(NSMAX)
  real ccfred(NSMAX)
  real ccfblue(-9:18)
  real a(5)
  integer*2 id2(NZMAX)
  character*12 arg
  character*22 decoded
  integer*1 i1SoftSymbols(207)

  call getarg(1,arg)
  read(arg,*) iutc

  open(20,file='refspec.dat',status='old')
  do i=1,NSMAX
     read(20,*) j,freq,ref(i)
  enddo

  df=12000.0/16384.0
  nsps=6912
  tstep=nsps*0.5/12000.0
  npts=52*12000
  limit=10000
  ntol=100

  do ifile=1,999
     read(60,end=999) nutc,nfqso,ntol,ndepth,nmode,nsubmode,nzhsym,ss,id2
     if(nutc.ne.iutc) cycle

     ia=nint((nfqso-ntol)/df)
     ib=nint((nfqso+ntol)/df)
     lag1=-int(2.5/tstep + 0.9999)
     lag2=int(5.0/tstep + 0.9999)
     nhsym=184
     do iter=1,2
        nadd=3
        if(iter.eq.2) nadd=2*nint(0.375*a(4)) + 1
        call sync9w(ss,nhsym,lag1,lag2,ia,ib,ccfred,ccfblue,ipk,lagpk,nadd)
        sum1=sum(ccfblue) - ccfblue(lagpk-1)-ccfblue(lagpk) -ccfblue(lagpk+1)
        sq=dot_product(ccfblue,ccfblue) - ccfblue(lagpk-1)**2 - &
             ccfblue(lagpk)**2 - ccfblue(lagpk+1)**2
        base=sum1/25.0
        rms=sqrt(sq/24.0)
        snr=(ccfblue(lagpk)-base)/rms
        nsnr=db(snr)-29.7
        xdt0=lagpk*tstep
        
        call lorentzian(ccfred(ia),ib-ia+1,a)
        f0=(ia+a(3))*df
!        write(*,3001) nadd,a,base,rms,snr,xdt,f0,ipk,lagpk
!3001    format(i3,9f7.2,f7.1,2i5)

        ccfblue=(ccfblue-base)/rms
!        rewind 16
!        do lag=lag1,lag2
!           write(16,3002) lag*tstep,ccfblue(lag)
!3002       format(2f10.3)
!        enddo

     enddo

     call softsym9w(id2,npts,xdt0,f0,a(4)*df,nsubmode,xdt1,i1softsymbols)
     call jt9fano(i1softsymbols,limit,nlim,decoded)
     write(*,1100) nutc,nsnr,xdt1-1.0,nint(f0),decoded,nlim
1100 format(i4.4,i4,f5.1,i5,1x,'@',1x,a22,i10)

  enddo

999 end program jt9w
