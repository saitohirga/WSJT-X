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
  // Implement the TransceiverBase interface.
  void do_start () override;
  void do_stop () override;
  void do_frequency (Frequency) override;
  void do_tx_frequency (Frequency, bool rationalise_mode) override;
  void do_mode (MODE, bool rationalise) override;
  void do_ptt (bool on) override;

  // Implement the PollingTransceiver interface.
  void poll () override;

private:
  QString send_command (QString const&, bool no_debug = false, bool prepend_context = true, bool recurse = false);
  void send_simple_command (QString const&, bool no_debug = false);
  void sync_impl ();
  int find_button (QRegExp const&) const;
  int find_dropdown (QRegExp const&) const;
  std::vector<int> find_dropdown_selection (int dropdown, QRegExp const&) const;
  int lookup_dropdown_selection (int dropdown, QString const&) const;
  int get_dropdown (int, bool no_debug = false);
  void set_dropdown (int, int);
  void set_button (int button_index, bool checked = true);
  bool is_button_checked (int button_index, bool no_debug = false);

  // This dictionary type maps Transceiver::MODE to a list of mode
  // drop down selection indexes that equate to that mode.  It is used
  // to map internal MODE values to HRD drop down selections and vice
  // versa.
  using ModeMap = std::vector<std::tuple<MODE, std::vector<int> > >;

  void map_modes (int dropdown, ModeMap *);
  int lookup_mode (MODE, ModeMap const&) const;
  MODE lookup_mode (int, ModeMap const&) const;

  // An alternate TransceiverBase instance that can be used to drive
  // PTT if required.
  std::unique_ptr<TransceiverBase> wrapped_;

  bool use_for_ptt_;            // Use HRD for PTT.

  QString server_;              // The TCP/IP addrress and port for
                                // the HRD server.

  QTcpSocket * hrd_;            // The TCP/IP client that links to the
                                // HRD server.

  enum {none, v4, v5} protocol_; // The HRD protocol that has been
                                 // detected.

  using RadioMap = std::vector<std::tuple<unsigned, QString> >;

  RadioMap radios_;             // Dictionary of available radios. 

  unsigned current_radio_;      // The current addressed radio.

  unsigned vfo_count_;          // How many VFOs are supported.

  QStringList buttons_;         // The buttons available to click.

  QStringList dropdown_names_;  // The names of drop down selectors
                                // available.

  QMap<QString, QStringList> dropdowns_; // Dictionary of available
                                         // drop down selections
                                         // available.

  int vfo_A_button_;            // The button we use to select VFO
                                // A. May be -1 if none available.

  int vfo_B_button_;            // Index of button we use to select
                                // VFO B. May be -1 if none available.

  int vfo_toggle_button_;       // Index of button we use to toggle
                                // the VFOs. Use this if VFO A and VFO
                                // B selection are not available.

  int mode_A_dropdown_;         // Index of the mode drop down for VFO
                                // A.

  ModeMap mode_A_map_;          // The map of modes available for VFO
                                // A.

  int mode_B_dropdown_;         // The drop down index for VFO B mode
                                // setting. May be -1 if independent
                                // VFO mode setting not available.

  ModeMap mode_B_map_;          // The map of modes for VFO B.

  int split_mode_button_;       // Button to use to select split
                                // operation. May be -1 if no button
                                // is available.

  int split_mode_dropdown_;     // The drop down index that allows
                                // split mode to be turned on and
                                // off. May be -1 if no such drop down
                                // exists.

  bool split_mode_dropdown_write_only_; // Some rigs cannot report
                                        // split status.

  std::vector<int> split_mode_dropdown_selection_on_; // The drop down
                                                      // selection to
                                                      // turn on
                                                      // split.

  std::vector<int> split_mode_dropdown_selection_off_; // The drop
                                                       // down
                                                       // selection to
                                                       // disable
                                                       // split.

  int split_off_button_;        // The button to turn off split mode.

  int tx_A_button_;             // The button to transmit on VFO A.

  int tx_B_button_;             // The button to transmit on VFO B.

  int ptt_button_;              // The button to toggle PTT.

  bool reversed_;               // True if VFOs are reversed.
};

#endif
