#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <syslog.h>


int main(int argc, const char *argv[])
{
	openlog("writer", LOG_CONS, LOG_USER);
	if(argc < 3 )
	{
		syslog(LOG_ERR,"Not enough parameters");
		return 1;
	}
	const char *filepath= argv[1];
	int fd;
	const char *buf=argv[2];

	fd= open(filepath, O_CREAT | O_WRONLY  , 0666);
	write(fd, buf, strlen(buf));
	syslog(LOG_DEBUG, "Writing %s to %s",argv[2],argv[1]);
	
	close(fd);
	
	return 0;
	
	
	
}
