program makedate

#ifdef Win32
  use dfport
#endif

  open(10,file='makedate_sub.f90',status='unknown')
  write(10,*) 'subroutine makedate_sub(isec)'
  write(10,*) '!f2py intent(out) isec'
  write(10,*) '  isec=',time()
  write(10,*) '  return'
  write(10,*) 'end subroutine makedate_sub'

end program makedate
      
