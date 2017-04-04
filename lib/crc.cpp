#include <boost/crc.hpp>
#include <boost/cstdint.hpp>

extern "C"
{
   short crc12 (unsigned char const * data, int length);
   bool crc12_check (unsigned char const * data, int length);
   short crc10 (unsigned char const * data, int length);
   bool crc10_check (unsigned char const * data, int length);
}

// assumes CRC is last 16 bits of the data and is set to zero
// caller should assign the returned CRC into the message in big endian byte order
short crc12 (unsigned char const * data, int length)
{
    return boost::augmented_crc<12, 0xc06> (data, length);
}

bool crc12_check (unsigned char const * data, int length)
{
   return !boost::augmented_crc<12, 0xc06> (data, length);
}

short crc10 (unsigned char const * data, int length)
{
    return boost::augmented_crc<10, 0x08f> (data, length);
}

bool crc10_check (unsigned char const * data, int length)
{
   return !boost::augmented_crc<10, 0x08f> (data, length);
}
