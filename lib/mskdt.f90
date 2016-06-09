subroutine mskdt(d,npts,ty,yellow,nyel)

  parameter (NFFT=1024,NH=NFFT/2)
  real d(npts)
  real x(0:NFFT-1)
  real green(703)
  real yellow(703)                    !703 = 30*12000/512
  real ty(703)
  real y2(175)
  real ty2(175)
  integer indx(703)
  logical ok
  complex c(0:NH)
  equivalence (x,c)

  df=12000.0/NFFT
  i1=nint(300.0/df)
  i2=nint(800.0/df)
  i3=nint(2200.0/df)
  i4=nint(2700.0/df)
  nblks=npts/NH - 1

  do j=1,nblks
     ib=(j+1)*NH
     ia=ib-NFFT+1
     x=d(ia:ib)
     call four2a(x,NFFT,1,-1,0)             !r2c FFT
     sqlow=0.
     do i=i1,i2
        sqlow=sqlow + real(c(i))**2 + aimag(c(i))**2
     enddo
     sqmid=0.
     do i=i2,i3
        sqmid=sqmid + real(c(i))**2 + aimag(c(i))**2
     enddo
     sqhigh=0.
     do i=i3,i4
        sqhigh=sqhigh + real(c(i))**2 + aimag(c(i))**2
     enddo
     green(j)=db(sqlow+sqmid+sqhigh)
     yellow(j)=db(sqmid/(sqlow+sqhigh))
     ty(j)=j*512.0/12000.0
  enddo

  npct=20
  call pctile(green,nblks,npct,base)
  green(1:nblks)=green(1:nblks) - base - 0.3
  call pctile(yellow,nblks,npct,base)
  yellow(1:nblks)=yellow(1:nblks) - base - 0.6
  call indexx(yellow,nblks,indx)

  do j=1,nblks/4
     k=indx(nblks+1-j)
     ty(j)=ty(k)
     yellow(j)=yellow(k)
     if(yellow(j).lt.1.5) exit
  enddo
  nyel=j-1
  k=1
  y2(1)=yellow(1)
  ty2(1)=ty(1)
  do j=2,nyel
     ok=.true.
     do i=1,j-1
        if(abs(ty(i)-ty(j)).lt.0.117) ok=.false.
     enddo
     if(ok) then
        k=k+1
        y2(k)=yellow(j)
        ty2(k)=ty(j)
     endif
  enddo
  nyel=k
  yellow(1:nyel)=y2(1:nyel)
  ty(1:nyel)=ty2(1:nyel)

  return
end subroutine mskdt
