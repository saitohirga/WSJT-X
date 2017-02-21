#ifndef PHASE_EQUALIZATION_DIALOG_HPP__
#define PHASE_EQUALIZATION_DIALOG_HPP__

#include <QObject>

#include "pimpl_h.hpp"

class QWidget;
class QSettings;
class QDir;

class PhaseEqualizationDialog
  : public QObject
{
  Q_OBJECT

public:
  explicit PhaseEqualizationDialog (QSettings *
                                    , QDir const& data_directory
                                    , QVector<float> const& coefficients
                                    , QWidget * = nullptr);
  Q_SLOT void show ();

  Q_SIGNAL void phase_equalization_changed (QVector<float> const&);

private:
  class impl;
  pimpl<impl> m_;
};

#endif
