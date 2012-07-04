subroutine genjtms3(msg,msgsent,iwave,nwave)

  character*22 msg,msgsent
  integer*1 chansym(258)
  integer*2 iwave(30*48000)
  integer dgen(13)
  integer*1 data0(13)                   
  integer*1 datsym(215)
  integer indx0(9)                        !Indices of duplicated data symbols
  data indx0 /16,38,60,82,104,126,148,170,192/

  call packmsg(msg,dgen)                  !Pack message into 12 six-bit symbols
  call entail(dgen,data0)           !Move from 6-bit to 8-bit symbols, add tail
  ndat=(72+31)*2
  call encode232(data0,ndat,datsym)       !Convolutional encoding

  do i=1,9                              !Duplicate 9 symbols at end of datsym
     datsym(206+i)=datsym(indx0(i))
  enddo

  call scr258(isync,datsym,1,chansym)   !Insert sync and data into chansym(258)

  twopi=8.0*atan(1.0)
  f0=1500.0
  dphi=twopi*f0/48000.0
  phi=0.
  k=0
  do j=1,258
     do i=1,24
        phi=phi+dphi
        if(phi.gt.twopi) phi=phi-twopi
        n=32767.0*sin(phi)
        if(chansym(j).eq.0) n=-n
        k=k+1
        iwave(k)=n
     enddo
  enddo
  nwave=k

!  call genjtms3a(chansym,258,iwave,nwave)
  msgsent=msg

  return
end subroutine genjtms3
