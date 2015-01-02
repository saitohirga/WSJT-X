#ifndef HAMLIB_TRANSCEIVER_HPP_
#define HAMLIB_TRANSCEIVER_HPP_

#include <tuple>

#include <QString>

#include <hamlib/rig.h>

#include "TransceiverFactory.hpp"
#include "PollingTransceiver.hpp"

extern "C"
{
  typedef struct rig RIG;
  struct rig_caps;
  typedef int vfo_t;
}

// hamlib transceiver and PTT mostly delegated directly to hamlib Rig class
class HamlibTransceiver final
  : public PollingTransceiver
{
  Q_OBJECT;                     // for translation context

 public:
  static void register_transceivers (TransceiverFactory::Transceivers *);

  explicit HamlibTransceiver (int model_number
                              , QString const& cat_port
                              , int cat_baud
                              , TransceiverFactory::DataBits cat_data_bits
                              , TransceiverFactory::StopBits cat_stop_bits
                              , TransceiverFactory::Handshake cat_handshake
                              , bool cat_dtr_always_on
                              , bool cat_rts_always_on
                              , TransceiverFactory::PTTMethod ptt_type
                              , TransceiverFactory::TXAudioSource back_ptt_port
                              , QString const& ptt_port
                              , int poll_interval = 0);
  ~HamlibTransceiver ();

 private:
  void do_start () override;
  void do_stop () override;
  void do_frequency (Frequency, MODE = UNK) override;
  void do_tx_frequency (Frequency, bool rationalise_mode = true) override;
  void do_mode (MODE, bool rationalise = true) override;
  void do_ptt (bool) override;

  void poll () override;

  void error_check (int ret_code, QString const& doing) const;
  void set_conf (char const * item, char const * value);
  QByteArray get_conf (char const * item);
  Transceiver::MODE map_mode (rmode_t) const;
  rmode_t map_mode (Transceiver::MODE mode) const;
  std::tuple<vfo_t, vfo_t> get_vfos () const;

  struct RIGDeleter {static void cleanup (RIG *);};
  QScopedPointer<RIG, RIGDeleter> rig_;

  bool back_ptt_port_;
  bool is_dummy_;

  bool mutable reversed_;

  bool split_query_works_;
  bool tickle_hamlib_;          // Hamlib requires a
                                // rig_set_split_vfo() call to
                                // establish the Tx VFO
};

#endif
