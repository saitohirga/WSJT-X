subroutine genmet24(mode,mettab)

! Return appropriate metric table for soft-decision convolutional decoder.

  real bias                         !bias for integer table
  integer scale                     !scale factor for integer table
! Metric table (RxSymbol,TxSymbol)
  integer mettab(0:255,0:1)

  bias=0.5
  scale=10
  if(mode.eq.7) then  !Non-coherent 2FSK
     open(19,file='dmet_10_-1_3.dat',status='old')
  else
     print*,'Unsupported mode:',mode,' in genmet.'
     stop 'genmet'
  endif

  do i=0,255
     read(19,*) junk,d0,d1
     mettab(i,0)=nint(scale*(d0-bias))
     mettab(i,1)=nint(scale*(d1-bias))
  enddo

  return
end subroutine genmet24

