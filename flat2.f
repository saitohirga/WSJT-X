      subroutine flat2(ss,n,nsum)

      real ss(1024)
      real ref(1024)
      real tmp(1024)

      nsmo=20
      base=50*(float(nsum)**1.5)
      ia=nsmo+1
      ib=n-nsmo-1
      do i=ia,ib
         call pctile(ss(i-nsmo),tmp,2*nsmo+1,50,ref(i))
      enddo
      call pctile(ref(ia),tmp,ib-ia+1,50,base2)

      if(base2.gt.0.1*base) then
         do i=ia,ib
            ss(i)=base*ss(i)/ref(i)
         enddo
      endif

      return
      end
