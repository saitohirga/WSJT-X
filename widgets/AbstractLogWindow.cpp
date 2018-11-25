#include "AbstractLogWindow.hpp"

#include <algorithm>
#include <QSettings>
#include <QString>
#include <QTableView>
#include <QHeaderView>
#include <QAction>
#include <QSqlTableModel>
#include <QItemSelectionModel>
#include <QItemSelection>
#include "Configuration.hpp"
#include "SettingsGroup.hpp"
#include "MessageBox.hpp"
#include "models/FontOverrideModel.hpp"
#include "pimpl_impl.hpp"

class AbstractLogWindow::impl final
{
public:
  impl (AbstractLogWindow * self, QString const& settings_key, QSettings * settings
        , Configuration const * configuration)
    : self_ {self}
    , settings_key_ {settings_key}
    , settings_ {settings}
    , configuration_ {configuration}
    , log_view_ {nullptr}
  {
  }

  void delete_QSOs ();

  AbstractLogWindow * self_;
  QString settings_key_;
  QSettings * settings_;
  Configuration const * configuration_;
  QTableView * log_view_;
  FontOverrideModel model_;
};

namespace
{
  bool row_is_higher (QModelIndex const& lhs, QModelIndex const& rhs)
  {
    return lhs.row () > rhs.row ();
  }
}

void AbstractLogWindow::impl::delete_QSOs ()
{
  auto selection_model = log_view_->selectionModel ();
  selection_model->select (selection_model->selection (), QItemSelectionModel::SelectCurrent | QItemSelectionModel::Rows);
  auto row_indexes = selection_model->selectedRows ();

  if (row_indexes.size ()
      && MessageBox::Yes == MessageBox::query_message (self_
                                                       , tr ("Confirm Delete")
                                                       , tr ("Are you sure you want to delete the %n "
                                                             "selected QSO(s) from the log", ""
                                                             , row_indexes.size ())))
    {
      // We must work with source model indexes because we don't want row
      // removes to invalidate model indexes we haven't yet processed. We
      // achieve that by processing them in decending row order.
      for (auto& row_index : row_indexes)
        {
          row_index = model_.mapToSource (row_index);
        }

      // reverse sort by row
      std::sort (row_indexes.begin (), row_indexes.end (), row_is_higher);
      for (auto index : row_indexes)
        {
          auto row = model_.mapFromSource (index).row ();
          model_.removeRow (row);
          self_->log_model_changed ();
        }
    }
}

AbstractLogWindow::AbstractLogWindow (QString const& settings_key, QSettings * settings
                                      , Configuration const * configuration
                                      , QWidget * parent)
  : QWidget {parent}
  , m_ {this, settings_key, settings, configuration}
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

void AbstractLogWindow::set_log_view (QTableView * log_view)
{
  // do this here because we know the UI must be setup before this
  SettingsGroup g {m_->settings_, m_->settings_key_};
  restoreGeometry (m_->settings_->value ("window/geometry").toByteArray ());
  m_->log_view_ = log_view;
  m_->log_view_->setContextMenuPolicy (Qt::ActionsContextMenu);
  m_->log_view_->setAlternatingRowColors (true);
  m_->log_view_->setSelectionBehavior (QAbstractItemView::SelectRows);
  m_->log_view_->setSelectionMode (QAbstractItemView::ExtendedSelection);
  m_->model_.setSourceModel (m_->log_view_->model ());
  m_->log_view_->setModel (&m_->model_);
  m_->log_view_->setColumnHidden (0, true);
  auto horizontal_header = log_view->horizontalHeader ();
  horizontal_header->setSectionResizeMode (QHeaderView::ResizeToContents);
  horizontal_header->setSectionsMovable (true);
  m_->log_view_->verticalHeader ()->setSectionResizeMode (QHeaderView::ResizeToContents);
  set_log_view_font (m_->configuration_->decoded_text_font ());
  m_->log_view_->scrollToBottom ();

  // actions
  auto delete_action = new QAction {tr ("&Delete ..."), m_->log_view_};
  m_->log_view_->insertAction (nullptr, delete_action);
  connect (delete_action, &QAction::triggered, [this] (bool /*checked*/) {
      m_->delete_QSOs ();
    });
}

void AbstractLogWindow::set_log_view_font (QFont const& font)
{
  // m_->log_view_->setFont (font);
  // m_->log_view_->horizontalHeader ()->setFont (font);
  // m_->log_view_->verticalHeader ()->setFont (font);
  m_->model_.set_font (font);
}
