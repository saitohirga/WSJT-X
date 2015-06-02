subroutine astrosub(nyear,month,nday,uth8,freq8,mygrid,hisgrid,          &
     AzSun8,ElSun8,AzMoon8,ElMoon8,AzMoonB8,ElMoonB8,ntsky,ndop,ndop00,  &
     RAMoon8,DecMoon8,Dgrd8,poloffset8,xnr8,techo8,width1,width2,bTx,    &
     AzElFileName,jpleph)

  implicit real*8 (a-h,o-z)
  character*6 mygrid,hisgrid,c1*1
  character*6 AzElFileName*(*),jpleph*(*)
  character*80 jpleph_file_name
  logical*1 bTx
  common/jplcom/jpleph_file_name

  jpleph_file_name=jpleph

  call astro0(nyear,month,nday,uth8,freq8,mygrid,hisgrid,                &
     AzSun8,ElSun8,AzMoon8,ElMoon8,AzMoonB8,ElMoonB8,ntsky,ndop,ndop00,  &
     dbMoon8,RAMoon8,DecMoon8,HA8,Dgrd8,sd8,poloffset8,xnr8,dfdt,dfdt0,  &
     width1,width2,xlst8,techo8)

  imin=60*uth8
  isec=3600*uth8
  ih=uth8
  im=mod(imin,60)
  is=mod(isec,60)
  open(15,file=AzElFileName,status='unknown',err=900)
  c1='R'
  nRx=1
  if(bTx) then
     c1='T'
     nRx=0
  endif
  AzAux=0.
  ElAux=0.
  nfreq=freq8/1000000
  doppler=ndop
  doppler00=ndop00
  write(15,1010,err=10) ih,im,is,AzMoon8,ElMoon8,                     &
       ih,im,is,AzSun8,ElSun8,                                        &
       ih,im,is,AzAux,ElAux,                                          &
       nfreq,doppler,dfdt,doppler00,dfdt0,c1
!       TXFirst,TRPeriod,poloffset,Dgrd,xnr,ave,rms,nRx
1010 format(                                                          &
      i2.2,':',i2.2,':',i2.2,',',f5.1,',',f5.1,',Moon'/               &
      i2.2,':',i2.2,':',i2.2,',',f5.1,',',f5.1,',Sun'/                &
      i2.2,':',i2.2,':',i2.2,',',f5.1,',',f5.1,',Source'/             &
      i5,',',f8.1,',',f8.2,',',f8.1,',',f8.2,',Doppler, ',a1)
!      i1,',',i3,',',f8.1,','f8.1,',',f8.1,',',f12.3,',',f12.3,',',i1,',RPol')
10 close(15)
  go to 999

900 print*,'Error opening azel.dat'

999 return  
end subroutine astrosub
