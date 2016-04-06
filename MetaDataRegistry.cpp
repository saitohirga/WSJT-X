#include "MetaDataRegistry.hpp"

#include <QMetaType>
#include <QItemEditorFactory>
#include <QStandardItemEditorCreator>

#include "Radio.hpp"
#include "FrequencyList.hpp"
#include "AudioDevice.hpp"
#include "Configuration.hpp"
#include "StationList.hpp"
#include "Transceiver.hpp"
#include "TransceiverFactory.hpp"
#include "WFPalette.hpp"

#include "FrequencyLineEdit.hpp"

QItemEditorFactory * item_editor_factory ()
{
  static QItemEditorFactory * our_item_editor_factory = new QItemEditorFactory;
  return our_item_editor_factory;
}

void register_types ()
{
  // Radio namespace
  auto frequency_type_id = qRegisterMetaType<Radio::Frequency> ("Frequency");
  qRegisterMetaType<Radio::Frequencies> ("Frequencies");

  // This is required to preserve v1.5 "frequencies" setting for
  // backwards compatibility, without it the setting gets trashed by
  // later versions.
  qRegisterMetaTypeStreamOperators<Radio::Frequencies> ("Frequencies");

  item_editor_factory ()->registerEditor (frequency_type_id, new QStandardItemEditorCreator<FrequencyLineEdit> ());
  auto frequency_delta_type_id = qRegisterMetaType<Radio::FrequencyDelta> ("FrequencyDelta");
  item_editor_factory ()->registerEditor (frequency_delta_type_id, new QStandardItemEditorCreator<FrequencyDeltaLineEdit> ());

  // Frequency list model
  qRegisterMetaType<FrequencyList::Item> ("Item");
  qRegisterMetaTypeStreamOperators<FrequencyList::Item> ("Item");
  qRegisterMetaType<FrequencyList::FrequencyItems> ("FrequencyItems");
  qRegisterMetaTypeStreamOperators<FrequencyList::FrequencyItems> ("FrequencyItems");

  // Audio device
  qRegisterMetaType<AudioDevice::Channel> ("AudioDevice::Channel");

  // Configuration
#if QT_VERSION < 0x050500
  qRegisterMetaType<Configuration::DataMode> ("Configuration::DataMode");
  qRegisterMetaType<Configuration::Type2MsgGen> ("Configuration::Type2MsgGen");
#endif
  qRegisterMetaTypeStreamOperators<Configuration::DataMode> ("Configuration::DataMode");
  qRegisterMetaTypeStreamOperators<Configuration::Type2MsgGen> ("Configuration::Type2MsgGen");

  // Station details
  qRegisterMetaType<StationList::Station> ("Station");
  qRegisterMetaType<StationList::Stations> ("Stations");
  qRegisterMetaTypeStreamOperators<StationList::Station> ("Station");
  qRegisterMetaTypeStreamOperators<StationList::Stations> ("Stations");

  // Transceiver
  qRegisterMetaType<Transceiver::TransceiverState> ("Transceiver::TransceiverState");
#if QT_VERSION < 0x050500
  qRegisterMetaType<Transceiver::MODE> ("Transceiver::MODE");
#endif

  // Transceiver factory
#if QT_VERSION < 0x050500
  qRegisterMetaType<TransceiverFactory::DataBits> ("TransceiverFactory::DataBits");
  qRegisterMetaType<TransceiverFactory::StopBits> ("TransceiverFactory::StopBits");
  qRegisterMetaType<TransceiverFactory::Handshake> ("TransceiverFactory::Handshake");
  qRegisterMetaType<TransceiverFactory::PTTMethod> ("TransceiverFactory::PTTMethod");
  qRegisterMetaType<TransceiverFactory::TXAudioSource> ("TransceiverFactory::TXAudioSource");
  qRegisterMetaType<TransceiverFactory::SplitMode> ("TransceiverFactory::SplitMode");
#endif
  qRegisterMetaTypeStreamOperators<TransceiverFactory::DataBits> ("TransceiverFactory::DataBits");
  qRegisterMetaTypeStreamOperators<TransceiverFactory::StopBits> ("TransceiverFactory::StopBits");
  qRegisterMetaTypeStreamOperators<TransceiverFactory::Handshake> ("TransceiverFactory::Handshake");
  qRegisterMetaTypeStreamOperators<TransceiverFactory::PTTMethod> ("TransceiverFactory::PTTMethod");
  qRegisterMetaTypeStreamOperators<TransceiverFactory::TXAudioSource> ("TransceiverFactory::TXAudioSource");
  qRegisterMetaTypeStreamOperators<TransceiverFactory::SplitMode> ("TransceiverFactory::SplitMode");

  // Waterfall palette
  qRegisterMetaTypeStreamOperators<WFPalette::Colours> ("Colours");
}
