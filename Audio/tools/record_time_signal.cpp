#include <iostream>
#include <exception>
#include <stdexcept>
#include <string>

#include <locale.h>

#include <QCoreApplication>
#include <QTextStream>
#include <QCommandLineParser>
#include <QCommandLineOption>
#include <QStringList>
#include <QFileInfo>
#include <QAudioFormat>
#include <QAudioDeviceInfo>
#include <QAudioInput>
#include <QTimer>
#include <QDateTime>

#include "revision_utils.hpp"
#include "Audio/BWFFile.hpp"

namespace
{
  QTextStream qtout {stdout};
}

class Recorder final
  : public QObject
{
  Q_OBJECT;

public:
  Recorder (int start, int duration, QString const& output, QAudioDeviceInfo const& source_device, QAudioFormat const& format, int notify_interval, int buffer_size)
    : source_ {source_device, format}
    , notify_interval_ {notify_interval}
    , output_ {format, output}
    , duration_ {duration}
  {
    if (!output_.open (BWFFile::WriteOnly)) throw std::invalid_argument {QString {"cannot open output file \"%1\""}.arg (output).toStdString ()};

    if (buffer_size) source_.setBufferSize (format.bytesForFrames (buffer_size));
    if (notify_interval_)
      {
        source_.setNotifyInterval (notify_interval);
        connect (&source_, &QAudioInput::notify, this, &Recorder::notify);
      }

    QTimer::singleShot (int ((((start - (QDateTime::currentMSecsSinceEpoch () / 1000) % 60) + 60) % 60) * 1000), Qt::PreciseTimer, this, &Recorder::start);
  }

  Q_SIGNAL void done ();

private:
  Q_SLOT void start ()
  {
    qtout << "started recording at " << QDateTime::currentDateTimeUtc ().toString ("hh:mm:ss.zzz UTC") << endl;
    source_.start (&output_);
    if (!notify_interval_) QTimer::singleShot (duration_ * 1000, Qt::PreciseTimer, this, &Recorder::stop);
    qtout << QString {"buffer size used is: %1"}.arg (source_.bufferSize ()) << endl;
  }

  Q_SLOT void notify ()
  {
    auto length = source_.elapsedUSecs ();
    qtout << QString {"%1 US recorded\r"}.arg (length) << flush;
    if (length >= duration_ * 1000 * 1000) stop ();
  }

  Q_SLOT void stop ()
  {
    auto length = source_.elapsedUSecs ();
    source_.stop ();
    qtout << QString {"%1 uS recorded "}.arg (length) << '(' << source_.format ().framesForBytes (output_.size ()) << " frames recorded)\n";
    qtout << "stopped recording at " << QDateTime::currentDateTimeUtc ().toString ("hh:mm:ss.zzz UTC") << endl;
    Q_EMIT done ();
  }

  QAudioInput source_;
  int notify_interval_;
  BWFFile output_;
  int duration_;
};

#include "record_time_signal.moc"

int main(int argc, char *argv[])
{
  QCoreApplication app {argc, argv};
  try
    {
      ::setlocale (LC_NUMERIC, "C"); // ensure number forms are in
                                     // consistent format, do this
                                     // after instantiating
                                     // QApplication so that Qt has
                                     // correct l18n

      // Override programs executable basename as application name.
      app.setApplicationName ("WSJT-X Record Time Signal");
      app.setApplicationVersion (version ());

      QCommandLineParser parser;
      parser.setApplicationDescription (
                                        "\nTool to determine and experiment with QAudioInput latencies\n\n"
                                        "\tUse the -I option to list available recording device numbers\n"
                                        );
      auto help_option = parser.addHelpOption ();
      auto version_option = parser.addVersionOption ();

      parser.addOptions ({
          {{"I", "list-audio-inputs"},
              app.translate ("main", "List the available audio input devices")},
          {{"s", "start-time"},
              app.translate ("main", "Record from <start-time> seconds"),
              app.translate ("main", "start-time")},
          {{"d", "duration"},
              app.translate ("main", "Recording <duration> seconds"),
              app.translate ("main", "duration")},
          {{"o", "output"},
              app.translate ("main", "Save output as <output-file>"),
              app.translate ("main", "output-file")},
          {{"f", "force"},
              app.translate ("main", "Overwrite existing file")},
          {{"r", "sample-rate"},
              app.translate ("main", "Record at <sample-rate>"),
              app.translate ("main", "sample-rate")},
          {{"c", "num-channels"},
              app.translate ("main", "Record <num> channels"),
              app.translate ("main", "num")},
          {{"R", "recording-device-number"},
              app.translate ("main", "Record from <device-number>"),
              app.translate ("main", "device-number")},
          {{"n", "notify-interval"},
              app.translate ("main", "use notify signals every <interval> milliseconds, zero to use a timer"),
              app.translate ("main", "interval")},
          {{"b", "buffer-size"},
              app.translate ("main", "audio buffer size <frames>"),
              app.translate ("main", "frames")},
        });
      parser.process (app);

      auto input_devices = QAudioDeviceInfo::availableDevices (QAudio::AudioInput);      
      if (parser.isSet ("I"))
        {
          int n {0};
          for (auto const& device : input_devices)
            {
              qtout << ++n << " - [" << device.deviceName () << ']' << endl;
            }
          return 0;
        }

      bool ok;
      int start = parser.value ("s").toInt (&ok);
      if (!ok) throw std::invalid_argument {"start time not a number"};
      int duration = parser.value ("d").toInt (&ok);
      if (!ok) throw std::invalid_argument {"duration not a number"};
      int sample_rate {48000};
      if (parser.isSet ("r"))
        {
          sample_rate = parser.value ("r").toInt (&ok);
          if (!ok) throw std::invalid_argument {"sample rate not a number"};
        }
      int num_channels {2};
      if (parser.isSet ("c"))
        {
          num_channels = parser.value ("c").toInt (&ok);
          if (!ok) throw std::invalid_argument {"channel count not a number"};
        }
      int notify_interval {0};
      if (parser.isSet ("n"))
        {
          notify_interval = parser.value ("n").toInt (&ok);
          if (!ok) throw std::invalid_argument {"notify interval not a number"};
        }
      int buffer_size {0};
      if (parser.isSet ("b"))
        {
          buffer_size = parser.value ("b").toInt (&ok);
          if (!ok) throw std::invalid_argument {"buffer size not a number"};
        }
      int input_device {0};
      if (parser.isSet ("R"))
        {
          input_device = parser.value ("R").toInt (&ok);
          if (!ok || 0 >= input_device || input_device > input_devices.size ())
            {
              throw std::invalid_argument {"invalid recording device"};
            }
        }
      if (!parser.isSet ("o")) throw std::invalid_argument {"output file required"};
      QFileInfo ofi {parser.value ("o")};
      if (!ofi.suffix ().size () && ofi.fileName ()[ofi.fileName ().size () - 1] != QChar {'.'})
        {
          ofi.setFile (ofi.filePath () + ".wav");
        }
      if (!parser.isSet ("f") && ofi.isFile ())
        {
          throw std::invalid_argument {"set the `-force' option to overwrite an existing output file"};
        }

      QAudioFormat audio_format;
      audio_format.setSampleRate (sample_rate);
      audio_format.setChannelCount (num_channels);
      audio_format.setSampleSize (16);
      audio_format.setSampleType (QAudioFormat::SignedInt);
      audio_format.setCodec ("audio/pcm");

      auto source = input_device ? input_devices[input_device] : QAudioDeviceInfo::defaultInputDevice ();
      if (!source.isFormatSupported (audio_format))
        {
          qtout << "warning, requested format not supported, using nearest" << endl;
          audio_format = source.nearestFormat (audio_format);
        }

      // run the application
      Recorder record {start, duration, ofi.filePath (), source, audio_format, notify_interval, buffer_size};
      QObject::connect (&record, &Recorder::done, &app, &QCoreApplication::quit);
      return app.exec();
    }
  catch (std::exception const& e)
    {
      std::cerr << "Error: " << e.what () << '\n';
    }
  catch (...)
    {
      std::cerr << "Unexpected fatal error\n";
      throw; // hoping the runtime might tell us more about the exception
    }
  return -1;
}
