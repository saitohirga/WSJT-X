#include "AbstractLogWindow.hpp"

#include <QSettings>
#include <QString>
#include <QTableView>
#include <QHeaderView>
#include "Configuration.hpp"
#include "SettingsGroup.hpp"
#include "models/FontOverrideModel.hpp"
#include "pimpl_impl.hpp"

class AbstractLogWindow::impl final
{
public:
  impl (QString const& settings_key, QSettings * settings, Configuration const * configuration)
    : settings_key_ {settings_key}
    , settings_ {settings}
    , configuration_ {configuration}
    , log_view_ {nullptr}
  {
  }

  QString settings_key_;
  QSettings * settings_;
  Configuration const * configuration_;
  QTableView * log_view_;
  FontOverrideModel model_;
};

AbstractLogWindow::AbstractLogWindow (QString const& settings_key, QSettings * settings
                                      , Configuration const * configuration
                                      , QWidget * parent)
  : QWidget {parent}
  , m_ {settings_key, settings, configuration}
{
  // ensure view scrolls to latest new row
  connect (&m_->model_, &QAbstractItemModel::rowsInserted, [this] (QModelIndex const& /*parent*/, int /*first*/, int /*last*/) {
      if (m_->log_view_) m_->log_view_->scrollToBottom ();
    });
}

AbstractLogWindow::~AbstractLogWindow ()
{
  SettingsGroup g {m_->settings_, m_->settings_key_};
  m_->settings_->setValue ("window/geometry", saveGeometry ());
}

void AbstractLogWindow::set_log_model (QAbstractItemModel * log_model)
{
  m_->model_.setSourceModel (log_model);
}

void AbstractLogWindow::set_log_view (QTableView * log_view)
{
  // do this here because we know the UI must be setup before this
  SettingsGroup g {m_->settings_, m_->settings_key_};
  restoreGeometry (m_->settings_->value ("window/geometry").toByteArray ());

  m_->log_view_ = log_view;
  m_->log_view_->setModel (&m_->model_);
  m_->log_view_->setColumnHidden (0, true);
  auto horizontal_header = log_view->horizontalHeader ();
  horizontal_header->setSectionResizeMode (QHeaderView::ResizeToContents);
  horizontal_header->setSectionsMovable (true);
  m_->log_view_->verticalHeader ()->setSectionResizeMode (QHeaderView::ResizeToContents);
  set_log_view_font (m_->configuration_->decoded_text_font ());
  m_->log_view_->scrollToBottom ();
}

void AbstractLogWindow::set_log_view_font (QFont const& font)
{
  // m_->log_view_->setFont (font);
  // m_->log_view_->horizontalHeader ()->setFont (font);
  // m_->log_view_->verticalHeader ()->setFont (font);
  m_->model_.set_font (font);
}
