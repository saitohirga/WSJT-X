      subroutine getpfx1(callsign,k)

      character callsign*12
      character*8 c
      character addpfx*8
      common/gcom4/addpfx              !Can't 'include' *.f90 in *.f 
      include 'pfx.f'

      iz=index(callsign,' ') - 1
      if(iz.lt.0) iz=12
      islash=index(callsign(1:iz),'/')
      k=0
      c='   '
      if(islash.gt.0 .and. islash.le.(iz-4)) then
!  Add-on prefix
         c=callsign(1:islash-1)
         callsign=callsign(islash+1:iz)
         do i=1,NZ
            if(pfx(i)(1:4).eq.c) then
               k=i
               go to 10
            endif
         enddo
         if(addpfx.eq.c) then
            k=449
            go to 10
         endif

      else if(islash.eq.(iz-1)) then
!  Add-on suffix
         c=callsign(islash+1:iz)
         callsign=callsign(1:islash-1)
         do i=1,NZ2
            if(sfx(i).eq.c(1:1)) then
               k=400+i
               go to 10
            endif
         enddo
      endif

 10   if(islash.ne.0 .and.k.eq.0) k=-1
      return
      end

