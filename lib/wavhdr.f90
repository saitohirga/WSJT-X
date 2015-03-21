module wavhdr
  type hdr
     character*4 ariff
     integer*4 lenfile
     character*4 awave
     character*4 afmt
     integer*4 lenfmt
     integer*2 nfmt2
     integer*2 nchan2
     integer*4 nsamrate
     integer*4 nbytesec
     integer*2 nbytesam2
     integer*2 nbitsam2
     character*4 adata
     integer*4 ndata
  end type hdr

  contains

    function default_header(nsamrate,npts)
      type(hdr) default_header,h
      h%ariff='RIFF'
      h%awave='WAVE'
      h%afmt='fmt '
      h%lenfmt=16
      h%nfmt2=1
      h%nchan2=1
      h%nsamrate=nsamrate
      h%nbitsam2=16
      h%nbytesam2=h%nbitsam2 * h%nchan2 / 8
      h%adata='data'
      h%nbytesec=h%nsamrate * h%nbitsam2 * h%nchan2 / 8
      h%ndata=2*npts
      h%lenfile=h%ndata + 44 - 8
      default_header=h
    end function default_header

end module wavhdr
