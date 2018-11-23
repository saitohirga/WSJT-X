#ifndef CABRILLO_LOG_WINDOW_HPP_
#define CABRILLO_LOG_WINDOW_HPP_

#include "AbstractLogWindow.hpp"
#include "pimpl_h.hpp"

class QSettings;
class Configuration;
class QFont;
class QAbstractItemModel;

class CabrilloLogWindow final
  : public AbstractLogWindow
{
public:
  explicit CabrilloLogWindow (QSettings *, Configuration const *, QAbstractItemModel * cabrillo_log_model
                              , QWidget * parent = nullptr);
  ~CabrilloLogWindow ();

private:
  class impl;
  pimpl<impl> m_;
};

#endif
