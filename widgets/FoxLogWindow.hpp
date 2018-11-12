#ifndef FOX_LOG_WINDOW_HPP_
#define FOX_LOG_WINDOW_HPP_

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
  class FoxLogWindow;
}

class FoxLogWindow final
  : public QWidget
{
public:
  explicit FoxLogWindow (QSettings *, Configuration const *, QAbstractItemModel * fox_log_model
                         , QWidget * parent = nullptr);
  ~FoxLogWindow ();

  void change_font (QFont const&);
  void callers (int);
  void queued (int);
  void rate (int);

private:
  void read_settings ();
  void write_settings () const;

  QSettings * settings_;
  Configuration const * configuration_;
  FontOverrideModel fox_log_model_;
  QScopedPointer<Ui::FoxLogWindow> ui_;
};

#endif
