#include "DecodeHighlightingListView.hpp"

#include <QAction>
#include <QColorDialog>

#include "models/DecodeHighlightingModel.hpp"
#include "MessageBox.hpp"

#include "pimpl_impl.hpp"

class DecodeHighlightingListView::impl final
{
public:
  impl ()
    : fg_colour_action_ {tr ("&Foreground color ..."), nullptr}
    , bg_colour_action_ {tr ("&Background color ..."), nullptr}
    , defaults_action_ {tr ("&Reset this item to defaults"), nullptr}
  {
  }

  DecodeHighlightingListView * self_;
  QAction fg_colour_action_;
  QAction bg_colour_action_;
  QAction defaults_action_;
};

DecodeHighlightingListView::DecodeHighlightingListView (QWidget * parent)
  : QListView {parent}
{
  addAction (&m_->fg_colour_action_);
  addAction (&m_->bg_colour_action_);
  addAction (&m_->defaults_action_);
  connect (&m_->fg_colour_action_, &QAction::triggered, [this] (bool /*checked*/) {
      auto const& index = currentIndex ();
      auto colour = QColorDialog::getColor (model ()->data (index, Qt::ForegroundRole).value<QBrush> ().color ()
                                            , this
                                            , tr ("Choose %1 Foreground Color")
                                                .arg (model ()->data (index).toString ()));
      if (colour.isValid ())
        {
          model ()->setData (index, colour, Qt::ForegroundRole);
        }
    });
  connect (&m_->bg_colour_action_, &QAction::triggered, [this] (bool /*checked*/) {
      auto const& index = currentIndex ();
      auto colour = QColorDialog::getColor (model ()->data (index, Qt::BackgroundRole).value<QBrush> ().color ()
                                            , this
                                            , tr ("Choose %1 Background Color")
                                                .arg (model ()->data (index).toString ()));
      if (colour.isValid ())
        {
          model ()->setData (index, colour, Qt::BackgroundRole);
        }
    });
  connect (&m_->defaults_action_, &QAction::triggered, [this] (bool /*checked*/) {
      auto const& index = currentIndex ();
      model ()->setData (index, model ()->data (index, DecodeHighlightingModel::EnabledDefaultRole).toBool () ? Qt::Checked : Qt::Unchecked, Qt::CheckStateRole);
      model ()->setData (index, model ()->data (index, DecodeHighlightingModel::ForegroundDefaultRole), Qt::ForegroundRole);
      model ()->setData (index, model ()->data (index, DecodeHighlightingModel::BackgroundDefaultRole), Qt::BackgroundRole);
    });
}

DecodeHighlightingListView::~DecodeHighlightingListView ()
{
}

QSize DecodeHighlightingListView::sizeHint () const
{
  auto item_height = sizeHintForRow (0);
  if (item_height >= 0)
    {
      // set the height hint to exactly the space required for all the
      // items
      return {width (), (model ()->rowCount () * (item_height + 2 * spacing ())) + 2 * frameWidth ()};
    }
  return QListView::sizeHint ();
}
