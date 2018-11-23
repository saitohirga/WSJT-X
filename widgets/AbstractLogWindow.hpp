#ifndef ABSTRACT_LOG_WINDOW_HPP_
#define ABSTRACT_LOG_WINDOW_HPP_

#include <QWidget>
#include "pimpl_h.hpp"

class QString;
class QSettings;
class Configuration;
class QAbstractItemModel;
class QTableView;
class QFont;

class AbstractLogWindow
  : public QWidget
{
public:
  AbstractLogWindow (QString const& settings_key, QSettings * settings
                     , Configuration const * configuration
                     , QWidget * parent = nullptr);
  virtual ~AbstractLogWindow () = 0;

  void set_log_model (QAbstractItemModel *);
  void set_log_view (QTableView *);
  void set_log_view_font (QFont const&);

private:
  class impl;
  pimpl<impl> m_;
};

#endif
