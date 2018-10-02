program emedop

  real*8 txfreq8
  real*8 rxfreq8
  real*4 LST
  real*4 lat_a
  real*4 lat_b
  character*80 infile
  character*256 jpleph_file_name
  common/jplcom/jpleph_file_name
  data jpleph_file_name/'JPLEPH'/

  nargs=iargc()
  if(nargs.ne.1) then
     print*,'Usage: emedop <infile>'
     go to 999
  endif

  call getarg(1,infile)
  open(10,file=infile,status='old',err=900)
  read(10,1001) lat_a
1001 format(10x,f12.0)
  read(10,1001) wlon_a
  read(10,1001) lat_b
  read(10,1001) wlon_b
  read(10,1001) txfreq8
  read(10,1002) nyear,month,nday,ih,im,is
1002 format(10x,i4,2i2,1x,i2,1x,i2,1x,i2)
  sec_start=3600.0*ih + 60.0*im + is
  read(10,1002) nyear,month,nday,ih,im,is
  sec_stop=3600.0*ih + 60.0*im + is
  read(10,1001) sec_step

  write(*,1005)
1005 format('  Date       UTC      Tx Freq      Rx Freq    Doppler'/    &
            '------------------------------------------------------')
  
  sec=sec_start
  ncalc=(sec_stop - sec_start)/sec_step

  do icalc=1,ncalc
     uth=sec/3600.0
     call MoonDopJPL(nyear,month,nday,uth,-wlon_a,lat_a,RAMoon,DecMoon,    &
          LST,HA,AzMoon,ElMoon,vr_a,techo)

     call MoonDopJPL(nyear,month,nday,uth,-wlon_b,lat_b,RAMoon,DecMoon,    &
          LST,HA,AzMoon,ElMoon,vr_b,techo)
  
     dop_a=-txfreq8*vr_a/2.99792458e5                 !One-way Doppler from a
     dop_b=-txfreq8*vr_b/2.99792458e5                 !One-way Doppler to b
     doppler=1.e6*(dop_a + dop_b)
     rxfreq8=txfreq8 + dop_a + dop_b

     ih=sec/3600.0
     im=(sec-ih*3600.0)/60.0
     is=nint(mod(sec,60.0))
     write(*,1010) nyear,month,nday,ih,im,is,txFreq8,rxFreq8,doppler
1010 format(i4,2i2.2,2x,i2.2,':',i2.2,':',i2.2,2f13.7,f8.1)

     sec=sec + sec_step
  enddo
  go to 999
900 print*,'Cannot open file ',trim(infile)
999 end program emedop

  

