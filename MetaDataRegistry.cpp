#include "MetaDataRegistry.hpp"

#include <QMetaType>
#include <QItemEditorFactory>
#include <QStandardItemEditorCreator>

#include "Radio.hpp"
#include "models/FrequencyList.hpp"
#include "AudioDevice.hpp"
#include "Configuration.hpp"
#include "models/StationList.hpp"
#include "Transceiver.hpp"
#include "TransceiverFactory.hpp"
#include "WFPalette.hpp"
#include "models/IARURegions.hpp"
#include "models/DecodeHighlightingModel.hpp"
#include "widgets/FrequencyLineEdit.hpp"

QItemEditorFactory * item_editor_factory ()
{
  static QItemEditorFactory * our_item_editor_factory = new QItemEditorFactory;
  return our_item_editor_factory;
}

void register_types ()
{
  // types in Radio.hpp are registered in their own translation unit
  // as they are needed in the wsjtx_udp shared library too

  // we still have to register the fully qualified names of enum types
  // used as signal/slot connection arguments since the new Qt 5.5
  // Q_ENUM macro only seems to register the unqualified name
  
  item_editor_factory ()->registerEditor (qMetaTypeId<Radio::Frequency> (), new QStandardItemEditorCreator<FrequencyLineEdit> ());
  //auto frequency_delta_type_id = qRegisterMetaType<Radio::FrequencyDelta> ("FrequencyDelta");
  item_editor_factory ()->registerEditor (qMetaTypeId<Radio::FrequencyDelta> (), new QStandardItemEditorCreator<FrequencyDeltaLineEdit> ());

  // Frequency list model
  qRegisterMetaTypeStreamOperators<FrequencyList_v2::Item> ("Item_v2");
  qRegisterMetaTypeStreamOperators<FrequencyList_v2::FrequencyItems> ("FrequencyItems_v2");

  // defunct old versions
  qRegisterMetaTypeStreamOperators<FrequencyList::Item> ("Item");
  qRegisterMetaTypeStreamOperators<FrequencyList::FrequencyItems> ("FrequencyItems");

  // Audio device
  qRegisterMetaType<AudioDevice::Channel> ("AudioDevice::Channel");

  // Configuration
  qRegisterMetaTypeStreamOperators<Configuration::DataMode> ("Configuration::DataMode");
  qRegisterMetaTypeStreamOperators<Configuration::Type2MsgGen> ("Configuration::Type2MsgGen");

  // Station details
  qRegisterMetaType<StationList::Station> ("Station");
  qRegisterMetaType<StationList::Stations> ("Stations");
  qRegisterMetaTypeStreamOperators<StationList::Station> ("Station");
  qRegisterMetaTypeStreamOperators<StationList::Stations> ("Stations");

  // Transceiver
  qRegisterMetaType<Transceiver::TransceiverState> ("Transceiver::TransceiverState");

  // Transceiver factory
  qRegisterMetaTypeStreamOperators<TransceiverFactory::DataBits> ("TransceiverFactory::DataBits");
  qRegisterMetaTypeStreamOperators<TransceiverFactory::StopBits> ("TransceiverFactory::StopBits");
  qRegisterMetaTypeStreamOperators<TransceiverFactory::Handshake> ("TransceiverFactory::Handshake");
  qRegisterMetaTypeStreamOperators<TransceiverFactory::PTTMethod> ("TransceiverFactory::PTTMethod");
  qRegisterMetaTypeStreamOperators<TransceiverFactory::TXAudioSource> ("TransceiverFactory::TXAudioSource");
  qRegisterMetaTypeStreamOperators<TransceiverFactory::SplitMode> ("TransceiverFactory::SplitMode");

  // Waterfall palette
  qRegisterMetaTypeStreamOperators<WFPalette::Colours> ("Colours");

  // IARURegions
  qRegisterMetaTypeStreamOperators<IARURegions::Region> ("IARURegions::Region");

  // DecodeHighlightingModel
  qRegisterMetaTypeStreamOperators<DecodeHighlightingModel::HighlightInfo> ("HighlightInfo");
  qRegisterMetaTypeStreamOperators<DecodeHighlightingModel::HighlightItems> ("HighlightItems");
}
