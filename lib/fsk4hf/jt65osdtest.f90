program jt65osdtest
!
! Test k9an's JT65 encoder by comparing codewords with 
! those produced by the tried-and-true KA9Q encoder
!
   use jt65_generator_matrix
   use gf64math

   integer m(12),cwka9q(63),cwk9an(63),cwtest(63)
   integer gmrb(12,63)
   do i=1,12
      m(i)=i
   enddo
   call rs_encode(m,cwka9q)
   write(*,'(63i3)') cwka9q 
   call gf64_encode(g,m,cwk9an)
   write(*,'(63i3)') cwk9an 

   gmrb=g
   call gf64_standardize_genmat(gmrb)
   do i=1,12
      write(*,'(63i3)') gmrb(i,:)
   enddo

   m(1:12)=cwk9an(1:12)
   call gf64_encode(gmrb,m,cwtest)
   write(*,*) 'Test message:'
   write(*,'(12i3)') m 
   write(*,*) 'Codeword:'
   write(*,'(63i3)') cwtest

end program jt65osdtest
