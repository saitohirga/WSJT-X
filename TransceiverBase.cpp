#include "TransceiverBase.hpp"

#include <exception>

#include <QString>

#include "pimpl_impl.hpp"

class TransceiverBase::impl final
{
public:
  impl ()
  {
  }

  impl (impl const&) = delete;
  impl& operator = (impl const&) = delete;

  TransceiverState state_;
};


TransceiverBase::TransceiverBase ()
{
}

TransceiverBase::~TransceiverBase ()
{
}

void TransceiverBase::start () noexcept
{
  QString message;
  try
    {
      if (m_->state_.online ())
        {
          // ensure PTT isn't left set
          do_ptt (false);
          do_post_ptt (false);

          do_stop ();
          do_post_stop ();
          m_->state_.online (false);
        }
      do_start ();
      do_post_start ();
      m_->state_.online (true);
    }
  catch (std::exception const& e)
    {
      message = e.what ();
    }
  catch (...)
    {
      message = "Unexpected rig error";
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
      if (m_->state_.online ())
        {
          // ensure PTT isn't left set
          do_ptt (false);
          do_post_ptt (false);
        }

      do_stop ();
      do_post_stop ();
      m_->state_.online (false);
    }
  catch (std::exception const& e)
    {
      message = e.what ();
    }
  catch (...)
    {
      message = "Unexpected rig error";
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

void TransceiverBase::frequency (Frequency f) noexcept
{
  QString message;
  try
    {
      if (m_->state_.online ())
        {
          do_frequency (f);
          do_post_frequency (f);
        }
    }
  catch (std::exception const& e)
    {
      message = e.what ();
    }
  catch (...)
    {
      message = "Unexpected rig error";
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
      if (m_->state_.online ())
        {
          do_tx_frequency (tx, rationalise_mode);
          do_post_tx_frequency (tx);
        }
    }
  catch (std::exception const& e)
    {
      message = e.what ();
    }
  catch (...)
    {
      message = "Unexpected rig error";
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
      if (m_->state_.online ())
        {
          do_mode (m, rationalise);
          do_post_mode (m);
        }
    }
  catch (std::exception const& e)
    {
      message = e.what ();
    }
  catch (...)
    {
      message = "Unexpected rig error";
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
      if (m_->state_.online ())
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
      message = "Unexpected rig error";
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
      if (m_->state_.online ())
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
      message = "Unexpected rig error";
    }
  if (!message.isEmpty ())
    {
      offline (message);
    }
}

void TransceiverBase::update_rx_frequency (Frequency rx)
{
  m_->state_.frequency (rx);
}

void TransceiverBase::update_other_frequency (Frequency tx)
{
  m_->state_.tx_frequency (tx);
}

void TransceiverBase::update_split (bool state)
{
  m_->state_.split (state);
}

void TransceiverBase::update_mode (MODE m)
{
  m_->state_.mode (m);
}

void TransceiverBase::update_PTT (bool state)
{
  m_->state_.ptt (state);
}

void TransceiverBase::update_complete ()
{
  if (do_pre_update ())
    {
      Q_EMIT update (m_->state_);
    }
}

void TransceiverBase::offline (QString const& reason)
{
  QString message;
  try
    {
      if (m_->state_.online ())
        {
          m_->state_.online (false);
          do_stop ();
        }
    }
  catch (std::exception const& e)
    {
      message = e.what ();
    }
  catch (...)
    {
      message = "Unexpected rig error";
    }
  Q_EMIT failure (reason + '\n' + message);
}

auto TransceiverBase::state () const -> TransceiverState const&
{
  return m_->state_;
}
