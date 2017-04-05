#include <boost/crc.hpp>

extern "C"
{
   short crc10 (unsigned char const * data, int length);
   bool crc10_check (unsigned char const * data, int length);
}

namespace
{
  unsigned long constexpr truncated_polynomial = 0x08f;
}

// assumes CRC is last 16 bits of the data and is set to zero
// caller should assign the returned CRC into the message in big endian byte order
short crc10 (unsigned char const * data, int length)
{
    return boost::augmented_crc<10, truncated_polynomial> (data, length);
}

bool crc10_check (unsigned char const * data, int length)
{
   return !boost::augmented_crc<10, truncated_polynomial> (data, length);
}
