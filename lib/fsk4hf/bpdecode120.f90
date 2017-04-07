subroutine bpdecode120(llr,apmask,maxiterations,decoded,niterations,cw)

! A log-domain belief propagation decoder for the (120,60) code.

integer, parameter:: N=120, K=60, M=N-K
integer*1 codeword(N),cw(N),apmask(N)
integer  colorder(N)
integer*1 decoded(K)
integer Nm(7,M)  ! 5, 6, or 7 bits per check 
integer Mn(3,N)  ! 3 checks per bit
integer synd(M)
real tov(3,N)
real toc(7,M)
real tanhtoc(7,M)
real zn(N)
real llr(N)
real Tmn
integer nrw(M)

data colorder/    &
  0,1,2,21,3,4,5,6,7,8,20,10,9,11,12,23,13,28,14,31, &
  15,16,22,26,17,30,18,29,25,32,41,34,19,33,27,36,38,43,42,24, &
  37,39,45,40,35,44,47,46,50,51,53,48,52,56,54,57,55,49,58,61, &
  60,59,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79, &
  80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99, &
  100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119/

data Mn/               &
   1,  18,  48, &
   2,   4,  51, &
   3,  23,  47, &
   5,  36,  42, &
   6,  43,  49, &
   7,  24,  55, &
   8,  35,  60, &
   9,  26,  30, &
  10,  29,  45, &
  11,  13,  46, &
  12,  53,  54, &
  14,  20,  57, &
  15,  16,  58, &
  17,  39,  44, &
  19,  37,  41, &
  21,  28,  34, &
  22,  50,  59, &
  25,  31,  52, &
  27,  32,  38, &
  33,  40,  56, &
   1,  11,  47, &
   2,  10,  16, &
   3,  12,  27, &
   4,  24,  28, &
   5,  23,  60, &
   6,  29,  39, &
   7,  31,  54, &
   8,  50,  56, &
   9,  13,  14, &
  15,  22,  41, &
  17,  26,  40, &
  18,  25,  45, &
  19,  20,  55, &
  21,  30,  36, &
  32,  49,  59, &
  33,  53,  58, &
  34,  38,  46, &
  29,  35,  57, &
  37,  43,  48, &
  42,  51,  52, &
   7,  11,  44, &
   1,  42,  58, &
   2,  13,  49, &
   3,  20,  40, &
   4,  18,  56, &
   5,  45,  55, &
   6,  21,  31, &
   8,  46,  52, &
   9,  12,  48, &
  10,  37,  38, &
  14,  15,  25, &
  16,  17,  60, &
  19,  39,  53, &
  22,  44,  51, &
  23,  28,  41, &
  24,  32,  35, &
  26,  45,  59, &
  27,  33,  36, &
  30,  47,  54, &
  34,  50,  57, &
  33,  43,  55, &
   1,  41,  57, &
   2,  40,  54, &
   3,   6,  24, &
   4,  11,  59, &
   5,  13,  56, &
   7,  16,  34, &
   8,  19,  26, &
   9,  31,  58, &
  10,  21,  53, &
  12,  22,  60, &
  14,  38,  51, &
  15,  43,  46, &
  17,  48,  50, &
  18,  27,  39, &
  20,  28,  44, &
  23,  25,  49, &
   4,  29,  36, &
  30,  32,  52, &
  35,  37,  47, &
  39,  42,  59, &
   1,  21,  40, &
   2,  50,  55, &
   3,   8,  10, &
   5,  31,  37, &
   6,  14,  60, &
   7,  36,  49, &
   9,  34,  39, &
  11,  19,  25, &
  12,  52,  57, &
  13,  22,  29, &
  15,  30,  56, &
  16,  18,  20, &
  17,  24,  46, &
  23,  38,  58, &
  26,  28,  43, &
   2,  27,  41, &
   5,  32,  44, &
  33,  47,  51, &
  35,  48,  53, &
  42,  43,  54, &
  34,  45,  47, &
   1,   8,  49, &
   3,  14,  59, &
   4,  31,  46, &
   6,  20,  50, &
   7,  26,  53, &
   9,  10,  36, &
  11,  58,  60, &
  12,  21,  45, &
  13,  28,  33, &
  15,  17,  35, &
  16,  38,  52, &
  18,  41,  54, &
  19,  23,  32, &
  22,  40,  55, &
  24,  25,  42, &
  26,  27,  56, &
  29,  44,  54, &
  30,  37,  55/

data Nm/               &
   1,  21,  42,  62,  82, 103, 0, &
   2,  22,  43,  63,  83,  97, 0, &
   3,  23,  44,  64,  84, 104, 0, &
   2,  24,  45,  65,  78, 105, 0, &
   4,  25,  46,  66,  85,  98, 0, &
   5,  26,  47,  64,  86, 106, 0, &
   6,  27,  41,  67,  87, 107, 0, &
   7,  28,  48,  68,  84, 103, 0, &
   8,  29,  49,  69,  88, 108, 0, &
   9,  22,  50,  70,  84, 108, 0, &
  10,  21,  41,  65,  89, 109, 0, &
  11,  23,  49,  71,  90, 110, 0, &
  10,  29,  43,  66,  91, 111, 0, &
  12,  29,  51,  72,  86, 104, 0, &
  13,  30,  51,  73,  92, 112, 0, &
  13,  22,  52,  67,  93, 113, 0, &
  14,  31,  52,  74,  94, 112, 0, &
   1,  32,  45,  75,  93, 114, 0, &
  15,  33,  53,  68,  89, 115, 0, &
  12,  33,  44,  76,  93, 106, 0, &
  16,  34,  47,  70,  82, 110, 0, &
  17,  30,  54,  71,  91, 116, 0, &
   3,  25,  55,  77,  95, 115, 0, &
   6,  24,  56,  64,  94, 117, 0, &
  18,  32,  51,  77,  89, 117, 0, &
   8,  31,  57,  68,  96, 107, 118, &
  19,  23,  58,  75,  97, 118, 0, &
  16,  24,  55,  76,  96, 111, 0, &
   9,  26,  38,  78,  91, 119, 0, &
   8,  34,  59,  79,  92, 120, 0, &
  18,  27,  47,  69,  85, 105, 0, &
  19,  35,  56,  79,  98, 115, 0, &
  20,  36,  58,  61,  99, 111, 0, &
  16,  37,  60,  67,  88, 102, 0, &
   7,  38,  56,  80, 100, 112, 0, &
   4,  34,  58,  78,  87, 108, 0, &
  15,  39,  50,  80,  85, 120, 0, &
  19,  37,  50,  72,  95, 113, 0, &
  14,  26,  53,  75,  81,  88, 0, &
  20,  31,  44,  63,  82, 116, 0, &
  15,  30,  55,  62,  97, 114, 0, &
   4,  40,  42,  81, 101, 117, 0, &
   5,  39,  61,  73,  96, 101, 0, &
  14,  41,  54,  76,  98, 119, 0, &
   9,  32,  46,  57, 102, 110, 0, &
  10,  37,  48,  73,  94, 105, 0, &
   3,  21,  59,  80,  99, 102, 0, &
   1,  39,  49,  74, 100, 0,   0, &
   5,  35,  43,  77,  87, 103, 0, &
  17,  28,  60,  74,  83, 106, 0, &
   2,  40,  54,  72,  99, 0,   0, &
  18,  40,  48,  79,  90, 113, 0, &
  11,  36,  53,  70, 100, 107, 0, &
  11,  27,  59,  63, 101, 114, 119, &
   6,  33,  46,  61,  83, 116, 120, &
  20,  28,  45,  66,  92, 118, 0, &
  12,  38,  60,  62,  90, 0,   0, &
  13,  36,  42,  69,  95, 109, 0, &
  17,  35,  57,  65,  81, 104, 0, &
   7,  25,  52,  71,  86, 109, 0/

data nrw/   &
6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6, &
6,6,6,6,6,7,6,6,6,6,6,6,6,6,6,6,6,6,6,6, &
6,6,6,6,6,6,6,5,6,6,5,6,6,7,7,6,5,6,6,6/ 

ncw=3

toc=0
tov=0
tanhtoc=0
!write(*,*) llr
! initialize messages to checks
do j=1,M
  do i=1,nrw(j)
    toc(i,j)=llr((Nm(i,j)))
  enddo
enddo

ncnt=0

do iter=0,maxiterations

! Update bit log likelihood ratios (tov=0 in iteration 0).
  do i=1,N
    if( apmask(i) .ne. 1 ) then
      zn(i)=llr(i)+sum(tov(1:ncw,i))
    else
      zn(i)=llr(i)
    endif
  enddo

! Check to see if we have a codeword (check before we do any iteration).
  cw=0
  where( zn .gt. 0. ) cw=1
  ncheck=0
  do i=1,M
    synd(i)=sum(cw(Nm(1:nrw(i),i)))
    if( mod(synd(i),2) .ne. 0 ) ncheck=ncheck+1
!    if( mod(synd(i),2) .ne. 0 ) write(*,*) 'check ',i,' unsatisfied'
  enddo
!write(*,*) 'number of unsatisfied parity checks ',ncheck
  if( ncheck .eq. 0 ) then ! we have a codeword - reorder the columns and return it
    niterations=iter
    codeword=cw(colorder+1)
    decoded=codeword(M+1:N)
    return
  endif

  if( iter.gt.0 ) then  ! this code block implements an early stopping criterion
    nd=ncheck-nclast
    if( nd .lt. 0 ) then ! # of unsatisfied parity checks decreased
      ncnt=0  ! reset counter
    else
      ncnt=ncnt+1
    endif
!    write(*,*) iter,ncheck,nd,ncnt
    if( ncnt .ge. 3 .and. iter .ge. 5 .and. ncheck .gt. 10) then
      niterations=-1
      return
    endif
  endif
  nclast=ncheck

! Send messages from bits to check nodes 
  do j=1,M
    do i=1,nrw(j)
      ibj=Nm(i,j)
      toc(i,j)=zn(ibj)  
      do kk=1,ncw ! subtract off what the bit had received from the check
        if( Mn(kk,ibj) .eq. j ) then  
          toc(i,j)=toc(i,j)-tov(kk,ibj)
        endif
      enddo
    enddo
  enddo

! send messages from check nodes to variable nodes
  do i=1,M
    tanhtoc(1:7,i)=tanh(-toc(1:7,i)/2)
  enddo

  do j=1,N
    do i=1,ncw
      ichk=Mn(i,j)  ! Mn(:,j) are the checks that include bit j
      Tmn=product(tanhtoc(1:nrw(ichk),ichk),mask=Nm(1:nrw(ichk),ichk).ne.j)
      call platanh(-Tmn,y)
!      y=atanh(-Tmn)
      tov(i,j)=2*y
    enddo
  enddo

enddo
niterations=-1
return
end subroutine bpdecode120
