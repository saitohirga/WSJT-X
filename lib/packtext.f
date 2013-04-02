      subroutine packtext(msg,nc1,nc2,nc3)

      parameter (MASK28=2**28 - 1)
      character*13 msg
      character*42 c
      data c/'0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ +-./?'/

      nc1=0
      nc2=0
      nc3=0

      do i=1,5                                !First 5 characters in nc1
         do j=1,42                            !Get character code
            if(msg(i:i).eq.c(j:j)) go to 10
         enddo
         j=37
 10      j=j-1                                !Codes should start at zero
         nc1=42*nc1 + j
      enddo

      do i=6,10                               !Characters 6-10 in nc2
         do j=1,42                            !Get character code
            if(msg(i:i).eq.c(j:j)) go to 20
         enddo
         j=37
 20      j=j-1                                !Codes should start at zero
         nc2=42*nc2 + j
      enddo

      do i=11,13                              !Characters 11-13 in nc3
         do j=1,42                            !Get character code
            if(msg(i:i).eq.c(j:j)) go to 30
         enddo
         j=37
 30      j=j-1                                !Codes should start at zero
         nc3=42*nc3 + j
      enddo

C  We now have used 17 bits in nc3.  Must move one each to nc1 and nc2.
      nc1=nc1+nc1
      if(iand(nc3,32768).ne.0) nc1=nc1+1
      nc2=nc2+nc2
      if(iand(nc3,65536).ne.0) nc2=nc2+1
      nc3=iand(nc3,32767)

      return
      end
