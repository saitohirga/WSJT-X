subroutine osd300(llr,norder,decoded,niterations,cw)
!
! An ordered-statistics decoder based on ideas from: 
! "Soft-decision decoding of linear block codes based on ordered statistics,"
! by Marc P. C. Fossorier and Shu Lin, 
! IEEE Trans Inf Theory, Vol 41, No 5, Sep 1995
! 

include "ldpc_300_60_params.f90"

integer*1 gen(K,N)
integer*1 genmrb(K,N)
integer*1 temp(K),m0(K),me(0:K)
integer indices(N)
integer*1 codeword(N),cw(N),hdec(N)
integer*1 decoded(K)
integer indx(N)
real llr(N),rx(N),absrx(N)
logical first
data first/.true./

save first,gen

if( first ) then ! fill the generator matrix
  gen=0
  do i=1,M
    do j=1,15
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

! The hard decisions for the K MRB bits define the order 0 message, m0. 
! Encode m0 using the modified generator matrix to find the "order 0" codeword. 
! Flip various combinations of bits in m0 and re-encode to generate a list of
! codewords. Test all such codewords against the received word to decide which
! codeword is most likely to be correct.
hdec=hdec(indices)
m0=hdec(1:K)

nhardmin=N
j0=0
j1=0
j2=0
j3=0
if( norder.ge.4 ) j0=K
if( norder.ge.3 ) j1=K
if( norder.ge.2 ) j2=K
if( norder.ge.1 ) j3=K
! me(0) is a dummy position --- only me(1:K) are actually used. This is done
! to avoid "if" statements within the inner loop.
do i1=0,j0
  do i2=i1,j1
    do i3=i2,j2
      do i4=i3,j3
        me(1:K)=m0
        me(i1)=1-me(i1)
        me(i2)=1-me(i2)
        me(i3)=1-me(i3)
        me(i4)=1-me(i4)

! me is the m0 + error pattern. encode this message using genmrb to
! produce a codeword. test the codeword against the received vector
! and save it if it's the best that we've seen so far. 
        do i=1,N 
          nsum=sum(iand(me(1:K),genmrb(1:K,i)))
          codeword(i)=mod(nsum,2)
        enddo
        nhard=count(codeword .ne. hdec)
        if( nhard .lt. nhardmin ) then
          cw=codeword
          nhardmin=nhard
          i1min=i1
          i2min=i2
          i3min=i3
          i4min=i4
        endif
      enddo
    enddo
  enddo 
enddo
! re-order the codeword to place message bits at the end
cw(indices)=cw
decoded=cw(M+1:N)
niterations=1
return
end subroutine osd300
