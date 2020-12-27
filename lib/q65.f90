module q65

  parameter (MAXAVE=64)
  integer nsave,nlist,LL0
  integer iutc(MAXAVE)
  integer iseq(MAXAVE)
  integer listutc(10)
  real    f0save(MAXAVE)
  real    xdtsave(MAXAVE)
  real    snr1save(MAXAVE)
  real,allocatable :: s3save(:,:,:)
  real,allocatable :: s3avg(:,:)

end module q65
