#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/syslog.h>
#include <syslog.h>
#include <unistd.h>

int main(int argc, char *argv[])
{
    openlog(NULL,0,LOG_USER);
    if(argc != 3)
    {
        syslog(LOG_ERR, "Invalid number of arguments: %d", argc);
        fprintf(stderr, "Usage: <filename> <string> %s\n", strerror(errno));
        return 1;
    }

    const char *filename = argv[1];
    char *buffer = argv[2];
    size_t ret;

    // Open file stream for writing
    FILE *fp = fopen(filename, "w");

    if(fp == NULL) {
        syslog(LOG_ERR, "Unable to open file");
        perror("Unable to open file");
        return EXIT_FAILURE;
    }

    ret = fwrite(buffer, sizeof(char), strlen(buffer), fp);

    if(ret != strlen(buffer)) {
        syslog(LOG_ERR, "Failed to write data");
        perror("Failed to write data");
        fclose(fp);
        return EXIT_FAILURE;
    } else {
        syslog(LOG_INFO, "Successful write to file");
    }

    // Close the file
    fclose(fp);
    return EXIT_SUCCESS;
}
