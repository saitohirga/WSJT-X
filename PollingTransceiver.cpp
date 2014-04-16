#include "PollingTransceiver.hpp"

#include <exception>

#include <QObject>
#include <QString>
#include <QTimer>

#include "pimpl_impl.hpp"

#include "moc_PollingTransceiver.cpp"

namespace
{
  unsigned const polls_to_stabilize {3};
}

// Internal implementation of the PollingTransceiver class.
class PollingTransceiver::impl final
  : public QObject
{
  Q_OBJECT;

private:
  Q_DISABLE_COPY (impl);

public:
  impl (PollingTransceiver * self, int poll_interval)
    : QObject {self}
    , self_ {self}
    , interval_ {poll_interval}
    , poll_timer_ {nullptr}
    , retries_ {0}
  {
  }

private:
  void start_timer ()
  {
    if (interval_)
      {
        if (!poll_timer_)
          {
            poll_timer_ = new QTimer {this}; // pass ownership to QObject which handles destruction for us

            connect (poll_timer_, &QTimer::timeout, this, &PollingTransceiver::impl::handle_timeout);
          }
        poll_timer_->start (interval_);
      }
  }

  void stop_timer ()
  {
    if (poll_timer_)
      {
        poll_timer_->stop ();
      }
  }

  Q_SLOT void handle_timeout ();

  PollingTransceiver * self_; // our owner so we can call methods
  int interval_;    // polling interval in milliseconds
  QTimer * poll_timer_;

  // keep a record of the last state signalled so we can elide
  // duplicate updates
  Transceiver::TransceiverState last_signalled_state_;

  // keep a record of expected state so we can compare with actual
  // updates to determine when state changes have bubbled through
  Transceiver::TransceiverState next_state_;

  unsigned retries_;            // number of incorrect polls left

  friend class PollingTransceiver;
};

#include "PollingTransceiver.moc"


PollingTransceiver::PollingTransceiver (int poll_interval)
  : m_ {this, poll_interval}
{
}

PollingTransceiver::~PollingTransceiver ()
{
}

void PollingTransceiver::do_post_start ()
{
  m_->start_timer ();
  if (!m_->next_state_.online ())
    {
      // remember that we are expecting to go online
      m_->next_state_.online (true);
      m_->retries_ = polls_to_stabilize;
    }
}

void PollingTransceiver::do_post_stop ()
{
  // not much point waiting for rig to go offline since we are ceasing
  // polls
  m_->stop_timer ();
}

void PollingTransceiver::do_post_frequency (Frequency f)
{
  if (m_->next_state_.frequency () != f)
    {
      // update expected state with new frequency and set poll count
      m_->next_state_.frequency (f);
      m_->retries_ = polls_to_stabilize;
    }
}

void PollingTransceiver::do_post_tx_frequency (Frequency f)
{
  if (m_->next_state_.tx_frequency () != f)
    {
      // update expected state with new TX frequency and set poll
      // count
      m_->next_state_.tx_frequency (f);
      m_->next_state_.split (f); // setting non-zero TX frequency means split
      m_->retries_ = polls_to_stabilize;
    }
}

void PollingTransceiver::do_post_mode (MODE m)
{
  if (m_->next_state_.mode () != m)
    {
      // update expected state with new mode and set poll count
      m_->next_state_.mode (m);
      m_->retries_ = polls_to_stabilize;
    }
}

bool PollingTransceiver::do_pre_update ()
{
  // if we are holding off a change then withhold the signal
  if (m_->retries_ && state () != m_->next_state_)
    {
      return false;
    }
  return true;
}

void PollingTransceiver::do_sync (bool force_signal)
{
  poll ();                      // tell sub-classes to update our
                                // state

  // Signal new state if it is directly requested or, what we expected
  // or, hasn't become what we expected after polls_to_stabilize
  // polls. Unsolicited changes will be signalled immediately unless
  // they intervene in a expected sequence where they will be delayed.
  if (m_->retries_)
    {
      --m_->retries_;
      if (force_signal || state () == m_->next_state_ || !m_->retries_)
        {
          // our client wants a signal regardless
          // or the expected state has arrived
          // or there are no more retries
          force_signal = true;
        }
    }
  else if (force_signal || state () != m_->last_signalled_state_)
    {
      // here is the normal passive polling path
      // either our client has requested a state update regardless of change
      // or sate has changed asynchronously
      force_signal = true;
    }

  if (force_signal)
    {
      // reset everything, record and signal the current state
      m_->retries_ = 0;
      m_->next_state_ = state ();
      m_->last_signalled_state_ = state ();
      update_complete ();
    }
}

void PollingTransceiver::impl::handle_timeout ()
{
  QString message;

  // we must catch all exceptions here since we are called by Qt and
  // inform our parent of the failure via the offline() message
  try
    {
      self_->do_sync (false);
    }
  catch (std::exception const& e)
    {
      message = e.what ();
    }
  catch (...)
    {
      message = tr ("Unexpected rig error");
    }
  if (!message.isEmpty ())
    {
      self_->offline (message);
    }
}
