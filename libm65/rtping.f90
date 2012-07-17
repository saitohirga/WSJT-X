subroutine rtping(dat,k,cfile6,MinSigdB,MouseDF,ntol)

!subroutine rtping(dat,jz,nz,MinSigdB,MinWidth,NFreeze,DFTolerance,    &
!     MouseDF,istart,pick,cfile6,mycall,hiscall,mode,ps0)

! Decode Multi-Tone FSK441 mesages.

  parameter (NSMAX=30*48000)
  parameter (NZMAX=NSMAX/2048)
  real dat(NSMAX)                !Raw audio data
  logical pick
  character*6 cfile6
  real sig(NZMAX)                !Sq-law detected signal, sampled at 43 ms
  real sigdb(NZMAX)              !Signal in dB, sampled at 43 ms
  real work(NZMAX)
  real pingdat(3,100)
!  character msg*40,msg3*3
  character*90 line
  common/ccom/nline,tping(100),line(100)
  data nping0/0/
  save

  slim=MinSigdB
!  nf1=-ntol
!  nf2=ntol
  dt=1.0/48000.0
  kstep=2048
!  pick=.false.
  istart=1
  jz=k

! Find signal power
  j=k/kstep
  sig(j)=dot_product(dat(k-kstep+1:k),dat(k-kstep+1:k))/kstep
  if(j.lt.10) return

! Remove baseline, compute signal level in dB 
  call pctile (sig,work,j,50,base1)
  do i=1,j
     sigdb(i)=db(sig(i)/base1)
     if(j.eq.703) write(13,3001) i,sig(i),sigdb(i)
3001 format(i5,2e12.3)
  enddo

  dtbuf=kstep*dt
  wmin=0.040
  call ping(sigdb,j,dtbuf,slim,wmin,pingdat,nping)

! If this is a "mouse pick" and no ping was found, force a pseudo-ping 
! at center of data.
!  if(pick.and.nping.eq.0) then
!     if(nping.le.99) nping=nping+1
!     pingdat(1,nping)=0.5*jz*dt
!     pingdat(2,nping)=0.16
!     pingdat(3,nping)=1.0
!  endif

  do iping=1,nping
! Find starting place and length of data to be analyzed:
     tstart=pingdat(1,iping)
     width=pingdat(2,iping)
     peak=pingdat(3,iping)
!     mswidth=10*nint(100.0*width)
     jj=(tstart-0.02)/dt
     if(jj.lt.1) jj=1
     jjz=nint((width+0.02)/dt)+1
     jjz=min(jjz,jz+1-jj)

! Compute average spectrum of this ping.
!     call spec441(dat(jj),jjz,ps,f0)

! Decode the message.
!     msg=' '
!     call longx(dat(jj),jjz,ps,DFTolerance,noffset,msg,msglen,bauderr)

! Assemble a signal report:
     nwidth=0
     if(width.ge.0.04) nwidth=1     !These might depend on NSPD
     if(width.ge.0.12) nwidth=2
     if(width.gt.1.00) nwidth=3
     nstrength=6
     if(peak.ge.11.0) nstrength=7
     if(peak.ge.17.0) nstrength=8
     if(peak.ge.23.0) nstrength=9
!     nrpt=10*nwidth + nstrength
     t2=tstart + dt*(istart-1)

     jjzz=min(jjz,2*48000)       !Max data size 2 s 
!###
     jjzz=14400
     jj=jj-200
!###

     if(nping.gt.nping0) then
        print*,'a',jj,jjzz,jj*dt,jjzz*dt,t2,width
        call jtmsk(dat(jj),jjzz,cfile6,t2,mswidth,int(peak),nrpt,      &
             nfreeze,DFTolerance,MouseDF,pick)
        nping0=nping
     endif
  enddo

  return
end subroutine rtping
