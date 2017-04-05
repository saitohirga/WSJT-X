#include <boost/crc.hpp>

extern "C"
{
   short crc12 (unsigned char const * data, int length);
   bool crc12_check (unsigned char const * data, int length);
}

namespace
{
  unsigned long constexpr truncated_polynomial = 0xc06;
}

// assumes CRC is last 16 bits of the data and is set to zero
// caller should assign the returned CRC into the message in big endian byte order
short crc12 (unsigned char const * data, int length)
{
    return boost::augmented_crc<12, truncated_polynomial> (data, length);
}

bool crc12_check (unsigned char const * data, int length)
{
   return !boost::augmented_crc<12, truncated_polynomial> (data, length);
}
