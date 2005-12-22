      subroutine grid2deg(grid,dlong,dlat)

C  Converts Maidenhead grid locator to degrees of West longitude
C  and North latitude.

      character*6 grid
      character*1 g1,g2,g3,g4,g5,g6

      if(grid(5:5).eq.' ') grid(5:6)='mm'
      g1=grid(1:1)
      g2=grid(2:2)
      g3=grid(3:3)
      g4=grid(4:4)
      g5=grid(5:5)
      g6=grid(6:6)

      nlong = 180 - 20*(ichar(g1)-ichar('A'))
      n20d = 2*(ichar(g3)-ichar('0'))
      xminlong = 5*(ichar(g5)-ichar('a')+0.5)
      dlong = nlong - n20d - xminlong/60.0
c      print*,nlong,n20d,xminlong,dlong
      nlat = -90+10*(ichar(g2)-ichar('A')) + ichar(g4)-ichar('0')
      xminlat = 2.5*(ichar(g6)-ichar('a')+0.5)
      dlat = nlat + xminlat/60.0
c      print*,nlat,xminlat,dlat

      return
      end
