      subroutine getpfx1(callsign,k)

      character callsign*12
      character*4 c
      include 'pfx.f'

      iz=index(callsign,' ') - 1
      islash=index(callsign(1:iz),'/')
      k=0
      c='   '
      if(islash.gt.0 .and. (islash.le.4 .or. (islash.eq.5 .and.
     +    iz.ge.8))) then
         c=callsign(1:islash-1)
         callsign=callsign(islash+1:iz)
         do i=1,NZ
            if(pfx(i)(1:4).eq.c) then
               k=i
               go to 10
            endif
         enddo

      else if(islash.gt.5 .or. (islash.eq.5 .and. iz.eq.6)) then
         c=callsign(islash+1:iz)
         callsign=callsign(1:islash-1)
         do i=1,NZ2
            if(sfx(i).eq.c(1:1)) then
               k=400+i
               go to 10
            endif
         enddo
      endif

 10   continue
      if(islash.ne.0 .and.k.eq.0) k=-1
c      print*,iz,islash,k,' ',c
     
      return
      end

