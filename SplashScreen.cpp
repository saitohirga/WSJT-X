#include "SplashScreen.hpp"

#include <QPixmap>
#include <QVBoxLayout>
#include <QCheckBox>
#include <QCoreApplication>

#include "revision_utils.hpp"
#include "pimpl_impl.hpp"

class SplashScreen::impl
{
public:
  impl ()
    : checkbox_ {"Do not show this again"}
  {
    main_layout_.addStretch ();
    main_layout_.addWidget (&checkbox_, 0, Qt::AlignRight);
  }

  QVBoxLayout main_layout_;
  QCheckBox checkbox_;
};

SplashScreen::SplashScreen ()
  : QSplashScreen {QPixmap {":/splash.png"}, Qt::WindowStaysOnTopHint}
{
  setLayout (&m_->main_layout_);
  showMessage ("<h2>" + QString {"Alpha Release: WSJT-X v" +
        QCoreApplication::applicationVersion() + " " +
        revision ()}.simplified () + "</h2>"
    "V1.7 has many new features, most aimed at VHF/UHF/Microwave users.<br />"
    "Some are not yet described in the User Guide and may not be thoroughly<br />"
    "tested. The release notes have more details.<br /><br />"
    "As a test user you have an obligation to report anomalous results<br />"
    "to the development team.  We are particularly interested in tests<br />"
    "of experimental modes QRA64 (intended for EME) and MSK144<br />"
    "(intended for meteor scatter).<br /><br />"
    "Send reports to wsjtgroup@yahoogroups.com, and be sure to save .wav<br />"
    "files where appropriate.<br /><br />"
    "<b>Open the Help menu and select Release Notes for more details.</b><br />"
    "<img src=\":/icon_128x128.png\" />"
    "<img src=\":/gpl-v3-logo.svg\" height=\"80\" />", Qt::AlignCenter);
  connect (&m_->checkbox_, &QCheckBox::stateChanged, [this] (int s) {
      if (Qt::Checked == s) Q_EMIT disabled ();
    });
}

SplashScreen::~SplashScreen ()
{
}
