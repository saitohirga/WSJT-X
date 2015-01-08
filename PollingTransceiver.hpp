#ifndef POLLING_TRANSCEIVER_HPP__
#define POLLING_TRANSCEIVER_HPP__

#include <QObject>

#include "TransceiverBase.hpp"

#include "pimpl_h.hpp"

//
// Polling Transceiver
//
//  Helper base  class that  encapsulates the emulation  of continuous
//  update and caching of a transceiver state.
//
// Collaborations
//
//  Implements the TransceiverBase post  action interface and provides
//  the abstract  poll() operation  for sub-classes to  implement. The
//  pol operation is invoked every poll_interval milliseconds.
//
// Responsibilities
//
//  Because some rig interfaces don't immediately update after a state
//  change request; this  class allows a rig a few  polls to stabilise
//  to the  requested state before  signalling the change.  This means
//  that  clients don't  see  intermediate states  that are  sometimes
//  inaccurate,  e.g. changing  the split  TX frequency  on Icom  rigs
//  requires a  VFO switch  and polls while  switched will  return the
//  wrong current frequency.
//
class PollingTransceiver
  : public TransceiverBase
{
  Q_OBJECT;                     // for translation context

protected:
  explicit PollingTransceiver (int poll_interval); // in milliseconds

public:
  ~PollingTransceiver ();

protected:
  void do_sync (bool force_signal) override final;

  // Sub-classes implement this and fetch what they can from the rig
  // in a non-intrusive manner.
  virtual void poll () = 0;

  void do_post_start () override final;
  void do_post_stop () override final;
  void do_post_frequency (Frequency, MODE = UNK) override final;
  void do_post_tx_frequency (Frequency, bool rationalize = true) override final;
  void do_post_mode (MODE, bool rationalize = true) override final;
  void do_post_ptt (bool = true) override final;
  bool do_pre_update () override final;

private:
  class impl;
  pimpl<impl> m_;
};

#endif
