#ifndef TRANSCEIVER_BASE_HPP__
#define TRANSCEIVER_BASE_HPP__

#include <stdexcept>

#include "Transceiver.hpp"

#include "pimpl_h.hpp"

class QString;

//
// Base Transceiver Implementation
//
//  Behaviour common to all Transceiver implementations.
//
// Collaborations
//
//  Implements the Transceiver abstract  interface as template methods
//  and provides  a new abstract interface  with similar functionality
//  (do_XXXXX operations). Provides and  calls abstract interface that
//  gets  called post  the above  operations (do_post_XXXXX)  to allow
//  caching implementation etc.
//
//  A  key factor  is  to  catch all  exceptions  thrown by  sub-class
//  implementations where  the template method  is a Qt slot  which is
//  therefore  likely  to  be  called   by  Qt  which  doesn't  handle
//  exceptions. Any exceptions are converted to Transceiver::failure()
//  signals.
//
//  Sub-classes update the stored state via a protected interface.
//
// Responsibilities:
//
//  Wrap incoming  Transceiver messages catching all  exceptions in Qt
//  slot driven  messages and converting  them to Qt signals.  This is
//  done because exceptions  make concrete Transceiver implementations
//  simpler  to   write,  but  exceptions  cannot   cross  signal/slot
//  boundaries  (especially across  threads).  This  also removes  any
//  requirement for the client code to handle exceptions.
//
//  Maintain the  state of the  concrete Transceiver instance  that is
//  passed back via  the Transceiver::update(TransceiverState) signal,
//  it   is  still   the   responsibility   of  concrete   Transceiver
//  implementations to emit  the state_change signal when  they have a
//  status update.
//
//  Maintain    a   go/no-go    status   for    concrete   Transceiver
//  implementations  ensuring only  a valid  sequence of  messages are
//  passed. A concrete Transceiver instance  must be started before it
//  can receive  messages, any exception thrown  takes the Transceiver
//  offline.
//
//  Implements methods  that concrete Transceiver  implementations use
//  to update the Transceiver state.  These do not signal state change
//  to  clients  as  this  is   the  responsibility  of  the  concrete
//  Transceiver implementation, thus allowing multiple state component
//  updates to be signalled together if required.
//
class TransceiverBase
  : public Transceiver
{
protected:
  TransceiverBase ();

public:
  ~TransceiverBase ();

  //
  // Implement the Transceiver abstract interface.
  //
  void start () noexcept override final;
  void stop () noexcept override final;
  void frequency (Frequency rx) noexcept override final;
  void tx_frequency (Frequency tx, bool rationalise_mode) noexcept override final;
  void mode (MODE, bool rationalise) noexcept override final;
  void ptt (bool) noexcept override final;
  void sync (bool force_signal) noexcept override final;

protected:
  //
  // Error exception which is thrown to signal unexpected errors.
  //
  struct error
    : public std::runtime_error
  {
    error (char const * msg) : std::runtime_error (msg) {}
  };

  // Template methods that sub classes implement to do what they need to do.
  //
  // These methods may throw exceptions to signal errors.
  virtual void do_start () = 0;
  virtual void do_post_start () {}

  virtual void do_stop () = 0;
  virtual void do_post_stop () {}

  virtual void do_frequency (Frequency rx) = 0;
  virtual void do_post_frequency (Frequency) {}

  virtual void do_tx_frequency (Frequency tx = 0, bool rationalise_mode = true) = 0;
  virtual void do_post_tx_frequency (Frequency) {}

  virtual void do_mode (MODE, bool rationalise = true) = 0;
  virtual void do_post_mode (MODE) {}

  virtual void do_ptt (bool = true) = 0;
  virtual void do_post_ptt (bool) {}

  virtual void do_sync (bool force_signal = false) = 0;

  virtual bool do_pre_update () {return true;}

  // sub classes report rig state changes with these methods
  void update_rx_frequency (Frequency);
  void update_other_frequency (Frequency = 0);
  void update_split (bool);
  void update_mode (MODE);
  void update_PTT (bool = true);

  // Calling this triggers the Transceiver::update(State) signal.
  void update_complete ();

  // sub class may asynchronously take the rig offline by calling this
  void offline (QString const& reason);

  // and query state with this one
  TransceiverState const& state () const;

private:
  class impl;
  pimpl<impl> m_;
};

#endif
