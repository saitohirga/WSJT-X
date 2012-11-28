subroutine packgrid(grid,ng,text)

  parameter (NGBASE=180*180)
  character*4 grid
  character*1 c1
  logical text

  text=.false.
  if(grid.eq.'    ') go to 90               !Blank grid is OK

! First, handle signal reports in the original range, -01 to -30 dB
  if(grid(1:1).eq.'-') then
     read(grid(2:3),*,err=800,end=800) n
     if(n.ge.1 .and. n.le.30) then
        ng=NGBASE+1+n
        go to 900
     endif
     go to 10
  else if(grid(1:2).eq.'R-') then
     read(grid(3:4),*,err=800,end=800) n
     if(n.ge.1 .and. n.le.30) then
        ng=NGBASE+31+n
        go to 900
     endif
     go to 10
! Now check for RO, RRR, or 73 in the message field normally used for grid
  else if(grid(1:4).eq.'RO  ') then
     ng=NGBASE+62
     go to 900
  else if(grid(1:4).eq.'RRR ') then
     ng=NGBASE+63
     go to 900
  else if(grid(1:4).eq.'73  ') then
     ng=NGBASE+64
     go to 900
  endif

! Now check for extended-range signal reports: -50 to -31, and 0 to +49.
10 n=99
  c1=grid(1:1)
  read(grid,*,err=20) n
  go to 30
20 read(grid(2:4),*,err=30) n
30 if(n.ge.-50 .and. n.le.49) then
     if(c1.eq.'R') then
        write(grid,1002) n+50
1002    format('LA',i2.2)
     else
        write(grid,1003) n+50
1003    format('KA',i2.2)
     endif
     go to 40
  endif

! Maybe it's free text ?
  if(grid(1:1).lt.'A' .or. grid(1:1).gt.'R') text=.true.
  if(grid(2:2).lt.'A' .or. grid(2:2).gt.'R') text=.true.
  if(grid(3:3).lt.'0' .or. grid(3:3).gt.'9') text=.true.
  if(grid(4:4).lt.'0' .or. grid(4:4).gt.'9') text=.true.
  if(text) go to 900

! OK, we have a properly formatted grid locator
40 call grid2deg(grid//'mm',dlong,dlat)
  long=dlong
  lat=dlat+ 90.0
  ng=((long+180)/2)*180 + lat
  go to 900

90 ng=NGBASE + 1
  go to 900

800 text=.true.
900 continue

  return
end subroutine packgrid
