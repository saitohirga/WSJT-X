program jt65osdtest
!
! Demonstrate some procedures that can be used to implement an ordered-
! statistics decoder for JT65. 
! 1. Test JT65 generator-matrix-based encoding by comparing codewords with 
! those produced by the tried-and-true KA9Q encoder
! 2. Demonstrate how to reconfigure the generator matrix to make an arbitrary
! subset of 12 symbols the systematic symbols, and show that re-encoding using
! the subset of symbols regenerates the original codeword.
!
   use jt65_generator_matrix
   use gf64math
   use packjt

   character*22 message    
   integer m(12),cwka9q(63),cwk9an(63),cwtest(63)
   integer gmrb(12,63)
   data m/61,51,10,42,51,55, 3,29,53,55,58,42/ !"K9AN K1JT -25"

   message="K9AN K1JT RRR"
   call packmsg(message,m,itype,.false.)
   write(*,*) 'Message text: ',message
   write(*,*) 'Message symbols:'
   write(*,'(12i3)') m

! Encode using Karn encoder.
   call rs_encode(m,cwka9q)
   write(*,*) 'KA9Q codeword'
   write(*,'(63i3)') cwka9q 
! Encode using generator matrix.
   call gf64_encode(g,m,cwk9an)
   write(*,*) 'K9AN codeword'
   write(*,'(63i3)') cwk9an 

! The message symbols are the last 12 symbols of the codeword. For this test,
! "pretend" that the symbols at positions 1,3,5,7,9,11,13,15,17,19,21,23 are 
! the best received symbols, i.e. the best symbols are all parity symbols.  
! Reorder columns of the generator matrix so that the best symbols are in front
! and then use Gauss-Jordan elimination to create a generator matrix that
! can be used to re-encode the best 12 symbols, producing the same codeword
! that we started with. 
   gmrb=g
   do i=1,12
      gmrb(1:12,i)=g(1:12,2*i-1)
      gmrb(1:12,i+12)=g(1:12,2*i)
   enddo

   call gf64_standardize_genmat(gmrb)

! Now demonstrate that we can use the revised generator matrix to encode the 12
! best symbols and recover the codeword that we started with.
   m(1:12)=cwk9an(1:23:2)          !Take symbols 1,3,5,...23 as the message 
   call gf64_encode(gmrb,m,cwtest) !reencode using the revised generator matrix
   write(*,*) 'Re-encode using generator matrix reconfigured to use odd-index symbols starting at 1 as the message:'
   write(*,'(12i3)') m 
   write(*,*) 'Re-encoded codeword should be the same as the original codeword:'
   write(*,'(63i3)') cwtest        !This should be the same as the original cw.

end program jt65osdtest
