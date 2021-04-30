subroutine ftninit(appd)

  use timer_module, only: timer
  character*(*) appd
  character firstline*30
  character addpfx*8
  common/pfxcom/addpfx

  addpfx='    '
  call pfxdump(appd//'/prefixes.txt')
  open(13,file=appd//'/map65.log',status='unknown')
  open(19,file=appd//'/livecq.txt',status='unknown')
  open(21,file=appd//'/map65_rx.log',status='unknown',access='append',err=950)
  open(26,file=appd//'/tmp26.txt',status='unknown')

! Import FFTW wisdom, if available:
  open(28,file=appd//'/fftwf_wisdom.dat',status='old',err=30)
  read(28,1000,err=30,end=30) firstline
1000 format(a30)
  rewind 28
  call import_wisdom_from_file(isuccess,28)
  close(28)
  if(isuccess.ne.0) write(13,1010) firstline
1010 format('Imported FFTW wisdom: ',a30)

30 flush(13)
  return

920 write(0,*) '!Error opening timer.out'
  stop
950 write(0,*) '!Error opening ALL65.TXT'
  stop

end subroutine ftninit
