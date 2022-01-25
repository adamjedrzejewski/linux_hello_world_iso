#include <stdio.h>
#include <unistd.h>

int main(int argc, char **argv) {
    (void) argc;
    (void) argv;
    puts("hello world");
    sleep(0xFFFFFFFF);
}
