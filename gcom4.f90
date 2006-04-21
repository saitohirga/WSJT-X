! Variable             Purpose                              Set in Thread
!-------------------------------------------------------------------------
character addpfx*8     !Add-on prefix, as in ZA/PA2CHR           GUI
integer*2 d2c          !Rx data recovered from recorded file     GUI
integer jzc            !Length of data available in d2c          GUI
character filename*24  !Name of wave file read from disk         GUI

common/gcom4/addpfx,d2c(661500),jzc,filename

!### volatile /gcom4/
