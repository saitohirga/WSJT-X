/**
 * \file src/rigclass.cc
 * \brief Ham Radio Control Libraries C++ interface
 * \author Stephane Fillod
 * \date 2001-2003
 *
 * Hamlib C++ interface is a frontend implementing wrapper functions.
 */

/**
 *
 *  Hamlib C++ bindings - main file
 *  Copyright (c) 2001-2003 by Stephane Fillod
 *
 *
 *   This library is free software; you can redistribute it and/or
 *   modify it under the terms of the GNU Lesser General Public
 *   License as published by the Free Software Foundation; either
 *   version 2.1 of the License, or (at your option) any later version.
 *
 *   This library is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *   Lesser General Public License for more details.
 *
 *   You should have received a copy of the GNU Lesser General Public
 *   License along with this library; if not, write to the Free Software
 *   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 *
 */

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include <hamlib/rig.h>
#include "rigclass.h"
#include <QDebug>
#include <QHostAddress>

#define NUMTRIES 5

static int hamlibpp_freq_event(RIG *rig, vfo_t vfo, freq_t freq, rig_ptr_t arg);

static int hamlibpp_freq_event(RIG *rig, vfo_t vfo, freq_t freq, rig_ptr_t arg)
{
  if (!rig || !rig->state.obj)
    return -RIG_EINVAL;

/* assert rig == ((Rig*)rig->state.obj).theRig */
  return ((Rig*)rig->state.obj)->FreqEvent(vfo, freq, arg);
}

Rig::Rig()
{
  rig_set_debug_level( RIG_DEBUG_WARN);
}

Rig::~Rig() {
  theRig->state.obj = NULL;
  rig_cleanup(theRig);
  caps = NULL;
}

int Rig::init(rig_model_t rig_model)
{
    int initOk;

    theRig = rig_init(rig_model);
    if (!theRig)
      {
        initOk = false;
      }
    else
      {
        initOk = true;
	caps = theRig->caps;
	theRig->callbacks.freq_event = &hamlibpp_freq_event;
	theRig->state.obj = (rig_ptr_t)this;
      }

    return initOk;
}

int Rig::open(int n) {
  m_hrd=false;
  m_cmndr=false;
  if(n<9900) {
    if(n==-99999) return -1;                      //Silence compiler warning
    return rig_open(theRig);
  }

#ifdef WIN32	              // Ham radio Deluxe or Commander (Windows only)
  if(n==9999) {
    m_hrd=true;
    bool bConnect=false;
    bConnect = HRDInterfaceConnect(L"localhost",7809);
    if(bConnect) {
      const wchar_t* context=HRDInterfaceSendMessage(L"Get Context");
      m_context="[" + QString::fromWCharArray (context,-1) + "] ";
      HRDInterfaceFreeString(context);
      return 0;
    } else {
      m_hrd=false;
      return -1;
    }
  }
  if(n==9998) {
    if(commanderSocket->state()==QAbstractSocket::ConnectedState) {
      commanderSocket->abort();
    }

    if(commanderSocket->state()==QAbstractSocket::UnconnectedState) {
      commanderSocket->connectToHost(QHostAddress::LocalHost, 52002);
      if(!commanderSocket->waitForConnected(1000)) {
        return -1;
      }
    }
    QString t;
    t="<command:10>CmdGetFreq<parameters:0>";
    QByteArray ba = t.toLocal8Bit();
    const char* buf=ba.data();
    commanderSocket->write(buf);
    commanderSocket->waitForReadyRead(1000);
    QByteArray reply=commanderSocket->read(128);
    if(reply.indexOf("<CmdFreq:")==0) {
      m_cmndr=true;
      return 0;
    }
  }
#endif
  return -1;
}

int Rig::close(void) {
#ifdef WIN32	// Ham Radio Deluxe only on Windows
  if(m_hrd) {
    HRDInterfaceDisconnect();
    return 0;
  } else if(m_cmndr) {
    commanderSocket->close();
    return 0;
  } else
#endif
    {
    return rig_close(theRig);
  }
}

int Rig::setConf(const char *name, const char *val)
{
  return rig_set_conf(theRig, tokenLookup(name), val);
}

int Rig::setFreq(freq_t freq, vfo_t vfo) {
#ifdef WIN32	// Ham Radio Deluxe (only on Windows)
  if(m_hrd) {
    QString t;
    int nhz=(int)freq;
    t=m_context + "Set Frequency-Hz " + QString::number(nhz);
    const wchar_t* cmnd = (const wchar_t*) t.utf16();
    const wchar_t* result=HRDInterfaceSendMessage(cmnd);
    QString t2=QString::fromWCharArray (result,-1);
    HRDInterfaceFreeString(result);
    if(t2=="OK") {
      return 0;
    } else {
      return -1;
    }
  } else if(m_cmndr) {
    QString t;
    double f=0.001*freq;
    t.sprintf("<command:10>CmdSetFreq<parameters:23><xcvrfreq:10>%10.3f",f);
    QLocale locale;
    t.replace(".",locale.decimalPoint());
    QByteArray ba = t.toLocal8Bit();
    const char* buf=ba.data();
    commanderSocket->write(buf);
    commanderSocket->waitForBytesWritten(1000);
    return 0;
  } else
#endif
  {
    return rig_set_freq(theRig, vfo, freq);
  }
}

int Rig::setXit(shortfreq_t xit, vfo_t vfo)
{
  return rig_set_xit(theRig, vfo, xit);
}

int Rig::setVFO(vfo_t vfo)
{
  return rig_set_vfo(theRig, vfo);
}

vfo_t Rig::getVFO()
{
  vfo_t vfo;
  rig_get_vfo(theRig, &vfo);
  return vfo;
}

int Rig::setSplitFreq(freq_t tx_freq, vfo_t vfo) {
#ifdef WIN32	// Ham Radio Deluxe only on Windows
  if(m_hrd) {
    QString t;
    int nhz=(int)tx_freq;
    t=m_context + "Set Frequency-Hz " + QString::number(nhz);
    const wchar_t* cmnd = (const wchar_t*) t.utf16();
    const wchar_t* result=HRDInterfaceSendMessage(cmnd);
    QString t2=QString::fromWCharArray (result,-1);
    HRDInterfaceFreeString(result);
    if(t2=="OK") {
      return 0;
    } else {
      return -1;
    }
  } else if(m_cmndr) {
    QString t;
    double f=0.001*tx_freq;
    t.sprintf("<command:12>CmdSetTxFreq<parameters:23><xcvrfreq:10>%10.3f",f);
    QLocale locale;
    t.replace(".",locale.decimalPoint());
    QByteArray ba = t.toLocal8Bit();
    const char* buf=ba.data();
    commanderSocket->write(buf);
    commanderSocket->waitForBytesWritten(1000);
    return 0;
  } else
#endif
  {
    return rig_set_split_freq(theRig, vfo, tx_freq);
  }
}

freq_t Rig::getFreq(vfo_t vfo)
{
  freq_t freq;
#ifdef WIN32	// Ham Radio Deluxe (only on Windows)
  if(m_hrd) {
    const wchar_t* cmnd = (const wchar_t*) (m_context+"Get Frequency").utf16();
    const wchar_t* freqString=HRDInterfaceSendMessage(cmnd);
    QString t2=QString::fromWCharArray (freqString,-1);
    HRDInterfaceFreeString(freqString);
    freq=t2.toDouble();
    return freq;
  } else if(m_cmndr) {
    QString t;
    t="<command:10>CmdGetFreq<parameters:0>";
    QByteArray ba = t.toLocal8Bit();
    const char* buf=ba.data();
    commanderSocket->write(buf);
    commanderSocket->waitForReadyRead(1000);
    QByteArray reply=commanderSocket->read(128);
    QString t2(reply);
    if(t2.indexOf("<CmdFreq:")==0) {
      int i1=t2.indexOf(">");
      t2=t2.mid(i1+1).replace(",","");
      freq=1000.0*t2.toDouble();
      return freq;
    } else {
      return -1.0;
    }
  } else
#endif
  {
    freq=-1.0;
    for(int i=0; i<NUMTRIES; i++) {
      int iret=rig_get_freq(theRig, vfo, &freq);
      if(iret==RIG_OK) break;
    }
    return freq;
  }
}

int Rig::setMode(rmode_t mode, pbwidth_t width, vfo_t vfo) {
  return rig_set_mode(theRig, vfo, mode, width);
}

rmode_t Rig::getMode(pbwidth_t& width, vfo_t vfo) {
  rmode_t mode;
  rig_get_mode(theRig, vfo, &mode, &width);
  return mode;
}

int Rig::setPTT(ptt_t ptt, vfo_t vfo)
{
#ifdef WIN32	// Ham Radio Deluxe only on Windows
  if(m_hrd) {
    wchar_t* cmnd;

    if(ptt==0) {
      cmnd = (wchar_t*) (m_context +
                             "Set Button-Select TX 0").utf16();
    } else {
      cmnd = (wchar_t*) (m_context +
                             "Set Button-Select TX 1").utf16();
    }
    const wchar_t* result=HRDInterfaceSendMessage(cmnd);
    QString t2=QString::fromWCharArray (result,-1);
    HRDInterfaceFreeString(result);
    if(t2=="OK") {
      return 0;
    } else {
      return -1;
    }
  } else if(m_cmndr) {
    QString t;
    if(ptt==0) t="<command:5>CmdRX<parameters:0>";
    if(ptt>0) t="<command:5>CmdTX<parameters:0>";
    QByteArray ba = t.toLocal8Bit();
    const char* buf=ba.data();
    commanderSocket->write(buf);
    commanderSocket->waitForBytesWritten(1000);
    return 0;
  } else
#endif
    {
    return rig_set_ptt(theRig, vfo, ptt);
  }
}

ptt_t Rig::getPTT(vfo_t vfo)
{
  ptt_t ptt;
  rig_get_ptt(theRig, vfo, &ptt);
  return ptt;
}

token_t Rig::tokenLookup(const char *name)
{
  return rig_token_lookup(theRig, name);
}
