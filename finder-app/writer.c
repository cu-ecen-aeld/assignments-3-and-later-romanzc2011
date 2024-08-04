#include <fcntl.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <syslog.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>

int main(int argc, char *argv[])
{
    int fd;
    size_t len;
    ssize_t ret;

    openlog(NULL,0,LOG_USER);
    if(argc != 3)
    {
        syslog(LOG_ERR, "Invalid Number of arguments: %d", argc);
        fprintf(stderr, "Usage: <filename> <string>\n", strerror(errno));
        return 1;
    }

    const char *filename = argv[1];
    const char *buffer = argv[2];

    // Open file to write
    fd = creat(filename, 0644);
    if(fd == -1) {
        syslog(LOG_ERR, "Error opening file %s: %s", filename, strerror(errno));
        fprintf(stderr, "Error opening file %s: %s\n", filename, strerror(errno));
        return 1;
    }

    len = strlen(buffer);

    // Write buffer to open file and close file
    while(len > 0)
    {
        ret = write(fd, buffer, len);
        if(ret == -1) {
            if(errno == EINTR) {
                continue;
            }
            perror("write");
            syslog(LOG_ERR, "Error writing to file: %s", strerror(errno));

            close(fd);
            return 1;
        }
        
        syslog(LOG_DEBUG, "Wrote %d bytes to %s", ret, filename);

        buffer += ret; // Advance buffer ptr by number bytes written
        len -= ret; // Decrease length by amount bytes written
    }

    close(fd);
    return 0;
}