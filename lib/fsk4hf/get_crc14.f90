subroutine get_crc14(mc,ncrc)
  
  character c14*14

  integer*1 mc(68),r(15),p(15)
  integer ncrc
! polynomial for 14-bit CRC 0x6757
  data p/1,1,0,0,1,1,1,0,1,0,1,0,1,1,1/
  
! divide by polynomial
  r=mc(1:15)
  do i=0,53
    r(15)=mc(i+15)
    r=mod(r+r(1)*p,2)
    r=cshift(r,1)
  enddo

  write(c14,'(14b1)') r(1:14)
  read(c14,'(b14.14)') ncrc
!  mc(55:68)=r(1:14)

end subroutine get_crc14
