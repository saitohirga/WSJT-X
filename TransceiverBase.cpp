#include "TransceiverBase.hpp"

#include <exception>

#include <QString>
#include <QTimer>
#include <QThread>
#include <QDebug>

namespace
{
  auto const unexpected = TransceiverBase::tr ("Unexpected rig error");
}

void TransceiverBase::start () noexcept
{
  QString message;
  try
    {
      if (state_.online ())
        {
          try
            {
              // try and ensure PTT isn't left set
              do_ptt (false);
              do_post_ptt (false);
            }
          catch (...)
            {
              // don't care about exceptions
            }
          do_stop ();
          do_post_stop ();
        }
      do_start ();
      do_post_start ();
      state_.online (true);
    }
  catch (std::exception const& e)
    {
      message = e.what ();
    }
  catch (...)
    {
      message = unexpected;
    }
  if (!message.isEmpty ())
    {
      offline (message);
    }
}

void TransceiverBase::stop () noexcept
{
  QString message;
  try
    {
      if (state_.online ())
        {
          try
            {
              // try and ensure PTT isn't left set
              do_ptt (false);
              do_post_ptt (false);
            }
          catch (...)
            {
              // don't care about exceptions
            }
        }
      do_stop ();
      do_post_stop ();
      state_.online (false);
    }
  catch (std::exception const& e)
    {
      message = e.what ();
    }
  catch (...)
    {
      message = unexpected;
    }
  if (!message.isEmpty ())
    {
      offline (message);
    }
  else
    {
      Q_EMIT finished ();
    }
}

void TransceiverBase::frequency (Frequency f, MODE m) noexcept
{
  QString message;
  try
    {
      if (state_.online ())
        {
          do_frequency (f, m);
          do_post_frequency (f, m);
        }
    }
  catch (std::exception const& e)
    {
      message = e.what ();
    }
  catch (...)
    {
      message = unexpected;
    }
  if (!message.isEmpty ())
    {
      offline (message);
    }
}

void TransceiverBase::tx_frequency (Frequency tx, bool rationalise_mode) noexcept
{
  QString message;
  try
    {
      if (state_.online ())
        {
          do_tx_frequency (tx, rationalise_mode);
          do_post_tx_frequency (tx, rationalise_mode);
        }
    }
  catch (std::exception const& e)
    {
      message = e.what ();
    }
  catch (...)
    {
      message = unexpected;
    }
  if (!message.isEmpty ())
    {
      offline (message);
    }
}

void TransceiverBase::mode (MODE m, bool rationalise) noexcept
{
  QString message;
  try
    {
      if (state_.online ())
        {
          do_mode (m, rationalise);
          do_post_mode (m, rationalise);
        }
    }
  catch (std::exception const& e)
    {
      message = e.what ();
    }
  catch (...)
    {
      message = unexpected;
    }
  if (!message.isEmpty ())
    {
      offline (message);
    }
}

void TransceiverBase::ptt (bool on) noexcept
{
  QString message;
  try
    {
      if (state_.online ())
        {
          do_ptt (on);
          do_post_ptt (on);
        }
    }
  catch (std::exception const& e)
    {
      message = e.what ();
    }
  catch (...)
    {
      message = unexpected;
    }
  if (!message.isEmpty ())
    {
      offline (message);
    }
}

void TransceiverBase::sync (bool force_signal) noexcept
{
  QString message;
  try
    {
      if (state_.online ())
        {
          do_sync (force_signal);
        }
    }
  catch (std::exception const& e)
    {
      message = e.what ();
    }
  catch (...)
    {
      message = unexpected;
    }
  if (!message.isEmpty ())
    {
      offline (message);
    }
}

void TransceiverBase::update_rx_frequency (Frequency rx)
{
  state_.frequency (rx);
}

void TransceiverBase::update_other_frequency (Frequency tx)
{
  state_.tx_frequency (tx);
}

void TransceiverBase::update_split (bool state)
{
  state_.split (state);
}

void TransceiverBase::update_mode (MODE m)
{
  state_.mode (m);
}

void TransceiverBase::update_PTT (bool state)
{
  auto prior = state_.ptt ();
  state_.ptt (state);
  if (state != prior)
    {
      // always signal PTT changes because some MainWindow logic
      // depends on it
      update_complete ();
    }
}

void TransceiverBase::updated ()
  {
    if (do_pre_update ())
      {
        Q_EMIT update (state_);
      }
  }

void TransceiverBase::update_complete ()
{
  // Use a timer to ensure that the calling function completes before
  // the Transceiver::update signal is triggered.
  QTimer::singleShot (0, this, SLOT (updated ()));
}

void TransceiverBase::offline (QString const& reason)
{
  QString message;
  try
    {
      if (state_.online ())
        {
          try
            {
              // try and ensure PTT isn't left set
              do_ptt (false);
              do_post_ptt (false);
            }
          catch (...)
            {
              // don't care about exceptions
            }
        }
      do_stop ();
      do_post_stop ();
      state_.online (false);
    }
  catch (std::exception const& e)
    {
      message = e.what ();
    }
  catch (...)
    {
      message = unexpected;
    }
  Q_EMIT failure (reason + '\n' + message);
}
