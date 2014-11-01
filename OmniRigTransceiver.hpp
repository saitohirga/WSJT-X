#ifndef OMNI_RIG_TRANSCEIVER_HPP__
#define OMNI_RIG_TRANSCEIVER_HPP__

#include <memory>

#include <QScopedPointer>
#include <QString>

#include "TransceiverFactory.hpp"
#include "TransceiverBase.hpp"

#include "OmniRig.h"

//
// OmniRig Transceiver Interface
//
// Implemented as a Transceiver decorator  because we may want the PTT
// services of another Transceiver  type such as the HamlibTransceiver
// which can  be enabled by wrapping  a HamlibTransceiver instantiated
// as a "Hamlib Dummy" transceiver in the Transceiver factory method.
//
class OmniRigTransceiver final
  : public TransceiverBase
{
  Q_OBJECT;

public:
  static void register_transceivers (TransceiverFactory::Transceivers *, int id1, int id2);

  enum RigNumber {One = 1, Two};

  // takes ownership of wrapped Transceiver
  explicit OmniRigTransceiver (std::unique_ptr<TransceiverBase> wrapped, RigNumber, TransceiverFactory::PTTMethod ptt_type, QString const& ptt_port);
  ~OmniRigTransceiver ();

  void do_start () override;
  void do_stop () override;
  void do_frequency (Frequency) override;
  void do_tx_frequency (Frequency, bool rationalise_mode) override;
  void do_mode (MODE, bool rationalise) override;
  void do_ptt (bool on) override;
  void do_sync (bool force_signal) override;

private:
  Q_SLOT void online_check ();
  Q_SLOT void handle_COM_exception (int,  QString, QString, QString);
  Q_SLOT void handle_visible_change ();
  Q_SLOT void handle_rig_type_change (int rig_number);
  Q_SLOT void handle_status_change (int rig_number);
  Q_SLOT void handle_params_change (int rig_number, int params);
  Q_SLOT void handle_custom_reply (int, QVariant const& command, QVariant const& reply);

  void init_rig ();

  static MODE map_mode (OmniRig::RigParamX param);
  static OmniRig::RigParamX map_mode (MODE mode);

  std::unique_ptr<TransceiverBase> wrapped_;
  bool use_for_ptt_;
  TransceiverFactory::PTTMethod ptt_type_;
  unsigned startup_poll_countdown_;
  QScopedPointer<OmniRig::OmniRigX> omni_rig_;
  RigNumber rig_number_;
  QScopedPointer<OmniRig::RigX> rig_;
  QScopedPointer<OmniRig::PortBits> port_;
  int readable_params_;
  int writable_params_;
  bool send_update_signal_;
  bool reversed_;   // some rigs can reverse VFOs
  bool starting_;
};

#endif
