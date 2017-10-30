module gf64math
! Basic math in GF(64), for JT65 and QRA64

   implicit none
   integer :: gf64exp(0:62),gf64log(0:63)

!  gf64exp: GF(64) decimal representation, indexed by logarithm
   data gf64exp/                                             &
            1,   2,   4,   8,  16,  32,   3,   6,  12,  24,  &
           48,  35,   5,  10,  20,  40,  19,  38,  15,  30,  &
           60,  59,  53,  41,  17,  34,   7,  14,  28,  56,  &
           51,  37,   9,  18,  36,  11,  22,  44,  27,  54,  &
           47,  29,  58,  55,  45,  25,  50,  39,  13,  26,  &
           52,  43,  21,  42,  23,  46,  31,  62,  63,  61,  &
           57,  49,  33/

!  logarithms of GF(64) elements, indexed by decimal representation
   data gf64log/                                              &
          -1,   0,   1,   6,   2,  12,   7,  26,   3,  32,   &
          13,  35,   8,  48,  27,  18,   4,  24,  33,  16,   &
          14,  52,  36,  54,   9,  45,  49,  38,  28,  41,   &
          19,  56,   5,  62,  25,  11,  34,  31,  17,  47,   &
          15,  23,  53,  51,  37,  44,  55,  40,  10,  61,   &
          46,  30,  50,  22,  39,  43,  29,  60,  42,  21,   &
          20,  59,  57,  58/

   contains

! Product of two GF(64) field elements
      function gf64_product(i1,i2)
         integer, intent(in) :: i1,i2
         integer :: gf64_product
         if(i1.ne.0.and.i2.ne.0) then
            gf64_product=gf64exp(mod(gf64log(i1)+gf64log(i2),63))
         else
            gf64_product=0
         endif
      end function gf64_product

! Inverse of a GF(64) field element for arguments in [1,63]. Undefined otherwise. 
      function gf64_inverse(i1)
         integer, intent(in) :: i1
         integer :: gf64_inverse
         if(i1.gt.1) then
            gf64_inverse=gf64exp(63-gf64log(i1)) 
         else 
            gf64_inverse=1
         endif
      end function gf64_inverse

! Sum two GF(64) field elements
      function gf64_sum(i1,i2)
         integer, intent(in) :: i1,i2
         integer :: gf64_sum
         gf64_sum=ieor(i1,i2)
      end function gf64_sum

end module gf64math

