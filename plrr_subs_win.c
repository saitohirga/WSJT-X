#include <winsock2.h>
#include <ws2tcpip.h>
#include <stdlib.h>
#include <stdio.h>

#define HELLO_PORT 50004
#define HELLO_GROUP "239.255.0.0"
#define MSGBUFSIZE 1416

struct sockaddr_in addr;
int fd;

//void __stdcall SETUP_RSOCKET(void)
void setup_rsocket_(void)
{
  struct ip_mreq mreq;
  u_int yes=1;
  int i,j,k;

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

  k=sizeof(int);
  i=256*1024;
  err=setsockopt(fd, SOL_SOCKET, SO_RCVBUF, (char *)&i,k);
  if (err<0) {
    j=WSAGetLastError();
    printf("Error: %d   %d\n",err,j);
  }
  /* allow multiple sockets to use the same PORT number */
  if (setsockopt(fd,SOL_SOCKET,SO_REUSEADDR,&yes,sizeof(yes)) < 0) {
    perror("Reusing ADDR failed");
    exit(1);
  }

  /* set up destination address */
  memset(&addr,0,sizeof(addr));
  addr.sin_family=AF_INET;
  addr.sin_addr.s_addr=htonl(INADDR_ANY); /* N.B.: differs from sender */
  addr.sin_port=htons(HELLO_PORT);
     
  /* bind to receive address */
  if (bind(fd,(struct sockaddr *) &addr,sizeof(addr)) < 0) {
    perror("bind");
    exit(1);
  }
     
  /* use setsockopt() to request that the kernel join a multicast group */
  mreq.imr_multiaddr.s_addr=inet_addr(HELLO_GROUP);
  mreq.imr_interface.s_addr=htonl(INADDR_ANY);
  // NG: mreq.imr_interface.s_addr=htonl("192.168.10.13");
  if (setsockopt(fd,IPPROTO_IP,IP_ADD_MEMBERSHIP,&mreq,sizeof(mreq)) < 0) {
    perror("setsockopt");
    exit(1);
  }
}

//void __stdcall RECV_PKT(char buf[])
void recv_pkt_(char buf[])
{
  int addrlen,nbytes;
  addrlen=sizeof(addr);
  if ((nbytes=recvfrom(fd,buf,1416,0, 
		       (struct sockaddr *) &addr,&addrlen)) < 0) {
    perror("recvfrom");
    exit(1);
  }
}
