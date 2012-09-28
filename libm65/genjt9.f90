subroutine genjt9(message,minutes,msgsent,d6)

! Encodes a "JT9-minutes" message and returns array d6(85) of tone
! values in the range 0-8.  

  character*22 message          !Message to be generated
  character*22 msgsent          !Message as it will be received

  integer*4 mettab(0:255,0:1)

  integer*4 d0(13)              !72-bit message as 6-bit words
  integer*1 d1(13)              !72 bits and zero tail as 8-bit bytes
  integer*1 d2(206)             !Encoded information-carrying bits
  integer*1 d3(206)             !Bits from d2, after interleaving
  integer*4 d4(69)              !Symbols from d3, values 0-7
  integer*4 d5(69)              !Gray-coded symbols, values 0-7
  integer*4 d6(85)              !Channel symbols including sync, values 0-8

  integer*4 t0(13)              !72-bit message as 6-bit words
  integer*1 t1(13)              !72 bits and zero tail as 8-bit bytes
  integer*1 t2(206)             !Encoded information-carrying bits
  integer*1 t3(206)             !Bits from d2, after interleaving
  integer*4 t4(69)              !Symbols from d3, values 0-7
  integer*4 t5(69)              !Gray-coded symbols, values 0-7
  integer*4 t6(85)              !Channel symbols including sync, values 0-8
  integer*1 tmp(72)

  integer isync(85)
  data isync/                                    &
       1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,  &
       1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,0,0,0,1,0,  &
       0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,  &
       0,0,1,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,  &
       1,0,0,0,1/
  data twopi/6.283185307179586476d0/
  save

  call packmsg(message,d0)           !Pack message into 12 6-bit bytes
  call unpackmsg(d0,msgsent)
  call entail(d0,d1)
  nsym2=206
  call encode232(d1,nsym2,d2)        !Convolutional code, K=32, r=1/2
  call interleave9(d2,1,d3)
  call packbits(d3,nsym2,3,d4)
  call graycode(d4,69,1,d5)

! Insert sync symbols (ntone=0) and add 1 to the data-tone numbers.
  j=0
  do i=1,85
     if(isync(i).eq.1) then
        d6(i)=0
     else
        j=j+1
        d6(i)=d5(j)+1
     endif
  enddo

  if(j.ne.999) return

  t6=d6
  j=0
  do i=1,85
     if(isync(i).eq.1) cycle
     j=j+1
     t5(j)=t6(i)-1
  enddo

  call graycode(t5,69,-1,t4)
  call unpackbits(t4,nsym2,3,t3)
  call interleave9(t3,-1,t2)
!  print*,'A',d2-t2

! Get the metric table
  bias=0.37
  scale=10                        !Optimize?
  open(19,file='met8.21',status='old')

  do i=0,255
     read(19,*) xjunk,x0,x1
     mettab(i,0)=nint(scale*(x0-bias))
     mettab(i,1)=nint(scale*(x1-bias))    !### Check range, etc.  ###
  enddo
  print*,'b'

  ndelta=17
  ntimeout=0
  limit=1000
  call fano232(t2,72+31,mettab,ndelta,limit,t1,ncycles,metric,ierr)
  print*,t1
!  if(ncycles/(72+31).ge.limit) ntimeout=1
!  nbytes=(nbits+7)/8
!  do i=1,nbytes
!     n=t1(i)
!     t4(i)=iand(n,255)
!  enddo
!  call unpackbits(t1,9,8,tmp)
!  call packbits(tmp,12,6,t0)
!  print*,'z',t0


  return
end subroutine genjt9
