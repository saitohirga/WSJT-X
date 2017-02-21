#include "PhaseEqualizationDialog.hpp"

#include <iterator>
#include <algorithm>
#include <fstream>

#include <QDir>
#include <QVector>
#include <QVBoxLayout>
#include <QDialog>
#include <QDialogButtonBox>
#include <QPushButton>
#include <QFileDialog>
#include <QSettings>

#include "SettingsGroup.hpp"
#include "qcustomplot.h"
#include "pimpl_impl.hpp"

namespace
{
  char const * const title = "Phase Equalization";
  size_t constexpr intervals = 144;

  // plot data loaders - wraps a plot providing value_type and
  // push_back so that a std::back_inserter output iterator can be
  // used to load plot data
  template<typename T>
  struct plot_data_loader
  {
  public:
    typedef T value_type;

    plot_data_loader (QCustomPlot * plot, int graph_index)
      : plot_ {plot}
      , index_ {graph_index }
    {
    }

    // load point into graph
    void push_back (value_type const& d)
    {
      plot_->graph (index_)->data ()->add (d);
    }

  private:
    QCustomPlot * plot_;
    int index_;
  };

  typedef plot_data_loader<QCPGraphData> graph_loader_type;

  // generate points of type T for a 5 term polynomial for x in
  // (-1..+1) with N intervals and function S to scale X
  //
  // it is up to the user to call the generator sufficient times which
  // is interval+1 times to reach +1
  template<typename R, typename T, typename S>
  struct poly_generator
  {
  public:
    poly_generator (QVector<T> const& coeffs, size_t intervals, S scaling = [] (T x) {return x;})
      : x_ {0}
      , intervals_ {intervals}
      , scaling_ {scaling}
      , coeffs_ {coeffs}
    {
    }

    R operator () ()
    {
      T x {x_++ * 2.f / intervals_ - 1.f};
      return {scaling_ (x), coeffs_[0] + x * (coeffs_[1] + x * (coeffs_[2] + x * (coeffs_[3] + x * coeffs_[4])))};
    }

    size_t intervals () const {return intervals_;}

  private:
    int x_;
    size_t intervals_;
    S scaling_;
    QVector<T> coeffs_;
  };

  // make our n=5 polynomial single precision FP generator of
  // QCPGraphData type points with intervals intervals
  template<typename S>
  auto make_poly_generator (QVector<float> const& coeffs, S x_scaling)
    -> poly_generator<QCPGraphData, float, decltype (x_scaling)>
  {
    return poly_generator<QCPGraphData, float, decltype (x_scaling)> {coeffs, intervals, x_scaling};
  }

  // a lambda that scales the X axis appropriately
  auto x_scaling = [] (float x) -> float {return 1500. + 1000 * x;};
}

// read a phase point line from a stream
std::istream& operator >> (std::istream& is, graph_loader_type::value_type& v)
{
  float pp, sigmay;          // discard these
  is >> v.key >> pp >> v.value >> sigmay;
  v.key = 1500. + 1000. * v.key;  // scale frequency to Hz
  return is;
}

class PhaseEqualizationDialog::impl final
  : public QDialog
{
  Q_OBJECT

public:
  explicit impl (PhaseEqualizationDialog * self, QSettings * settings
                 , QDir const& data_directory, QVector<float> const& coefficients
                 , QWidget * parent);
  ~impl () {save_window_state ();}

protected:
  void closeEvent (QCloseEvent * e) override
  {
    save_window_state ();
    QDialog::closeEvent (e);
  }

private:
  void save_window_state ()
  {
    SettingsGroup g (settings_, title);
    settings_->setValue ("geometry", saveGeometry ());
  }

  void plot_current ();
  void plot ();

  PhaseEqualizationDialog * self_;
  QSettings * settings_;
  QDir data_directory_;
  QVBoxLayout layout_;
  QVector<float> current_coefficients_;
  QVector<float> new_coefficients_;
  QCustomPlot plot_;
  QDialogButtonBox button_box_;
};

#include "PhaseEqualizationDialog.moc"

PhaseEqualizationDialog::PhaseEqualizationDialog (QSettings * settings
                                                  , QDir const& data_directory
                                                  , QVector<float> const& coefficients
                                                  , QWidget * parent)
  : m_ {this, settings, data_directory, coefficients, parent}
{
}

void PhaseEqualizationDialog::show ()
{
  m_->show ();
}

PhaseEqualizationDialog::impl::impl (PhaseEqualizationDialog * self
                                     , QSettings * settings
                                     , QDir const& data_directory
                                     , QVector<float> const& coefficients
                                     , QWidget * parent)
  : QDialog {parent}
  , self_ {self}
  , settings_ {settings}
  , data_directory_ {data_directory}
  , current_coefficients_ {coefficients}
  , button_box_ {QDialogButtonBox::Discard | QDialogButtonBox::Apply
        | QDialogButtonBox::RestoreDefaults | QDialogButtonBox::Close}
{
  setWindowTitle (windowTitle () + ' ' + tr (title));
  resize (500, 600);
  {
    SettingsGroup g {settings_, title};
    restoreGeometry (settings_->value ("geometry", saveGeometry ()).toByteArray ());
  }
  layout_.addWidget (&plot_);

  plot_.xAxis->setLabel (tr ("Freq (Hz)"));
  plot_.yAxis->setLabel (tr ("Phase (Radians)"));
  plot_.legend->setVisible (true);
  plot_.setInteractions (QCP::iRangeDrag | QCP::iRangeZoom);
  plot_.axisRect ()->setRangeDrag (Qt::Vertical);
  plot_.axisRect ()->setRangeZoom (Qt::Vertical);

  plot_.addGraph ();
  plot_.graph ()->setName (tr ("Measured"));
  plot_.graph ()->setPen (QPen {Qt::blue});
  plot_.graph ()->setVisible (false);
  plot_.graph ()->removeFromLegend ();

  plot_.addGraph ();
  plot_.graph ()->setName (tr ("Proposed"));
  plot_.graph ()->setPen (QPen {Qt::red});
  plot_.graph ()->setVisible (false);
  plot_.graph ()->removeFromLegend ();

  plot_.addGraph ();
  plot_.graph ()->setName (tr ("Current"));
  plot_.graph ()->setPen (QPen {Qt::green});

  plot_.addGraph ();
  plot_.graph ()->setName (tr ("Current as Used"));
  plot_.graph ()->setPen (QPen {Qt::darkGreen});

  auto load_button = button_box_.addButton (tr ("Load ..."), QDialogButtonBox::ActionRole);
  layout_.addWidget (&button_box_);
  setLayout (&layout_);

  connect (&button_box_, &QDialogButtonBox::rejected, this, &QDialog::reject);
  connect (&button_box_, &QDialogButtonBox::clicked, [this, load_button] (QAbstractButton * button) {
      if (button == load_button)
        {
          plot ();
        }
      else if (button == button_box_.button (QDialogButtonBox::Apply))
        {
          if (plot_.graph (0)->dataCount ()) // something loaded
            {
              current_coefficients_ = new_coefficients_;
              Q_EMIT self_->phase_equalization_changed (current_coefficients_);
              plot_current ();
            }
        }
      else if (button == button_box_.button (QDialogButtonBox::RestoreDefaults))
        {
          current_coefficients_ = QVector<float> {0., 0., 0., 0., 0.};
          Q_EMIT self_->phase_equalization_changed (current_coefficients_);
          plot_current ();
        }
      else if (button == button_box_.button (QDialogButtonBox::Discard))
        {
          new_coefficients_ = QVector<float> {0., 0., 0., 0., 0.};

          plot_.graph (0)->data ()->clear ();
          plot_.graph (0)->setVisible (false);
          plot_.graph (0)->removeFromLegend ();

          plot_.graph (1)->data ()->clear ();
          plot_.graph (1)->setVisible (false);
          plot_.graph (1)->removeFromLegend ();

          plot_.graph (2)->rescaleAxes ();
          plot_.graph (3)->rescaleValueAxis (true);

          plot_.replot ();
        }
    });

  plot_current ();
}

void PhaseEqualizationDialog::impl::plot_current ()
{
  plot_.graph (2)->data ()->clear ();
  plot_.graph (3)->data ()->clear ();
  {
    graph_loader_type graph {&plot_, 2};
    std::generate_n (std::back_inserter (graph), intervals + 1, make_poly_generator (current_coefficients_, x_scaling));
  }
  {
    // plot the adjusted polynomial using only the three high order terms
    graph_loader_type graph {&plot_, 3};
    QVector<float> reduced {current_coefficients_};
    reduced[0] = 0.f;
    reduced[1] = 0.f;
    std::generate_n (std::back_inserter (graph), intervals + 1, make_poly_generator (reduced, x_scaling));
  }
  plot_.graph (2)->rescaleAxes ();
  plot_.graph (3)->rescaleValueAxis (true);
  if (plot_.graph (0)->dataCount ())
    {
      plot_.graph (0)->rescaleValueAxis (true);
      plot_.graph (1)->rescaleValueAxis (true);
    }
  plot_.replot ();
}

void PhaseEqualizationDialog::impl::plot ()
{
  auto const& name = QFileDialog::getOpenFileName (this
                                                   , "Select Phase Response Coefficients"
                                                   , data_directory_.absolutePath ()
                                                   , "Phase Coefficient Files (*.pcoeff)");
  if (name.size ())
    {
      std::ifstream coeffs_source (name.toLatin1 ().constData (), std::ifstream::in);
      int n;
      float chi;
      float rmsdiff;
      // read header information
      coeffs_source >> n >> chi >> rmsdiff;
      {
        std::istream_iterator<float> isi {coeffs_source};
        new_coefficients_.clear ();
        std::copy_n (isi, 5, std::back_inserter (new_coefficients_));
      }

      plot_.graph (0)->data ()->clear ();
      plot_.graph (1)->data ()->clear ();
      {
        // read the phase data to plot into graph 0
        graph_loader_type graph {&plot_, 0};
        std::istream_iterator<graph_loader_type::value_type> start {coeffs_source};
        std::copy_n (start, intervals + 1, std::back_inserter (graph));
      }
      {
        // generate the proposed polynomial plot in graph 1
        graph_loader_type graph {&plot_, 1};
        std::generate_n (std::back_inserter (graph), intervals + 1, make_poly_generator (new_coefficients_, x_scaling));
      }
      plot_.graph (0)->setVisible (true);
      plot_.graph (0)->addToLegend ();
      plot_.graph (0)->rescaleAxes ();

      plot_.graph (1)->setVisible (true);
      plot_.graph (1)->addToLegend ();
      plot_.graph (1)->rescaleValueAxis (true);

      if (plot_.graph (2)->dataCount ())
        {
          plot_.graph (2)->rescaleValueAxis (true);
          plot_.graph (3)->rescaleValueAxis (true);
        }
      plot_.replot ();
    }
}

#include "moc_PhaseEqualizationDialog.cpp"
