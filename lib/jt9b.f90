subroutine jt9b(jt9com,nbytes)

  include 'constants.f90'
  integer*1 jt9com(0:nbytes-1)
  kss=0
  ksavg=kss + 4*184*NSMAX
  kid2=ksavg + 4*NSMAX
  knutc=kid2 + 2*NTMAX*12000
  call jt9c(jt9com(kss),jt9com(ksavg),jt9com(kid2),jt9com(knutc))

  return
end subroutine jt9b
