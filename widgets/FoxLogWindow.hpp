#ifndef FOX_LOG_WINDOW_HPP_
#define FOX_LOG_WINDOW_HPP_

#include "AbstractLogWindow.hpp"
#include "pimpl_h.hpp"

class QSettings;
class Configuration;
class QFont;
class QAbstractItemModel;

class FoxLogWindow final
  : public AbstractLogWindow
{
public:
  explicit FoxLogWindow (QSettings *, Configuration const *, QAbstractItemModel * fox_log_model
                         , QWidget * parent = nullptr);
  ~FoxLogWindow ();

  void callers (int);
  void queued (int);
  void rate (int);

private:
  class impl;
  pimpl<impl> m_;
};

#endif
