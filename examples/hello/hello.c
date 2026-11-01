#include <stdio.h>

#ifndef MESSAGE
#define MESSAGE "Hello from the cluster!"
#endif

int main(void)
{
    puts(MESSAGE);
#ifdef VERBOSE
    puts("Verbose output enabled at compile time.");
#endif
    return 0;
}
