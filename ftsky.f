      real function ftsky(l,b)

C  Returns 408 MHz sky temperature for l,b (in degrees), from 
C  Haslam, et al. survey.  Must have already read the entire
C  file tsky.dat into memory.

      real*4 l,b
      integer*2 nsky
      common/sky/ nsky(360,180)
      save

      j=nint(b+91.0)
      if(j.gt.180) j=180
      xl=l
      if(xl.lt.0.0) xl=xl+360.0
      i=nint(xl+1.0)
      if(i.gt.360) i=i-360
      ftsky=0.0
      if(i.ge.1 .and. i.le.360 .and. j.ge.1 .and. j.le.180) then
         ftsky=0.1*nsky(i,j)
      endif

      return
      end
