/*  ____   ____ ______ ____    ___
    || \\ ||    | || | || \\  // \\
    ||_// ||==    ||   ||_// ((   ))
    || \\ ||___   ||   || \\  \\_//
    a personal, minimalistic forth

    Going back to Retro 10, the `listener` has been the most
    common interface for Retro. This is a version of it for
    Retro 12.

    I'm no longer using this myself. Instead I use `rre`,
    which is a simpler and less messy approach. This will
    probably be removed in the future, at least as part of
    the core distribution.

    Copyright (c) 2016, 2017 Charles Childers
*/
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <stdint.h>
#include "../bridge.c"

#ifdef _WIN32
#include "termios.h"
int	tcgetattr(int _fildes, struct termios *_termios_p) {return 0;};
int	tcsetattr(int _fildes, int _optional_actions, const struct termios *_termios_p) {return 0;};
#include "ioctl.h"
#else
#include <termios.h>
#include <sys/ioctl.h>
#endif

struct termios new_termios, old_termios;
void term_setup() {
  tcgetattr(0, &old_termios);
  new_termios = old_termios;
  new_termios.c_iflag &= ~(BRKINT+ISTRIP+IXON+IXOFF);
  new_termios.c_iflag |= (IGNBRK+IGNPAR);
  new_termios.c_lflag &= ~(ICANON+ISIG+IEXTEN);
  new_termios.c_cc[VMIN] = 1;
  new_termios.c_cc[VTIME] = 0;
  tcsetattr(0, TCSANOW, &new_termios);
}
void term_cleanup() {
  tcsetattr(0, TCSANOW, &old_termios);
}
void include_file(char *fname) {
  char source[64000];
  FILE *fp;
  fp = fopen(fname, "r");
  if (fp == NULL)
    return;
  printf("+ load %s\n", fname);
  while (!feof(fp))
  {
    read_token(fp, source, 0);
    evaluate(source);
  }
  fclose(fp);
}
void dump_stack() {
  CELL i;
  printf("Stack: ");
  for (i = 1; i <= sp; i++) {
    if (i == sp)
      printf("< %d >", data[i]);
    else
      printf("%d ", data[i]);
  }
  printf("\n");
}
void prompt() {
  if (memory[Compiler] == 0)
    printf("\nok  ");
}
int main(int argc, char **argv) {
  ngaPrepare();
  ngaLoadImage("ngaImage");
  update_rx();
  printf("RETRO 12 (rx-%d.%d)\n", memory[4] / 100, memory[4] % 100);
  char input[1024];
  term_setup();
  printf("%d MAX, TIB @ %d, Heap @ %d\n\n", IMAGE_SIZE, TIB, Heap);
  while(1) {
    prompt();
    Dictionary = memory[2];
    read_token(stdin, input, 0);
    if (strcmp(input, "bye") == 0) {
      term_cleanup();
      exit(0);
    }
    else if (strcmp(input, ".p") == 0) {
      printf("__%s__", string_extract(data[sp]));
    }
    else if (strcmp(input, ".s") == 0) {
      dump_stack();
    }
    else
      evaluate(input);
  }
  term_cleanup();
  exit(0);
}
