/*  The following don't seem to be needed?
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <time.h>
#include <stdio.h>
*/

#include <arpa/inet.h>
#include <string.h>
#include <stdlib.h>

#define HELLO_PORT 50004
#define HELLO_GROUP "239.255.0.0"
#define MSGBUFSIZE 1416

struct sockaddr_in addr;
int fd;

void setup_rsocket_(void)
{
  struct ip_mreq mreq;
  u_int yes=1;

  /* create what looks like an ordinary UDP socket */
  if ((fd=socket(AF_INET,SOCK_DGRAM,0)) < 0) {
    perror("socket");
    exit(1);
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
  if (setsockopt(fd,IPPROTO_IP,IP_ADD_MEMBERSHIP,&mreq,sizeof(mreq)) < 0) {
    perror("setsockopt");
    exit(1);
  }
}

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
