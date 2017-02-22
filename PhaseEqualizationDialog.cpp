#include "PhaseEqualizationDialog.hpp"

#include <iterator>
#include <algorithm>
#include <fstream>
#include <limits>
#include <cmath>

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
  float constexpr PI = 3.1415927f;
  char const * const title = "Phase Equalization";
  size_t constexpr intervals = 144;

  // plot data loaders - wraps a plot providing value_type and
  // push_back so that a std::back_inserter output iterator can be
  // used to load plot data
  template<typename T, typename A>
  struct plot_data_loader
  {
  public:
    typedef T value_type;

    // the adjust argument is a function that is passed the plot
    // pointer, the graph index and a data point, it returns a
    // possibly adjusted data point and can modify the graph including
    // adding extra points or gaps (quiet_NaN)
    plot_data_loader (QCustomPlot * plot, int graph_index, A adjust)
      : plot_ {plot}
      , index_ {graph_index}
      , adjust_ (adjust)
    {
    }

    // load point into graph
    void push_back (value_type const& d)
    {
      plot_->graph (index_)->data ()->add (adjust_ (plot_, index_, d));
    }

  private:
    QCustomPlot * plot_;
    int index_;
    A adjust_;
  };
  // helper function template to make a plot_data_loader instance
  template<typename A>
  auto make_plot_data_loader (QCustomPlot * plot, int index, A adjust)
    -> plot_data_loader<QCPGraphData, decltype (adjust)>
  {
    return plot_data_loader<QCPGraphData, decltype (adjust)> {plot, index, adjust};
  }
  // identity adjust function when none is needed in the above
  // instantiation helper
  QCPGraphData adjust_identity (QCustomPlot *, int, QCPGraphData const& v) {return v;}

  // a plot_data_loader adjustment function that wraps Y values of
  // (-1..+1) plotting discontinuities as gaps in the graph data
  auto wrap_pi = [] (QCustomPlot * plot, int index, QCPGraphData d) 
  {
    double constexpr limit {1};
    static unsigned wrap_count {0};
    static double last_x {std::numeric_limits<double>::lowest ()};

    d.value += 2 * limit * wrap_count;
    if (d.value > limit)
      {
        // insert a gap in the graph
        plot->graph (index)->data ()->add ({last_x + (d.key - last_x) / 2
              , std::numeric_limits<double>::quiet_NaN ()});
        while (d.value > limit)
          {
            --wrap_count;
            d.value -= 2 * limit;
          }
      }
    else if (d.value < -limit)
      {
        // insert a gap into the graph
        plot->graph (index)->data ()->add ({last_x + (d.key - last_x) / 2
              , std::numeric_limits<double>::quiet_NaN ()});
        while (d.value < -limit)
          {
            ++wrap_count;
            d.value += 2 * limit;
          }
      }
    last_x = d.key;
    return d;
  };

  // generate points of type R from a function of type F for X in
  // (-1..+1) with N intervals and function of type SX to scale X and
  // of type SY to scale Y
  //
  // it is up to the user to call the generator sufficient times which
  // is interval+1 times to reach +1
  template<typename R, typename F, typename SX, typename SY>
  struct graph_generator
  {
  public:
    graph_generator (F f, size_t intervals, SX x_scaling, SY y_scaling)
      : x_ {0}
      , f_ (f)
      , intervals_ {intervals}
      , x_scaling_ (x_scaling)
      , y_scaling_ (y_scaling)
    {
    }

    R operator () ()
    {
      typename F::value_type x {x_++ * 2.f / intervals_ - 1.f};
      return {x_scaling_ (x), y_scaling_ (f_ (x))};
    }

  private:
    int x_;
    F f_;
    size_t intervals_;
    SX x_scaling_;
    SY y_scaling_;
  };
  // helper function template to make a graph_generator instance for
  // QCPGraphData type points with intervals intervals
  template<typename F, typename SX, typename SY>
  auto make_graph_generator (F function, SX x_scaling, SY y_scaling)
    -> graph_generator<QCPGraphData, F, decltype (x_scaling), decltype (y_scaling)>
  {
    return graph_generator<QCPGraphData, F, decltype (x_scaling), decltype (y_scaling)>
      {function, intervals, x_scaling, y_scaling};
  }

  // template function object for a polynomial with coefficients
  template<typename C>
  class polynomial
  {
  public:
    typedef typename C::value_type value_type;

    explicit polynomial (C const& coefficients)
      : c_ {coefficients}
    {
    }

    value_type operator () (value_type const& x)
    {
      value_type y {};
      for (typename C::size_type i = c_.size (); i > 0; --i)
        {
          y = c_[i - 1] + x * y;
        }
      return y;
    }

  private:
    C c_;
  };
  // helper function template to instantiate a polynomial instance
  template<typename C>
  auto make_polynomial (C const& coefficients) -> polynomial<C>
  {
    return polynomial<C> (coefficients);
  }

  // template function object for a group delay with coefficients
  template<typename C>
  class group_delay
  {
  public:
    typedef typename C::value_type value_type;

    explicit group_delay (C const& coefficients)
      : c_ {coefficients}
    {
    }

    value_type operator () (value_type const& x)
    {
      value_type tau {};
      for (typename C::size_type i = 2; i < c_.size (); ++i)
        {
          tau += i * c_[i] * std::pow (x, i - 1);
        }
      return -1 / (2 * PI) * tau;
    }

  private:
    C c_;
  };
  // helper function template to instantiate a group_delay function
  // object
  template<typename C>
  auto make_group_delay (C const& coefficients) -> group_delay<C>
  {
    return group_delay<C> (coefficients);
  }

  // handy identity function
  template<typename T> T identity (T const& v) {return v;}

  // a lambda that scales the X axis from normalized to (500..2500)Hz
  auto freq_scaling = [] (float v) -> float {return 1500.f + 1000.f * v;};

  // a lambda that scales the phase Y axis from radians to units of Pi
  auto pi_scaling = [] (float v) -> float {return v / PI;};
}

// read a phase point line from a stream (pcoeff file)
std::istream& operator >> (std::istream& is, QCPGraphData& v)
{
  float pp, sigmay;          // discard these
  is >> v.key >> pp >> v.value >> sigmay;
  v.key = 1500. + 1000. * v.key;  // scale frequency to Hz
  v.value /= PI;                  // scale to units of Pi
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
  plot_.xAxis->setRange (500, 2500);
  plot_.yAxis->setLabel (tr ("Phase (Π)"));
  plot_.yAxis->setRange (-1, +1);
  plot_.yAxis2->setLabel (tr ("Delay (ms)"));
  plot_.axisRect ()->setRangeDrag (Qt::Vertical);
  plot_.axisRect ()->setRangeZoom (Qt::Vertical);
  plot_.yAxis2->setVisible (true);
  plot_.axisRect ()->setRangeDragAxes (0, plot_.yAxis2);
  plot_.axisRect ()->setRangeZoomAxes (0, plot_.yAxis2);
  plot_.axisRect ()->insetLayout ()->setInsetAlignment (0, Qt::AlignBottom|Qt::AlignRight);
  plot_.legend->setVisible (true);
  plot_.setInteractions (QCP::iRangeDrag | QCP::iRangeZoom | QCP::iSelectPlottables);

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

  plot_.addGraph (plot_.xAxis, plot_.yAxis2);
  plot_.graph ()->setName (tr ("Group Delay"));
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
    // plot the current polynomial
    auto graph = make_plot_data_loader (&plot_, 2, wrap_pi);
    std::generate_n (std::back_inserter (graph), intervals + 1
                     , make_graph_generator (make_polynomial (current_coefficients_), freq_scaling, pi_scaling));
  }
  {
    // plot the group delay for the current polynomial
    auto graph = make_plot_data_loader (&plot_, 3, adjust_identity);
    std::generate_n (std::back_inserter (graph), intervals + 1
                     , make_graph_generator (make_group_delay (current_coefficients_), freq_scaling, identity<float>));
    plot_.graph (3)->rescaleValueAxis ();
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
        auto graph = make_plot_data_loader (&plot_, 0, adjust_identity);
        std::istream_iterator<QCPGraphData> start {coeffs_source};
        std::copy_n (start, intervals + 1, std::back_inserter (graph));
      }
      {
        // generate the proposed polynomial plot in graph 1
        auto graph = make_plot_data_loader (&plot_, 1, wrap_pi);
        std::generate_n (std::back_inserter (graph), intervals + 1
                         , make_graph_generator (make_polynomial (new_coefficients_), freq_scaling, pi_scaling));
      }
      plot_.graph (0)->setVisible (true);
      plot_.graph (0)->addToLegend ();

      plot_.graph (1)->setVisible (true);
      plot_.graph (1)->addToLegend ();

      plot_.replot ();
    }
}

#include "moc_PhaseEqualizationDialog.cpp"
