#ifndef CABRILLO_LOG_WINDOW_HPP_
#define CABRILLO_LOG_WINDOW_HPP_

#include <QWidget>
#include <QScopedPointer>
#include <QIdentityProxyModel>
#include "models/FontOverrideModel.hpp"

class QSettings;
class Configuration;
class QFont;
class QDateTime;
class QAbstractItemModel;
namespace Ui
{
  class CabrilloLogWindow;
}

class CabrilloLogWindow final
  : public QWidget
{
public:
  explicit CabrilloLogWindow (QSettings *, Configuration const *, QAbstractItemModel * cabrillo_log_model
                         , QWidget * parent = nullptr);
  ~CabrilloLogWindow ();

  void change_font (QFont const&);

private:
  void read_settings ();
  void write_settings () const;

  QSettings * settings_;
  Configuration const * configuration_;
  FontOverrideModel cabrillo_log_model_;
  QScopedPointer<Ui::CabrilloLogWindow> ui_;
};

#endif
