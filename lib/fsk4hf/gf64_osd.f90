subroutine gf64_osd(mrsym,mrprob,mr2sym,mr2prob,cw)
   use jt65_generator_matrix
   integer mrsym(63),mrprob(63),mr2sym(63),mr2prob(63),cw(63)
   integer indx(63)
   integer gmrb(12,63)
   integer correct(63)
   integer correctr(63)
   integer candidate(63)
   integer candidater(63)
   logical mask(63)
   data correct/   &  ! K1ABC W9XYZ EN37
      41,  0, 54, 46, 55, 29, 57, 35, 35, 48, 48, 61,  &
      21, 58, 25, 10, 50, 43, 28, 37, 10,  2, 61, 55,  &
      25,  5,  5, 57, 28, 11, 32, 45, 16, 55, 31, 46,  &
      44, 55, 34, 38, 50, 62, 52, 58, 17, 62, 35, 34,  &
      28, 21, 15, 47, 33, 20, 15, 28, 58,  4, 58, 61,  &
      59, 42,  2/

   correctr=correct(63:1:-1)
   call indexx(mrprob,63,indx)
!   do i=1,63
!     write(*,*) i,correctr(indx(i)),mrsym(indx(i)),mr2sym(indx(i))
!   enddo

   nhard=count(mrsym.ne.correctr)
   nerrtop12=count(mrsym(indx(52:63)).ne.correctr(indx(52:63)))
   nerrnext12=count(mrsym(indx(40:51)).ne.correctr(indx(40:51)))
   write(*,*) 'nerr, nerrtop12, nerrnext12 ',nerr,nerrtop12,nerrnext12

! The best 12 symbols will be used as the Most Reliable Basis
! Reorder the columns of the generator matrix in order of decreasing quality.
   do i=1,63
      gmrb(:,i)=g(:,indx(63+1-i))
   enddo
! Put the generator matrix in standard form so that top 12 symbols are
! encoded systematically.
   call gf64_standardize_genmat(gmrb)

! Add various error patterns to the 12 basis symbols and reencode each one
! to get a list of codewords. For now, just find the zero'th order codeword.
   call gf64_encode(gmrb,mrsym(indx(63:52:-1)),candidate)
! Undo the sorting to put the codeword symbols back into the "right" order.
   candidater=candidate(63:1:-1)
   candidate(indx)=candidater

!write(*,'(63i3)') candidate
!write(*,'(63i3)') correctr
!write(*,'(63i3)') mrsym
   nerr=count(correctr.ne.candidate)
write(*,*) 'Number of differences between candidate and correct codeword: ',nerr
   if( nerr .eq. 0 ) write(*,*) 'Successful decode'
   return
end subroutine gf64_osd

subroutine gf64_standardize_genmat(gmrb)
   use gf64math
   integer gmrb(12,63),temp(63),gkk,gjk,gkkinv
   do k=1,12
      gkk=gmrb(k,k) 
      if(gkk.eq.0) then ! zero pivot - swap with the first row with nonzero value
         do kk=k+1,12
            if(gmrb(kk,k).ne.0) then
               temp=gmrb(k,:)
               gmrb(k,:)=gmrb(kk,:)
               gmrb(kk,:)=temp
               gkk=gmrb(k,k)
               goto 20
            endif
         enddo 
      endif
20    gkkinv=gf64_inverse(gkk)
      do ic=1,63
         gmrb(k,ic)=gf64_product(gmrb(k,ic),gkkinv)
      enddo
      do j=1,12
         if(j.ne.k) then
            gjk=gmrb(j,k)
            do ic=1,63
               gmrb(j,ic)=gf64_sum(gmrb(j,ic),gf64_product(gmrb(k,ic),gjk))
            enddo
         endif
      enddo
   enddo

   return
end subroutine gf64_standardize_genmat

subroutine gf64_encode(gg,message,codeword)
!
! Encoder for a (63,12) Reed-Solomon code.
! The generator matrix is supplied in array gg.
!
   use gf64math
   integer message(12)      !Twelve 6-bit data symbols
   integer codeword(63)     !RS(63,12) codeword
   integer gg(12,63)

   codeword=0
   do j=1,12
      do i=1,63
         iprod=gf64_product(message(j),gg(j,i))
         codeword(i)=gf64_sum(codeword(i),iprod)
      enddo
   enddo

   return
end subroutine gf64_encode

