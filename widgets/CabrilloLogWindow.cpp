#include "CabrilloLogWindow.hpp"

#include <QApplication>
#include <QIdentityProxyModel>
#include "Configuration.hpp"
#include "models/Bands.hpp"
#include "item_delegates/ForeignKeyDelegate.hpp"
#include "item_delegates/DateTimeAsSecsSinceEpochDelegate.hpp"
#include "item_delegates/CallsignDelegate.hpp"
#include "pimpl_impl.hpp"

#include "ui_CabrilloLogWindow.h"

namespace
{
  class FormatProxyModel final
    : public QIdentityProxyModel
  {
  public:
    explicit FormatProxyModel (QObject * parent = nullptr)
      : QIdentityProxyModel {parent}
    {
    }

    QVariant data (QModelIndex const& index, int role) const override
    {
      if (Qt::TextAlignmentRole == role && index.isValid ())
        {
          switch (index.column ())
            {
            case 1:
            case 6:
              return Qt::AlignRight + Qt::AlignVCenter;
            default:
              break;
            }
        }
      return QIdentityProxyModel::data (index, role);
    }
  };
}

class CabrilloLogWindow::impl final
{
public:
  explicit impl () = default;
  FormatProxyModel format_model_;
  Ui::CabrilloLogWindow ui_;
};

CabrilloLogWindow::CabrilloLogWindow (QSettings * settings, Configuration const * configuration
                            , QAbstractItemModel * cabrillo_log_model, QWidget * parent)
  : AbstractLogWindow {"Cabrillo Log Window", settings, configuration, parent}
{
  setWindowTitle (QApplication::applicationName () + " - Cabrillo Log");
  m_->ui_.setupUi (this);
  m_->format_model_.setSourceModel (cabrillo_log_model);
  set_log_model (&m_->format_model_);
  set_log_view (m_->ui_.log_table_view);
  m_->ui_.log_table_view->setItemDelegateForColumn (2, new DateTimeAsSecsSinceEpochDelegate {this});
  m_->ui_.log_table_view->setItemDelegateForColumn (3, new CallsignDelegate {this});
  m_->ui_.log_table_view->setItemDelegateForColumn (6, new ForeignKeyDelegate {configuration->bands (), cabrillo_log_model, 0, 6, this});
  m_->ui_.log_table_view->horizontalHeader ()->moveSection (6, 1); // band to first column
}

CabrilloLogWindow::~CabrilloLogWindow ()
{
}
