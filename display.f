      subroutine display(nutc)

      parameter (MAXLINES=500)
      integer indx(MAXLINES)
      character*80 line(MAXLINES)
      real freqkHz(MAXLINES)
      integer utc(MAXLINES)
      real*8 f0

      ftol=0.02
      rewind 26

      do i=1,MAXLINES
         read(26,1010,end=10) line(i)
 1010    format(a80)
         read(line(i),1020) f0,ndf,utc(i)
 1020    format(f7.3,i5,26x,i5)
         freqkHz(i)=1000.d0*(f0-144.d0) + 0.001d0*ndf
      enddo

 10   nz=i-1
      call indexx(nz,freqkHz,indx)

      nstart=1
      rewind 24
      write(24,3101) line(indx(1))
 3101 format(a80)
      do i=2,nz
         j0=indx(i-1)
         j=indx(i)
         if(freqkHz(j)-freqkHz(j0).gt.ftol) then
            if(nstart.eq.0) write(24,3101)
            endfile 24
            if(nstart.eq.1) then
!@@@               call sysqqq('sort -k 1.40 fort.24 | uniq > fort.13')
               nstart=0
            else
!@@@               call sysqqq('sort -k 1.40 fort.24 | uniq >> fort.13')
            endif
            rewind 24
         endif
         if(i.eq.nz) write(24,3101)
         write(24,3101) line(j)
         j0=j
      enddo
      endfile 24
!@@@      call sysqqq('sort -k 1.40 fort.24 | uniq >> fort.13')

      return
      end
