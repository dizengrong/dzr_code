#include <execinfo.h>
#include <stdio.h>
#include <stdlib.h>
#include <signal.h>

/* A dummy function to make the backtrace more interesting. */
        void
dummy_function (void)
{
        unsigned char *ptr = 0x00;
        *ptr = 0x00;
}

void dump(int signo)
{
        void *array[10];
        size_t size;
        char **strings;
        size_t i;

        size = backtrace (array, 10);
        strings = backtrace_symbols (array, size);

        printf ("Obtained %zd stack frames.\n", size);

        for (i = 0; i < size; i++)
                printf ("%s\n", strings[i]);

        free (strings);

        exit(0);
}

        int
main (void)
{
        signal(SIGSEGV, &dump);
        dummy_function ();

        return 0;
}
