#include <QDebug>
#include <qsharedmemory.h>
#include <QSystemSemaphore>

// Multiple instances: KK1D, 17 Jul 2013
QSharedMemory mem_jt9("mem_jt9");
QSystemSemaphore sem_jt9("sem_jt9", 1, QSystemSemaphore::Open);

extern "C" {
  bool attach_jt9_();
  bool create_jt9_(int nsize);
  bool detach_jt9_();
  bool lock_jt9_();
  bool unlock_jt9_();
  char* address_jt9_();
  int size_jt9_();

  bool acquire_jt9_();
  bool release_jt9_();

  extern struct {
    char c[10];
  } jt9com_;
}

bool attach_jt9_() {return mem_jt9.attach();}
bool create_jt9_(int nsize) {return mem_jt9.create(nsize);}
bool detach_jt9_() {return mem_jt9.detach();}
bool lock_jt9_() {return mem_jt9.lock();}
bool unlock_jt9_() {return mem_jt9.unlock();}
char* address_jt9_() {return (char*)mem_jt9.constData();}
int size_jt9_() {return (int)mem_jt9.size();}

bool acquire_jt9_() {return sem_jt9.acquire();}
bool release_jt9_() {return sem_jt9.release();}
