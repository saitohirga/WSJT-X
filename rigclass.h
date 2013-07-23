/*
 *  Hamlib C++ bindings - API header
 *  Copyright (c) 2001-2002 by Stephane Fillod
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

#ifndef _RIGCLASS_H
#define _RIGCLASS_H 1

#include <hamlib/rig.h>
#include <iostream>
#include <QString>
#include <QTcpSocket>

extern QTcpSocket* commanderSocket;

class BACKEND_IMPEXP Rig {
private:
  RIG* theRig;  // Global ref. to the rig
  bool m_hrd;
  bool m_cmndr;
  QString m_context;


protected:
public:
  Rig();
  virtual ~Rig();

  const struct rig_caps *caps;

  // Initialize rig
  int init(rig_model_t rig_model);

  // This method open the communication port to the rig
  int open(int n);

  // This method close the communication port to the rig
  int close(void);

  int setConf(const char *name, const char *val);
  token_t tokenLookup(const char *name);

  int setFreq(freq_t freq, vfo_t vfo = RIG_VFO_CURR);
  freq_t getFreq(vfo_t vfo = RIG_VFO_CURR);
  int setMode(rmode_t, pbwidth_t width = RIG_PASSBAND_NORMAL, vfo_t vfo = RIG_VFO_CURR);
  rmode_t getMode(pbwidth_t&, vfo_t vfo = RIG_VFO_CURR);
  int setVFO(vfo_t);
  vfo_t getVFO();
  int setXit(shortfreq_t xit, vfo_t vfo);
  int setSplitFreq(freq_t tx_freq, vfo_t vfo = RIG_VFO_CURR);
  int setPTT (ptt_t ptt, vfo_t vfo = RIG_VFO_CURR);
  ptt_t getPTT (vfo_t vfo = RIG_VFO_CURR);

  // callbacks available in your derived object
  virtual int FreqEvent(vfo_t, freq_t, rig_ptr_t) const {
		  return RIG_OK;
  }
  virtual int ModeEvent(vfo_t, rmode_t, pbwidth_t, rig_ptr_t) const {
		  return RIG_OK;
  }
  virtual int VFOEvent(vfo_t, rig_ptr_t) const {
		  return RIG_OK;
  }
  virtual int PTTEvent(vfo_t, ptt_t, rig_ptr_t) const {
		  return RIG_OK;
  }
  virtual int DCDEvent(vfo_t, dcd_t, rig_ptr_t) const {
		  return RIG_OK;
  }
};

#ifdef WIN32
extern "C" {
  bool HRDInterfaceConnect(const wchar_t *host, const ushort);
  void HRDInterfaceDisconnect();
  bool HRDInterfaceIsConnected();
  wchar_t* HRDInterfaceSendMessage(const wchar_t *msg);
  void HRDInterfaceFreeString(const wchar_t *lstring);
}
#endif

#endif	// _RIGCLASS_H
