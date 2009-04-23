#include <winsock2.h>
#include <ws2tcpip.h>
#include <stdlib.h>
#include <stdio.h>

#define HELLO_PORT 50004
//#define HELLO_GROUP "239.255.0.0"
#define HELLO_GROUP "127.0.0.1"

struct sockaddr_in addr;
int fd;

void __stdcall SETUP_SSOCKET(void)
{
  struct ip_mreq mreq;

  // Make sure that we have compatible Winsock support
  WORD wVersionRequested;
  WSADATA wsaData;
  int err;
 
  wVersionRequested = MAKEWORD( 2, 2 );
  err = WSAStartup( wVersionRequested, &wsaData );
  if ( err != 0 ) {
    /* Tell the user that we could not find a usable */
    /* WinSock DLL.                                  */
    exit(1);
  }
 
  /* Confirm that the WinSock DLL supports 2.2.*/
  /* Note that if the DLL supports versions greater    */
  /* than 2.2 in addition to 2.2, it will still return */
  /* 2.2 in wVersion since that is the version we      */
  /* requested.                                        */
 
  if ( LOBYTE( wsaData.wVersion ) != 2 ||
       HIBYTE( wsaData.wVersion ) != 2 ) {
    /* Tell the user that we could not find a usable */
    /* WinSock DLL.                                  */
    WSACleanup( );
    exit(1);
  }
  /* The WinSock DLL is acceptable. Proceed. */

  /* create what looks like an ordinary UDP socket */
  if ((fd=socket(AF_INET,SOCK_DGRAM,IPPROTO_UDP)) < 0) {
    perror("socket");
    exit(1);
  }

  /* set up destination address */
  memset(&addr,0,sizeof(addr));
  addr.sin_family=AF_INET;
  addr.sin_addr.s_addr=inet_addr(HELLO_GROUP);
  addr.sin_port=htons(HELLO_PORT);
}

void __stdcall SEND_PKT(char buf[])
{
  if (sendto(fd,buf,1416,0,
	     (struct sockaddr *) &addr, sizeof(addr)) <  0) { 
    perror("sendto");
    exit(1);}
}
