subroutine fqso_first(nfqso,ntol,ca,ncand)

! If a candidate was found within +/- ntol of nfqso, move it into ca(1).

  type candidate
     real freq
     real dt
     real sync
     real flip
  end type candidate
  type(candidate) ca(300),cb

  dmin=1.e30
  i0=0
  do i=1,ncand
     d=abs(ca(i)%freq-nfqso)
     if(d.lt.dmin) then
        i0=i
        dmin=d
     endif
  enddo

  if(dmin.lt.float(ntol)) then
     cb=ca(i0)
     do i=i0,2,-1
        ca(i)=ca(i-1)
     enddo
     ca(1)=cb
  endif

  return
end subroutine fqso_first
