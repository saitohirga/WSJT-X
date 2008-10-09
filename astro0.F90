!--------------------------------------------------- astro0
subroutine astro0(nyear,month,nday,uth8,nfreq,grid,cauxra,cauxdec,       &
     AzSun8,ElSun8,AzMoon8,ElMoon8,AzMoonB8,ElMoonB8,ntsky,ndop,ndop00,  &
     dbMoon8,RAMoon8,DecMoon8,HA8,Dgrd8,sd8,poloffset8,xnr8,dfdt,dfdt0,  &
     RaAux8,DecAux8,AzAux8,ElAux8)

!f2py intent(in) nyear,month,nday,uth8,nfreq,grid,cauxra,cauxdec
!f2py intent(out) AzSun8,ElSun8,AzMoon8,ElMoon8,AzMoonB8,ElMoonB8,ntsky,ndop,ndop00,dbMoon8,RAMoon8,DecMoon8,HA8,Dgrd8,sd8,poloffset8,xnr8,dfdt,dfdt0,RaAux8,DecAux8,AzAux8,ElAux8

  character grid*6
  character*9 cauxra,cauxdec
  real*8 AzSun8,ElSun8,AzMoon8,ElMoon8,AzMoonB8,ElMoonB8,AzAux8,ElAux8
  real*8 dbMoon8,RAMoon8,DecMoon8,HA8,Dgrd8,xnr8,dfdt,dfdt0
  real*8 sd8,poloffset8
  include 'gcom2.f90'
  data uth8z/0.d0/,imin0/-99/
  save

  auxra=0.
  i=index(cauxra,':')
  if(i.eq.0) then
     read(cauxra,*,err=1,end=1) auxra
  else
     read(cauxra(1:i-1),*,err=1,end=1) ih
     read(cauxra(i+1:i+2),*,err=1,end=1) im
     read(cauxra(i+4:i+5),*,err=1,end=1) is
     auxra=ih + im/60.0 + is/3600.0
  endif
1 auxdec=0.
  i=index(cauxdec,':')
  if(i.eq.0) then
     read(cauxdec,*,err=2,end=2) auxdec
  else
     read(cauxdec(1:i-1),*,err=2,end=2) id
     read(cauxdec(i+1:i+2),*,err=2,end=2) im
     read(cauxdec(i+4:i+5),*,err=2,end=2) is
     auxdec=id + im/60.0 + is/3600.0
  endif

2 nmode=1
  if(mode(1:4).eq.'JT65') then
     nmode=2
     if(mode(5:5).eq.'A') mode65=1
     if(mode(5:5).eq.'B') mode65=2
     if(mode(5:5).eq.'C') mode65=4
  endif
  if(mode.eq.'Echo') nmode=3
  if(mode.eq.'JT6M') nmode=4
  uth=uth8

  call astro(AppDir,nyear,month,nday,uth,nfreq,hisgrid,2,nmode,1,    &
       AzSun,ElSun,AzMoon,ElMoon,ntsky,doppler00,doppler,            &
       dbMoon,RAMoon,DecMoon,HA,Dgrd,sd,poloffset,xnr,auxra,auxdec,  &
       AzAux,ElAux)
  AzMoonB8=AzMoon
  ElMoonB8=ElMoon
  call astro(AppDir,nyear,month,nday,uth,nfreq,grid,1,nmode,1,       &
       AzSun,ElSun,AzMoon,ElMoon,ntsky,doppler00,doppler,            &
       dbMoon,RAMoon,DecMoon,HA,Dgrd,sd,poloffset,xnr,auxra,auxdec,  &
       AzAux,ElAux)

  RaAux8=auxra
  DecAux8=auxdec
  AzSun8=AzSun
  ElSun8=ElSun
  AzMoon8=AzMoon
  ElMoon8=ElMoon
  dbMoon8=dbMoon
  RAMoon8=RAMoon/15.0
  DecMoon8=DecMoon
  HA8=HA
  Dgrd8=Dgrd
  sd8=sd
  poloffset8=poloffset
  xnr8=xnr
  AzAux8=AzAux
  ElAux8=ElAux
  ndop=nint(doppler)
  ndop00=nint(doppler00)

  if(uth8z.eq.0.d0) then
     uth8z=uth8-1.d0/3600.d0
     dopplerz=doppler
     doppler00z=doppler00
  endif
     
  dt=60.0*(uth8-uth8z)
  if(dt.le.0) dt=1.d0/60.d0
  dfdt=(doppler-dopplerz)/dt
  dfdt0=(doppler00-doppler00z)/dt
  uth8z=uth8
  dopplerz=doppler
  doppler00z=doppler00

  imin=60*uth8
  isec=3600*uth8

  if(isec.ne.isec0 .and. ndecoding.eq.0) then
     ih=uth8
     im=mod(imin,60)
     is=mod(isec,60)
     rewind 14
     write(14,1010) ih,im,is,AzMoon,ElMoon,                          &
        ih,im,is,AzSun,ElSun,                                        &
        ih,im,is,AzAux,ElAux,                                        &
        nfreq,doppler,dfdt,doppler00,dfdt0,                          &
        mousefqso,nsetftx
1010 format(i2.2,':',i2.2,':',i2.2,',',f5.1,',',f5.1,',Moon'/        &
            i2.2,':',i2.2,':',i2.2,',',f5.1,',',f5.1,',Sun'/         &
            i2.2,':',i2.2,':',i2.2,',',f5.1,',',f5.1,',Source'/      &
            i4,',',f8.1,',',f8.2,',',f8.1,',',f8.2,',Doppler'/       &
            i4,',',i1,',fQSO')
     call flushqqq(14)
     nsetftx=0
     isec0=isec
  endif

  return
end subroutine astro0
