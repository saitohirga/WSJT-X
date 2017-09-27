subroutine calibrate(app_dir,data_dir)

! Frequency calibration driver routine for WSJT-X
  
  character*(*) app_dir
  character*(*) data_dir
  character*256 fmtave,fcal,infile,avefile,calfile
  character*512 cmnd
  
  fmtave=app_dir//'fmtave'
  fcal=app_dir//'fcal'
  infile=data_dir//'fmt.all'
  avefile=data_dir//'fmtave.out '
  calfile=data_dir//'fcal.out'

  print*,trim(fmtave)
  print*,trim(fcal)
  print*,trim(infile)
  print*,trim(avefile)
  print*,trim(calfile)

  cmnd='"'//trim(fmtave)//' '//trim(infile)//' > '//avefile//'"'
  print*,trim(cmnd)
  call system(trim(cmnd))

  cmnd='"'//trim(fcal)//' '//trim(avefile)//' > '//calfile//'"'
  print*,trim(cmnd)
  call system(trim(cmnd))
  
  return
end subroutine calibrate
