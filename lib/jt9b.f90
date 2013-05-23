subroutine jt9b(jt9com,nbytes)

  parameter (NTMAX=120)
  parameter (NSMAX=1365)
  integer*1 jt9com(0:nbytes-1)
  kss=0
  ksavg=kss + 4*184*NSMAX
  kc0=ksavg + 4*NSMAX
  kid2=kc0 + 2*4*NTMAX*1500
  knutc=kid2 + 2*NTMAX*12000
  call jt9c(jt9com(kss),jt9com(ksavg),jt9com(kc0),jt9com(kid2),jt9com(knutc))

  return
end subroutine jt9b
