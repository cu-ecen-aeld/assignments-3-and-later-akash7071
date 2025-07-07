#include "threading.h"
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>

// Optional: use these functions to add debug or error prints to your application
#define DEBUG_LOG(msg,...)
//#define DEBUG_LOG(msg,...) printf("threading: " msg "\n" , ##__VA_ARGS__)
#define ERROR_LOG(msg,...) printf("threading ERROR: " msg "\n" , ##__VA_ARGS__)

void* threadfunc(void* thread_param)
{

    // TODO: wait, obtain mutex, wait, release mutex as described by thread_data structure
    // hint: use a cast like the one below to obtain thread arguments from your parameter
    struct thread_data* thread_func_args = (struct thread_data *) thread_param;


    usleep(thread_func_args->wait_to_obtain_ms * 1000);

    if( pthread_mutex_lock(thread_func_args->mutex)!=0)  // Lock the mutex before accessing shared resource
    {
        ERROR_LOG("Unable to lock mutex");
        thread_func_args->thread_complete_success=false;
        //free(thread_func_args);
        return thread_func_args;
    }
    usleep(thread_func_args->wait_to_release_ms * 1000);

    if( pthread_mutex_unlock(thread_func_args->mutex)!=0)  // unlock the mutex before accessing shared resource
    {
        ERROR_LOG("Unable to unlock mutex");
        thread_func_args->thread_complete_success=false;
        //free(thread_func_args);
        return thread_func_args;
    }

    thread_func_args->thread_complete_success=true;
    

    return thread_func_args;
}


bool start_thread_obtaining_mutex(pthread_t *thread, pthread_mutex_t *mutex,int wait_to_obtain_ms, int wait_to_release_ms)
{
    /**
     * TODO: allocate memory for thread_data, setup mutex and wait arguments, pass thread_data to created thread
     * using threadfunc() as entry point.
     *
     * return true if successful.
     *
     * See implementation details in threading.h file comment block
     */
    

    struct thread_data* thread_data = malloc(sizeof(*thread_data));
    if(thread_data==NULL)
    {
        ERROR_LOG("Failed to allocate memory to thread_data");
        return false;
    }

     // Initialize the mutex
/*     if (pthread_mutex_init(mutex, NULL) != 0) {
        ERROR_LOG("Mutex init failed\n");
        return false;
    } */

    thread_data->mutex=mutex;
    thread_data->wait_to_obtain_ms=wait_to_obtain_ms;
    thread_data->wait_to_release_ms=wait_to_release_ms;
	thread_data->thread_complete_success = false;



    if( pthread_create(thread,NULL, threadfunc, thread_data)!=0)
    {
        ERROR_LOG("pthread_create failed");
        free(thread_data);
        return false;
    }
	

    return true;
}

