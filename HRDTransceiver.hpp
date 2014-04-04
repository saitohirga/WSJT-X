#ifndef HRD_TRANSCEIVER_HPP__
#define HRD_TRANSCEIVER_HPP__

#include <vector>
#include <tuple>
#include <memory>

#include <QScopedPointer>
#include <QString>
#include <QStringList>

#include "TransceiverFactory.hpp"
#include "PollingTransceiver.hpp"

class QRegExp;
class QTcpSocket;

//
// Ham Radio Deluxe Transceiver Interface
//
// Implemented as a Transceiver decorator  because we may want the PTT
// services of another Transceiver  type such as the HamlibTransceiver
// which can  be enabled by wrapping  a HamlibTransceiver instantiated
// as a "Hamlib Dummy" transceiver in the Transceiver factory method.
//
class HRDTransceiver final
  : public PollingTransceiver
{
public:
  static void register_transceivers (TransceiverFactory::Transceivers *, int id);

  // takes ownership of wrapped Transceiver
  explicit HRDTransceiver (std::unique_ptr<TransceiverBase> wrapped, QString const& server, bool use_for_ptt, int poll_interval);
  ~HRDTransceiver ();

protected:
  void do_start () override;
  void do_stop () override;
  void do_frequency (Frequency) override;
  void do_tx_frequency (Frequency, bool rationalise_mode) override;
  void do_mode (MODE, bool rationalise) override;
  void do_ptt (bool on) override;

  void poll () override;

private:
  void init_radio ();
  QString send_command (QString const&, bool no_debug = false, bool prepend_context = true, bool recurse = false);
  void send_simple_command (QString const&, bool no_debug = false);
  void sync_impl ();
  int find_button (QRegExp const&) const;
  int find_dropdown (QRegExp const&) const;
  int find_dropdown_selection (int dropdown, QRegExp const&) const;
  int lookup_dropdown_selection (int dropdown, QString const&) const;
  int get_dropdown (int, bool no_debug = false);
  void set_dropdown (int, int);
  void set_button (int button_index, bool checked = true);
  bool is_button_checked (int button_index, bool no_debug = false);

  using ModeMap = std::vector<std::tuple<MODE, int> >;
  void map_modes (int dropdown, ModeMap *);
  int lookup_mode (MODE, ModeMap const&) const;
  MODE lookup_mode (int, ModeMap const&) const;

  std::unique_ptr<TransceiverBase> wrapped_;
  bool use_for_ptt_;
  QString server_;
  QTcpSocket * hrd_;
  enum {none, v4, v5} protocol_;
  using RadioMap = std::vector<std::tuple<unsigned, QString> >;
  RadioMap radios_;
  unsigned current_radio_;
  unsigned vfo_count_;
  QStringList buttons_;
  QStringList dropdown_names_;
  QMap<QString, QStringList> dropdowns_;
  int vfo_A_button_;
  int vfo_B_button_;
  int vfo_toggle_button_;
  int mode_A_dropdown_;
  ModeMap mode_A_map_;
  int mode_B_dropdown_;
  ModeMap mode_B_map_;
  int split_mode_button_;
  int split_mode_dropdown_;
  bool split_mode_dropdown_write_only_;
  int split_mode_dropdown_selection_on_;
  int split_mode_dropdown_selection_off_;
  int split_off_button_;
  int tx_A_button_;
  int tx_B_button_;
  int ptt_button_;
  bool reversed_;
};

#endif
