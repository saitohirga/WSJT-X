#ifndef TEST_CONFIGURATION_HPP_
#define TEST_CONFIGURATION_HPP_

#include "pimpl_h.hpp"

class QString;
class QSettings;
class QWidget;

class TestConfiguration final
{
 public:
  explicit TestConfiguration (QString const& instance_key, QSettings *, QWidget * parent = nullptr);
  ~TestConfiguration ();

 private:
  class impl;
  pimpl<impl> m_;
};

#endif
