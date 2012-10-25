subroutine packgrid(grid,ng,text)

  parameter (NGBASE=180*180)
  character*4 grid
  logical text

  text=.false.
  if(grid.eq.'    ') go to 90               !Blank grid is OK

  if(grid(1:1).eq.'-') then                 !Test for numerical signal report
     read(grid(2:3),*,err=1,end=1) n        !NB: n is positive
     if(n.lt.1) n=1
     if(n.gt.50) n=50
     if(n.gt.30) then
        call n2grid(-n,grid)                !Very low S/N use locators near -90
        go to 10
     endif
1    ng=NGBASE+1+n
     go to 100
  else if(grid(1:2).eq.'R-') then
     read(grid(3:4),*,err=2,end=2) n
     if(n.lt.1) n=1
     if(n.gt.50) n=50
     if(n.gt.30) then
        call n2grid(-n-20,grid)           !Very low S/N use locators near -90
        go to 10
     endif

2    if(n.eq.0) go to 90
     ng=NGBASE+31+n
     go to 100
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

100 return
end subroutine packgrid

