/* listener, copyright (c) 2016 charles childers */
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <stdint.h>
#include "bridge.c"
#define ED_BUFFER 327680
#define ED_BLOCKS 384
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
void term_clear() {
  printf("\033[2J\033[1;1H");
}
void term_move_cursor(int x, int y) {
  printf("\033[%d;%dH", y, x);
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
void read_blocks() {
  FILE *fp;
  if ((fp = fopen("retro.blocks", "rb")) != NULL) {
    CELL slot;
    for (int i = ED_BUFFER; i < IMAGE_SIZE; i++) {
      fread(&slot, sizeof(CELL), 1, fp);
      memory[i] = slot;
    }
    fclose(fp);
  }
}
void dump_stack() {
  printf("Stack: ");
  for (CELL i = 1; i <= sp; i++) {
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
//  include_file("retro.forth");
  read_blocks();
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
    else if (strcmp(input, "words") == 0) {
      CELL i = Dictionary;
      while (i != 0) {
        string_extract(d_name(i));
        printf("%s  ", string_data);
        i = memory[i];
      }
      printf("(%d entries)\n", d_count_entries(Dictionary));
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
