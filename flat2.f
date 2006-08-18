      subroutine flat2(ss,n,nsum)

      real ss(2048)
      real ref(2048)
      real tmp(2048)

      nsmo=20
      base=50*(float(nsum)**1.5)
      ia=nsmo+1
      ib=n-nsmo-1
      do i=ia,ib
         call pctile(ss(i-nsmo),tmp,2*nsmo+1,50,ref(i))
      enddo
      call pctile(ref(ia),tmp,ib-ia+1,68,base2)

C  Don't flatten if signal is extremely low (e.g., RX is off).
      if(base2.gt.0.05*base) then
         do i=ia,ib
            ss(i)=base*ss(i)/ref(i)
         enddo
      else
         do i=1,n
            ss(i)=0.
         enddo
      endif

      return
      end
