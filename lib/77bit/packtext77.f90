subroutine packtext77(c13,c71)

  real*16 q
  character*13 c13,w
  character*71 c71
  character*42 c
  data c/' 0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ+-./?'/

  q=0.q0
  w=adjustr(c13)
  do i=1,13
     j=index(c,w(i:i))-1
     if(j.lt.0) j=0
     q=42.q0*q + j
  enddo

  do i=71,1,-1
     c71(i:i)='0'
     n=mod(q,2.q0)
     q=q/2.q0
     if(n.eq.1) then
        c71(i:i)='1'
        q=q-0.q5
     endif
  enddo

  return
end subroutine packtext77
