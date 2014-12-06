#ifndef EMULATE_SPLIT_TRANSCEIVER_HPP__
#define EMULATE_SPLIT_TRANSCEIVER_HPP__

#include <memory>

#include "Transceiver.hpp"

//
// Emulate Split Transceiver
//
// Helper decorator class that encapsulates  the emulation of split TX
// operation.
//
// Responsibilities
//
//  Delegates  all  but setting  of  other  (split) frequency  to  the
//  wrapped Transceiver instance. Also routes failure signals from the
//  wrapped Transceiver instance to this instances failure signal.
//
//  Intercepts status  updates from  the wrapped  Transceiver instance
//  and re-signals it with the emulated status.
//
//  Generates a status update signal if the other (split) frequency is
//  changed, this is necessary  since the wrapped transceiver instance
//  never receives other frequency changes.
//
class EmulateSplitTransceiver final
  : public Transceiver
{
public:
  // takes ownership of wrapped Transceiver
  explicit EmulateSplitTransceiver (std::unique_ptr<Transceiver> wrapped);

  void start () noexcept override;
  void frequency (Frequency, MODE) noexcept override;
  void tx_frequency (Frequency, bool rationalise_mode) noexcept override;
  void ptt (bool on) noexcept override;

  // forward everything else to wrapped Transceiver
  void stop () noexcept override {wrapped_->stop (); Q_EMIT finished ();}
  void mode (MODE m, bool /* rationalise */) noexcept override {wrapped_->mode (m, false);}
  void sync (bool force_signal) noexcept override {wrapped_->sync (force_signal);}

private:
  void handle_update (TransceiverState);

  std::unique_ptr<Transceiver> wrapped_;
  Frequency frequency_[2];  // [0] <- RX, [1] <- other
  Frequency pre_tx_frequency_;  // return to this on switching to Rx
  bool tx_;
};

#endif
