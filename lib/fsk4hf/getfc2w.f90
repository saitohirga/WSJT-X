subroutine getfc2w(c,csync,npeaks,fs,fc1,fpks)

  include 'wsprlf_params.f90'

  complex c(0:NZ-1)                     !Complex waveform
  complex cs(0:NZ-1)                    !For computing spectrum
  complex csync(0:NZ-1)                 !Sync symbols only, from cbb
  real a(5)
  real freqs(413),sp2(413),fpks(npeaks)
  integer pkloc(1)

  df=fs/NZ
  baud=fs/NSPS
  a(1)=-fc1
  a(2:5)=0.
  call twkfreq1(c,NZ,fs,a,cs)         !Mix down by fc1

! Filter, square, then FFT to get refined carrier frequency fc2.
  call four2a(cs,NZ,1,-1,1)          !To freq domain

  ia=nint(0.75*baud/df) 
  cs(ia:NZ-1-ia)=0.                  !Save only freqs around fc1
  call four2a(cs,NZ,1,1,1)           !Back to time domain
  cs=cs/NZ
  cs=cs*cs                           !Square the data
  call four2a(cs,NZ,1,-1,1)          !Compute squared spectrum

! Find two peaks separated by baud
  pmax=0.
  fc2=0.
  ja=nint(0.3*baud/df)
  k=1
  do j=-ja,ja
     f2=j*df
     ia=nint((f2-0.5*baud)/df)
     if(ia.lt.0) ia=ia+NZ
     ib=nint((f2+0.5*baud)/df)
     p=real(cs(ia))**2 + aimag(cs(ia))**2 +                        &
          real(cs(ib))**2 + aimag(cs(ib))**2           
     if(p.gt.pmax) then
        pmax=p
        fc2=0.5*f2
     endif
     freqs(k)=0.5*f2
     sp2(k)=p
     k=k+1
!           write(52,1200) f2,p,db(p)
!1200       format(f10.3,2f15.3)
  enddo

  do i=1,npeaks
    pkloc=maxloc(sp2)
    ipk=pkloc(1)
    fpks(i)=freqs(ipk)
    ipk0=max(1,ipk-1)
    ipk1=min(413,ipk+1)
!    ipk0=ipk
!    ipk1=ipk
    sp2(ipk0:ipk1)=0.0
!write(*,*) i,fpks(i),fc2
  enddo
 
  a(1)=-fc1
  a(2:5)=0.
  call twkfreq1(c,NZ,fs,a,cs)         !Mix down by fc1
  cs=cs*conjg(csync)
  call four2a(cs,NZ,1,-1,1)          !To freq domain
  pmax=0.
  do i=0,NZ-1
     f=i*df
     if(i.gt.NZ/2) f=(i-NZ)*df
     p=real(cs(i))**2 + aimag(cs(i))**2
!     write(51,3001) f,p,db(p)
!3001 format(f10.3,e12.3,f10.3)
     if(p.gt.pmax) then
        pmax=p
        fc3=f
     endif
  enddo
  
  return
end subroutine getfc2w
