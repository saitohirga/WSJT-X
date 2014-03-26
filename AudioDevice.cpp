#include "AudioDevice.hpp"

#include <QMetaType>

namespace
{
  struct init
  {
    init ()
    {
      qRegisterMetaType<AudioDevice::Channel> ("AudioDevice::Channel");
    }
  } static_initializer;
}

bool AudioDevice::open (OpenMode mode, Channel channel)
{
  m_channel = channel;

  // ensure we are unbuffered
  return QIODevice::open (mode | QIODevice::Unbuffered);
}

