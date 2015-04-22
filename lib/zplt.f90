subroutine zplt(z,iplt,sync,dtx,nfreq,flip,sync2,nplot,emedelay,dttol,   &
  nfqso,ntol)

  real z(458,65)
  real zz(458,65)
  integer ij(2)
  character*4 lab

  call pctile(z,458*65,84,rms)
  fac=0.05/rms
  z=fac*z
  dtq=0.114286
  df=11025.0/(2.0*2520.0)

  ia=nint((nfqso-ntol)/df) - 273
  if(ia.lt.1) ia=1
  ib=nint((nfqso+ntol)/df) - 273
  if(ib.gt.458) ib=458
  ja=(emedelay+0.8-dttol)/dtq
  if(ja.lt.1) ja=1
  jb=(emedelay+0.8+dttol)/dtq
  if(jb.gt.65) jb=65

  zz=0.
  zz(ia:ib,ja:jb)=z(ia:ib,ja:jb)

  zmin=minval(zz)
  zmax=maxval(zz)
  flip=1.0
  if(abs(zmin).gt.abs(zmax)) flip=-1.0

  ij=maxloc(zz)
  if(flip.lt.0.0) ij=minloc(zz)
  i0=ij(1)
  j0=ij(2)
  nfreq=nint((i0+273)*df)
  dtx=j0*dtq-0.8
!  write(69,3101) ia,ib,ja,jb,ij,dtx,nfreq
!3101 format(6i5,f8.2,i6)

  ia=max(1,i0-72)
  ib=min(458,i0+72)
  sync=16.33*flip*(z(i0,j0) - 0.5*(z(ia,j0)+z(ib,j0)))
  sync2=20.0*flip*z(i0,j0)

  if(nplot.eq.0) go to 900

  zmax=max(abs(zmin),abs(zmax),1.0)
  zmin=-zmax

  do j=1,65
     write(61,1100) j*dtq-0.8,z(i0,j)
1100 format(2f10.3)
  enddo

  do i=1,458
     write(62,1100) (i+273)*df,flip*z(i,j0)
  enddo

  xx=1.5
  yy=7.5 - 3.0*iplt
  width=6.0
  height=2.0
  IP=458
  JP=65
  imax=IP
  jmax=JP

  if(iplt.eq.0) then
     call imopen("testjt4.ps")
     call imfont("Helvetica",16)
     call impalette("BlueRed.pal")
  endif

  call imr4mat_color(z,IP,JP,imax,jmax,zmin,zmax,xx,yy,   &
       width,height,1)
  call imstring("Frequency (Hz)",xx+0.5*width,yy-0.5,2,0)
  dy=0.1
  do i=1,9
     x=xx + 0.1*i*width
     call imyline(x,yy,dy)
     call imyline(x,yy+height,-dy)
  enddo
  do i=1,6
     nf=(i-1)*200 + 600
     write(lab,1020) nf
1020  format(i4)
     x=xx + (i-1)*0.2*width
     call imstring(lab,x,yy-0.25,2,0)
  enddo

  dx=0.1
  do i=0,6
     y=yy + height*(0.8+i)/(65.0*0.114286)
     call imxline(xx,y,dx)
     call imxline(xx+width,y,-dx)
  enddo

  do i=0,6,2
     y=yy + height*(0.8+i)/(65.0*0.114286)
     write(lab,1020) i
     call imstring(lab(4:4),xx-0.15,y-0.08,2,0)
  enddo

  y=yy + height*(3.8)/(65.0*0.114286)
  call imstring("DT", xx-0.5,y     ,2,0)
  call imstring("(s)",xx-0.5,y-0.25,2,0)

  if(iplt.eq.2) call imclose

900 return
end subroutine zplt
