#ifndef FOX_LOG_WINDOW_HPP_
#define FOX_LOG_WINDOW_HPP_

#include <QWidget>
#include <QScopedPointer>
#include <QIdentityProxyModel>

class QSettings;
class Configuration;
class QFont;
class QDateTime;
class QAbstractItemModel;
namespace Ui
{
  class FoxLogWindow;
}

// fix up font display as header font changes don't currently work
// from views (I think fixed in Qt 5.11.1)
class FontOverrideModel final
  : public QIdentityProxyModel
{
public:
  FontOverrideModel (QObject * parent = nullptr) : QIdentityProxyModel {parent} {}
  void set_font (QFont const& font) {font_ = font;}
  QVariant data (QModelIndex const& index, int role) const override
  {
    if (Qt::FontRole == role) return font_;
    return QIdentityProxyModel::data (index, role);
  }
  QVariant headerData (int section, Qt::Orientation orientation, int role) const override
  {
    if (Qt::FontRole == role) return font_;
    return QIdentityProxyModel::headerData (section, orientation, role);
  }
private:
  QFont font_;
};

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
  void closeEvent (QCloseEvent *) override;

  void read_settings ();
  void write_settings () const;

  QSettings * settings_;
  Configuration const * configuration_;
  FontOverrideModel fox_log_model_;
  QScopedPointer<Ui::FoxLogWindow> ui_;
};

#endif
