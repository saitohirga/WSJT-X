      subroutine indexx(n,arr,indx)

      parameter (NMAX=3000)
      integer indx(n)
      real arr(n)
      real brr(NMAX)
      if(n.gt.NMAX) then
         print*,'n=',n,' too big in indexx.'
         stop
      endif
      do i=1,n
         brr(i)=arr(i)
         indx(i)=i
      enddo
      call ssort(brr,indx,n,2)

      return
      end

