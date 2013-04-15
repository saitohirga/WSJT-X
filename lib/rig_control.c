#include "config.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "tstrig.h"

RIG *my_rig;                                       // handle to rig

int set_conf(RIG *my_rig, char *conf_parms);

//------------------------------------------------------------------------
int set_conf(RIG *my_rig, char *conf_parms)
{
  char *p, *q, *n;
  int ret;

  p = conf_parms;
  while (p && *p != '\0') {
    /* FIXME: left hand value of = cannot be null */
    q = strchr(p, '=');
    if ( !q )
      return -RIG_EINVAL;
    *q++ = '\0';
    n = strchr(q, ',');
    if (n) *n++ = '\0';

    printf("%s   %s\n",p,q);

    ret = rig_set_conf(my_rig, rig_token_lookup(my_rig, p), q);
    if (ret != RIG_OK)
      return ret;
    p = n;
  }
  return RIG_OK;
}

//------------------------------------------------------------------------
int rigOpen(rig_model_t my_model, int verbose)
{
  int retcode;		/* generic return code from functions */
  char *civaddr = NULL;	/* NULL means no need to set conf */
  const char *rig_file;
  const char *conf_parms2;
  int serial_rate;

  rig_set_debug(verbose);
  my_rig=rig_init(my_model);
  
  if (!my_rig) {
    fprintf(stderr, "Unknown rig num %d, or initialization error.\n",my_model);
    exit(2);
  }
  rig_file="COM1";
  serial_rate=4800;
  conf_parms2="data_bits=8,stop_bits=2,serial_handshake=Hardware";

  retcode=set_conf(my_rig, conf_parms2);
  if (retcode!=RIG_OK) {
    fprintf(stderr, "Config parameter error: %s\n", rigerror(retcode));
    exit(2);
  }

  if (rig_file)
    strncpy(my_rig->state.rigport.pathname, rig_file, FILPATHLEN - 1);

  if (serial_rate!=0)
    my_rig->state.rigport.parm.serial.rate = serial_rate;

  if (civaddr)
    rig_set_conf(my_rig, rig_token_lookup(my_rig, "civaddr"), civaddr);

  retcode = rig_open(my_rig);
  return 0;
}

int rigSetFreq(int fHz)
{
  return rig_set_freq(my_rig,RIG_VFO_CURR,fHz);
}

int rigFreq()
{
  int iret=0;
  freq_t freq;
  iret=rig_get_freq(my_rig, RIG_VFO_CURR, &freq);
  if (iret == RIG_OK ) {
    printf("rig_get_freq: freq = %"PRIfreq"\n", freq);
  } else {
    printf("rig_get_freq: error =  %s \n", rigerror(iret));
  }
  return freq;
}

void rigClose()
{
  rig_close(my_rig);
  rig_cleanup(my_rig);
}
