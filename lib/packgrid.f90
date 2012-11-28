subroutine packgrid(grid,ng,text)

  parameter (NGBASE=180*180)
  character*4 grid
  character*1 c1
  logical text

  text=.false.
  if(grid.eq.'    ') go to 90               !Blank grid is OK

  n=99
  c1=grid(1:1)
  read(grid,*,err=1) n
  go to 2
1 read(grid(2:4),*,err=2) n
2 if(n.ge.-50 .and. n.le.49) then
     if(c1.eq.'R') then
        write(grid,1002) n+50
1002    format('LA',i2.2)
     else
        write(grid,1003) n+50
1003    format('KA',i2.2)
     endif
     go to 10
  else if(grid(1:2).eq.'RO') then
     ng=NGBASE+62
     go to 100
  else if(grid(1:3).eq.'RRR') then
     ng=NGBASE+63
     go to 100
  else if(grid(1:2).eq.'73') then
     ng=NGBASE+64
     go to 100
  endif

  if(grid(1:1).lt.'A' .or. grid(1:1).gt.'R') text=.true.
  if(grid(2:2).lt.'A' .or. grid(2:2).gt.'R') text=.true.
  if(grid(3:3).lt.'0' .or. grid(3:3).gt.'9') text=.true.
  if(grid(4:4).lt.'0' .or. grid(4:4).gt.'9') text=.true.
  if(text) go to 100

10 call grid2deg(grid//'mm',dlong,dlat)
  long=dlong
  lat=dlat+ 90.0
  ng=((long+180)/2)*180 + lat
  go to 100

90 ng=NGBASE + 1

100 continue
  return
end subroutine packgrid

