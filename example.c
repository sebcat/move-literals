#include <stdio.h>

#ifdef __FOO_PLATFORM
#error \
  "unsupported platform"
#endif

int main(int argc, char *argv[]) {
  // char *x = "foobar";
  char *x = "foobarbaz";
  printf("%s\n", x);
  return 42;
}


