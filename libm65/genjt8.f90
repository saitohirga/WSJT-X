subroutine genjt8(message,iwave,nwave,nbit,msgsent)

! Generate a JT8 wavefile.

  parameter (NMAX=60*12000)     !Max length of wave file
  character*24 message          !Message to be generated
  character*24 msgsent          !Message as it will be received
  character cmode*5
  real*8 t,dt,phi,f,f0,dfgen,dphi,twopi,tsymbol
  integer*2 iwave(NMAX)         !Generated wave file
  integer iu(3)
  integer gsym(372)             !372 is needed for JT8 mode
  integer sent(144)
  integer ic8(8)
  data ic8/3,6,2,4,5,0,7,1/
  data nsps/4096/
  data twopi/6.283185307d0/
  save

  cmode='JT8'                                   !### temp ? ###
  call srcenc(cmode,message,nbit,iu)
! In JT8 mode, message length is always nbit=78
  if(nbit.ne.78) then
     print*,'genjt8, nbit=',nbit
     stop
  endif

! Apply FEC and do the channel encoding
  call chenc(cmode,nbit,iu,gsym)

! Remove source encoding, recover the human-readable message.
  call srcdec(cmode,nbit,iu,msgsent)

! Insert 8x8 Costas array at beginning and end of array sent().
  sent(1:8)=ic8
  sent(135:142)=ic8
! Insert two symbols after each Costas array to specify message length.
  if(nbit.eq.30) then
     sent(9)=2
     sent(10)=2
     sent(143)=2
     sent(144)=2
  else if(nbit.eq.48) then
     sent(9)=3
     sent(10)=3
     sent(143)=3
     sent(144)=3
  else
     sent(9)=6
     sent(10)=6
     sent(143)=6
     sent(144)=6
  endif

! Insert the 3-bit data symbols
  sent(11:134)=gsym(1:124)

! Use the four free symbols in 30-bit mode
  if(nbit.eq.30) then
     sent(121)=sent(20)
     sent(122)=sent(45)
     sent(123)=sent(70)
     sent(124)=sent(95)
  endif

! Set up necessary constants
  nsym=144
  tsymbol=nsps/12000.d0
  dt=1.d0/12000.d0
  f0=1270.46d0
  dfgen=12000.d0/nsps
  t=0.d0
  phi=0.d0
  k=0
  j0=0
  ndata=(nsym*12000.d0*tsymbol)/2
  ndata=2*ndata
  do i=1,ndata
     t=t+dt
     j=int(t/tsymbol) + 1                    !Symbol number, 1-nsym
     if(j.ne.j0) then
        f=f0
        k=k+1
        if(k.le.144) f=f0+(sent(k))*dfgen         !### Fix need for this ###
        dphi=twopi*dt*f
        j0=j
     endif
     phi=phi+dphi
     iwave(i)=32767.0*sin(phi)
  enddo

  iwave(ndata+1:)=0
  nwave=ndata+6000                          !0.5 s buffer before CW ID

  return
end subroutine genjt8
