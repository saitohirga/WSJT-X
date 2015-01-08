#include "EmulateSplitTransceiver.hpp"

EmulateSplitTransceiver::EmulateSplitTransceiver (std::unique_ptr<Transceiver> wrapped)
  : wrapped_ {std::move (wrapped)}
  , frequency_ {0, 0}
  , pre_tx_frequency_ {0}
  , tx_ {false}
{
  // Connect update signal of wrapped Transceiver object instance to ours.
  connect (wrapped_.get (), &Transceiver::update, this, &EmulateSplitTransceiver::handle_update);

  // Connect failure signal of wrapped Transceiver object to our
  // parent failure signal.
  connect (wrapped_.get (), &Transceiver::failure, this, &Transceiver::failure);
}

void EmulateSplitTransceiver::start () noexcept
{
  wrapped_->start ();
  wrapped_->tx_frequency (0, false);
}

void EmulateSplitTransceiver::frequency (Frequency rx, MODE m) noexcept
{
#if WSJT_TRACE_CAT
  qDebug () << "EmulateSplitTransceiver::frequency:" << rx << "mode:" << m;
#endif

  // Save frequency parameters.
  frequency_[0] = rx;

  // Set active frequency.
  wrapped_->frequency (rx, m);
}

void EmulateSplitTransceiver::tx_frequency (Frequency tx, bool /* rationalise_mode */) noexcept
{
#if WSJT_TRACE_CAT
  qDebug () << "EmulateSplitTransceiver::tx_frequency:" << tx;
#endif

  // Save frequency parameter.
  frequency_[1] = tx;

  // Set active frequency.
  wrapped_->frequency (frequency_[(tx_ && frequency_[1]) ? 1 : 0]);
}

void EmulateSplitTransceiver::ptt (bool on) noexcept
{
#if WSJT_TRACE_CAT
  qDebug () << "EmulateSplitTransceiver::ptt:" << on;
#endif

  // Save TX state for future frequency change requests.
  if (on)
    {
      // save the Rx frequency
      pre_tx_frequency_ = frequency_[0];

      // Switch to other frequency if we have one i.e. client wants
      // split operation).
      wrapped_->frequency (frequency_[frequency_[1] ? 1 : 0]);

      // Change TX state.
      wrapped_->ptt (true);
    }
  else
    {
      // Change TX state.
      wrapped_->ptt (false);

      // Switch to RX frequency.
      wrapped_->frequency (pre_tx_frequency_);
      pre_tx_frequency_ = 0;
    }
  tx_ = on;
}

void EmulateSplitTransceiver::handle_update (TransceiverState state)
{
#if WSJT_TRACE_CAT
  qDebug () << "EmulateSplitTransceiver::handle_update: from wrapped:" << state;
#endif

  // Change to reflect emulated state, we don't want to report the
  // shifted frequency when transmitting.
  if (pre_tx_frequency_)
    {
      state.frequency (pre_tx_frequency_);
    }
  else
    {
      // Follow the rig if in RX mode.
      frequency_[0] = state.frequency ();
    }

  // Always report the other frequency as the Tx frequency we will use.
  state.tx_frequency (frequency_[1]);

  if (state.split ())
    {
      Q_EMIT failure (tr ("Emulated split mode requires rig to be in simplex mode"));
    }
  else
    {
      state.split (true);       // override rig state
  
#if WSJT_TRACE_CAT
      qDebug () << "EmulateSplitTransceiver::handle_update: signalling:" << state;
#endif

      // signal emulated state
      Q_EMIT update (state);
    }
}
