subroutine osd174(llr,apmask,norder,decoded,cw,nhardmin,dmin)
!
! An ordered-statistics decoder for the (174,87) code.
! 
include "ldpc_174_87_params.f90"

integer*1 apmask(N),apmaskr(N)
integer*1 gen(K,N)
integer*1 genmrb(K,N),g2(N,K)
integer*1 temp(K),m0(K),me(K),mi(K)
integer indices(N),nxor(N)
integer*1 cw(N),ce(N),c0(N),hdec(N)
integer*1 decoded(K)
integer indx(N)
real llr(N),rx(N),absrx(N)
logical first
data first/.true./

save first,gen

if( first ) then ! fill the generator matrix
  gen=0
  do i=1,M
    do j=1,22
      read(g(i)(j:j),"(Z1)") istr
        do jj=1, 4 
          irow=(j-1)*4+jj
          if( btest(istr,4-jj) ) gen(irow,i)=1
        enddo
    enddo
  enddo
  do irow=1,K
    gen(irow,M+irow)=1
  enddo
first=.false.
endif

! re-order received vector to place systematic msg bits at the end
rx=llr(colorder+1) 
apmaskr=apmask(colorder+1)


! hard decode the received word
hdec=0            
where(rx .ge. 0) hdec=1

! use magnitude of received symbols as a measure of reliability.
absrx=abs(rx) 
call indexx(absrx,N,indx)  

! re-order the columns of the generator matrix in order of decreasing reliability.
do i=1,N
  genmrb(1:K,i)=gen(1:K,indx(N+1-i))
  indices(i)=indx(N+1-i)
enddo

! do gaussian elimination to create a generator matrix with the most reliable
! received bits in positions 1:K in order of decreasing reliability (more or less). 
! reliability will not be strictly decreasing because column re-ordering is needed
! to put the generator matrix in systematic form. the "indices" array tracks 
! column permutations caused by reliability sorting and gaussian elimination.
do id=1,K ! diagonal element indices 
  do icol=id,K+20  ! The 20 is ad hoc - beware
    iflag=0
    if( genmrb(id,icol) .eq. 1 ) then
      iflag=1
      if( icol .ne. id ) then ! reorder column
        temp(1:K)=genmrb(1:K,id)
        genmrb(1:K,id)=genmrb(1:K,icol)
        genmrb(1:K,icol)=temp(1:K) 
        itmp=indices(id)
        indices(id)=indices(icol)
        indices(icol)=itmp
      endif
      do ii=1,K
        if( ii .ne. id .and. genmrb(ii,id) .eq. 1 ) then
          genmrb(ii,1:N)=mod(genmrb(ii,1:N)+genmrb(id,1:N),2)
        endif
      enddo
      exit
    endif
  enddo
enddo

g2=transpose(genmrb)

! The hard decisions for the K MRB bits define the order 0 message, m0. 
! Encode m0 using the modified generator matrix to find the "order 0" codeword. 
! Flip various combinations of bits in m0 and re-encode to generate a list of
! codewords. Test all such codewords against the received word to decide which
! codeword is most likely to be correct.

hdec=hdec(indices)   ! hard decisions from received symbols
m0=hdec(1:K)         ! zero'th order message
absrx=absrx(indices) 
rx=rx(indices)       
apmaskr=apmaskr(indices)

s1=sum(absrx(1:K))
s2=sum(absrx(K+1:N))
xlam=7.0  ! larger values reject more error patterns 
rho=s1/(s1+xlam*s2)
call mrbencode(m0,c0,g2,N,K)
nxor=ieor(c0,hdec)
nhardmin=sum(nxor)
dmin=sum(nxor*absrx)
thresh=rho*dmin

cw=c0
nt=0
nrejected=0
do iorder=1,norder
  mi(1:K-iorder)=0
  mi(K-iorder+1:K)=1
  iflag=0
  do while(iflag .ge. 0 ) 
    if(all(iand(apmaskr(1:K),mi).eq.0)) then ! reject patterns with ap bits
      dpat=sum(mi*absrx(1:K))
      nt=nt+1
      if( dpat .lt. thresh ) then  ! reject unlikely error patterns
        me=ieor(m0,mi)
        call mrbencode(me,ce,g2,N,K)
        nxor=ieor(ce,hdec)
        dd=sum(nxor*absrx)
        if( dd .lt. dmin ) then
          dmin=dd
          cw=ce
          nhardmin=sum(nxor)
          thresh=rho*dmin
        endif
      else
        nrejected=nrejected+1
      endif
  endif
! get the next test error pattern, iflag will go negative
! when the last pattern with weight iorder has been generated
    call nextpat(mi,k,iorder,iflag)
  enddo
enddo

!write(*,*) 'nhardmin ',nhardmin
!write(*,*) 'total patterns ',nt,' number rejected ',nrejected

! re-order the codeword to place message bits at the end
cw(indices)=cw
hdec(indices)=hdec
decoded=cw(M+1:N)
cw(colorder+1)=cw ! put the codeword back into received-word order
return
end subroutine osd174

subroutine mrbencode(me,codeword,g2,N,K)
integer*1 me(K),codeword(N),g2(N,K)
! fast encoding for low-weight test patterns
  codeword=0
  do i=1,K
    if( me(i) .eq. 1 ) then
      codeword=ieor(codeword,g2(1:N,i))
    endif
  enddo
return
end subroutine mrbencode

subroutine nextpat(mi,k,iorder,iflag)
  integer*1 mi(k),ms(k)
! generate the next test error pattern
  ind=-1
  do i=1,k-1
     if( mi(i).eq.0 .and. mi(i+1).eq.1) ind=i 
  enddo
  if( ind .lt. 0 ) then ! no more patterns of this order
    iflag=ind
    return
  endif
  ms=0
  ms(1:ind-1)=mi(1:ind-1)
  ms(ind)=1
  ms(ind+1)=0
  if( ind+1 .lt. k ) then
     nz=iorder-sum(ms)
     ms(k-nz+1:k)=1
  endif
  mi=ms
  iflag=ind
  return
end subroutine nextpat
