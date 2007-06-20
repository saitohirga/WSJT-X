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

struct sockaddr_in addr;
int fd;

void setup_ssocket_(void)
{
  struct ip_mreq mreq;

  /* create what looks like an ordinary UDP socket */
  if ((fd=socket(AF_INET,SOCK_DGRAM,0)) < 0) {
    perror("socket");
    exit(EXIT_FAILURE);
  }

  /* set up destination address */
  memset(&addr,0,sizeof(addr));
  addr.sin_family=AF_INET;
  addr.sin_addr.s_addr=inet_addr(HELLO_GROUP);
  addr.sin_port=htons(HELLO_PORT);
}

void send_pkt_(char buf[])
{
  if (sendto(fd,buf,1416,0,(struct sockaddr *) &addr, 
	     sizeof(addr)) <  0) { 
    perror("sendto");
    exit(EXIT_FAILURE);}
}
