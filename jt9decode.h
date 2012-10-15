#ifndef JT9DECODE_H
#define JT9DECODE_H
#include <QtCore>
#include <QDebug>

class JT9DecodeThread : public QThread
{
  Q_OBJECT

protected:
  virtual void run();

public:
// Constructs (but does not start) a JT9DecodeThread
  JT9DecodeThread()
    :   quitExecution(false)           // Initialize some private members
    ,   m_txOK(false)
  {
  }

public:
  bool quitExecution;           //If true, thread exits gracefully

// Private members
private:
  bool    m_txOK;               //Enable Tx audio
};

#endif // JT9DECODE_H
