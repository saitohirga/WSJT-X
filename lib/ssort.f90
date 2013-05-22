subroutine ssort (x,y,n,kflag)
! Sort an array and optionally make the same interchanges in
!          an auxiliary array.  the array may be sorted in increasing
!          or decreasing order.  a slightly modified quicksort
!          algorithm is used.

! ssort sorts array x and optionally makes the same interchanges in
! array y.  the array x may be sorted in increasing order or
! decreasing order.  a slightly modified quicksort algorithm is used.

! Description of parameters
!    x - array of values to be sorted
!    y - array to be (optionally) carried along
!    n - number of values in array x to be sorted
!    kflag - control parameter
!          =  2  means sort x in increasing order and carry y along.
!          =  1  means sort x in increasing order (ignoring y)
!          = -1  means sort x in decreasing order (ignoring y)
!          = -2  means sort x in decreasing order and carry y along.

  integer kflag, n
  integer x(n), y(n)
  real r
  integer t, tt, tty, ty
  integer i, ij, j, k, kk, l, m, nn
  integer il(21), iu(21)

  nn = n
  if (nn .lt. 1) then
!         print*,'ssort: The number of sort elements is not positive.'
!         print*,'ssort: n = ',nn,'   kflag = ',kflag
     return
  endif

  kk = abs(kflag)
  if (kk.ne.1 .and. kk.ne.2) then
     print *,'the sort control parameter, k, is not 2, 1, -1, or -2.'
     return
  endif

! Alter array x to get decreasing order if needed

  if (kflag .le. -1) then
     do i=1,nn
        x(i) = -x(i)
     enddo
  endif

  if (kk .eq. 2) go to 100

! Sort x only

  m = 1
  i = 1
  j = nn
  r = 0.375e0

20 if (i .eq. j) go to 60
  if (r .le. 0.5898437e0) then
     r = r+3.90625e-2
  else
     r = r-0.21875e0
  endif

30 k = i

! Select a central element of the array and save it in location t

  ij = i + int((j-i)*r)
  t = x(ij)

! If first element of array is greater than t, interchange with t

  if (x(i) .gt. t) then
     x(ij) = x(i)
     x(i) = t
     t = x(ij)
  endif
  l = j

! If last element of array is less than than t, interchange with t
  if (x(j) .lt. t) then
     x(ij) = x(j)
     x(j) = t
     t = x(ij)

! If first element of array is greater than t, interchange with t
     if (x(i) .gt. t) then
        x(ij) = x(i)
        x(i) = t
        t = x(ij)
     endif
  endif

! Find an element in the second half of the array which is smaller than t
40 l = l-1
  if (x(l) .gt. t) go to 40

! Find an element in the first half of the array which is greater than t
50 k = k+1
  if (x(k) .lt. t) go to 50

! Interchange these elements
  if (k .le. l) then
     tt = x(l)
     x(l) = x(k)
     x(k) = tt
     go to 40
  endif

! Save upper and lower subscripts of the array yet to be sorted
  if (l-i .gt. j-k) then
     il(m) = i
     iu(m) = l
     i = k
     m = m+1
  else
     il(m) = k
     iu(m) = j
     j = l
     m = m+1
  endif
  go to 70

! Begin again on another portion of the unsorted array
60 m = m-1
  if (m .eq. 0) go to 190
  i = il(m)
  j = iu(m)

70 if (j-i .ge. 1) go to 30
  if (i .eq. 1) go to 20
  i = i-1

80 i = i+1
  if (i .eq. j) go to 60
  t = x(i+1)
  if (x(i) .le. t) go to 80
  k = i

90 x(k+1) = x(k)
  k = k-1
  if (t .lt. x(k)) go to 90
  x(k+1) = t
  go to 80

! Sort x and carry y along

100 m = 1
  i = 1
  j = nn
  r = 0.375e0

110 if (i .eq. j) go to 150
  if (r .le. 0.5898437e0) then
     r = r+3.90625e-2
  else
     r = r-0.21875e0
  endif

  120 k = i
! Select a central element of the array and save it in location t
  ij = i + int((j-i)*r)
  t = x(ij)
  ty = y(ij)

! If first element of array is greater than t, interchange with t
  if (x(i) .gt. t) then
     x(ij) = x(i)
     x(i) = t
     t = x(ij)
     y(ij) = y(i)
     y(i) = ty
     ty = y(ij)
  endif
  l = j

! If last element of array is less than t, interchange with t
  if (x(j) .lt. t) then
     x(ij) = x(j)
     x(j) = t
     t = x(ij)
     y(ij) = y(j)
     y(j) = ty
     ty = y(ij)

! If first element of array is greater than t, interchange with t
     if (x(i) .gt. t) then
        x(ij) = x(i)
        x(i) = t
        t = x(ij)
        y(ij) = y(i)
        y(i) = ty
        ty = y(ij)
     endif
  endif

! Find an element in the second half of the array which is smaller than t
130 l = l-1
  if (x(l) .gt. t) go to 130

! Find an element in the first half of the array which is greater than t
140 k = k+1
  if (x(k) .lt. t) go to 140

! Interchange these elements
  if (k .le. l) then
     tt = x(l)
     x(l) = x(k)
     x(k) = tt
     tty = y(l)
     y(l) = y(k)
     y(k) = tty
     go to 130
  endif

! Save upper and lower subscripts of the array yet to be sorted
  if (l-i .gt. j-k) then
     il(m) = i
     iu(m) = l
     i = k
     m = m+1
  else
     il(m) = k
     iu(m) = j
     j = l
     m = m+1
  endif
  go to 160

! Begin again on another portion of the unsorted array
150 m = m-1
  if (m .eq. 0) go to 190
  i = il(m)
  j = iu(m)

160 if (j-i .ge. 1) go to 120
  if (i .eq. 1) go to 110
  i = i-1

170 i = i+1
  if (i .eq. j) go to 150
  t = x(i+1)
  ty = y(i+1)
  if (x(i) .le. t) go to 170
  k = i

180 x(k+1) = x(k)
  y(k+1) = y(k)
  k = k-1
  if (t .lt. x(k)) go to 180
  x(k+1) = t
  y(k+1) = ty
  go to 170

! Clean up
190 if (kflag .le. -1) then
     do i=1,nn
        x(i) = -x(i)
     enddo
  endif

  return
end subroutine ssort
