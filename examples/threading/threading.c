#include "threading.h"
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>

// Optional: use these functions to add debug or error prints to your application
#define DEBUG_LOG(msg,...)
//#define DEBUG_LOG(msg,...) printf("threading: " msg "\n" , ##__VA_ARGS__)
#define ERROR_LOG(msg,...) printf("threading ERROR: " msg "\n" , ##__VA_ARGS__)

void *threadfunc(void* thread_param)
{

    // TODO: wait, obtain mutex, wait, release mutex as described by thread_data structure
    // hint: use a cast like the one below to obtain thread arguments from your parameter
    //struct thread_data* thread_func_args = (struct thread_data *) thread_param;
    struct thread_data *thread_func_args = (struct thread_data *) thread_param;
    int s;

    thread_func_args->thread_complete_success = false;

    usleep(thread_func_args->wait_ms * 1000);

    s = pthread_mutex_lock(thread_func_args->thread_mutex);
    if(s != 0) {
        perror("pthread_mutex_lock");
        return NULL;
    }

    usleep(thread_func_args->release_ms * 1000);
    s = pthread_mutex_unlock(thread_func_args->thread_mutex);
    if(s != 0) {
        perror("pthread_mutex_unlock");
        return NULL;
    }

    thread_func_args->thread_complete_success = true;

    return thread_param;
}


bool start_thread_obtaining_mutex(pthread_t *thread, pthread_mutex_t *mutex, int wait_to_obtain_ms, int wait_to_release_ms)
{

    struct thread_data *data_ptr = malloc(sizeof(struct thread_data));
    int s;

    if(data_ptr == NULL) {
        ERROR_LOG("Memory allocation failed");
        return false;
    }

    data_ptr->wait_ms = wait_to_obtain_ms;
    data_ptr->release_ms = wait_to_release_ms;
    data_ptr->thread_mutex = mutex;
    data_ptr->thread_complete_success = false;
    
    s = pthread_create(thread, NULL, threadfunc, (void *)data_ptr);
    if(s != 0) {
        ERROR_LOG("Error creating thread");
        return false;
    }
    
    return true;
}

