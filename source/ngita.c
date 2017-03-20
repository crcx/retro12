#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#ifdef _WIN32
#include "termios.h"
int	tcgetattr(int _fildes, struct termios *_termios_p) {return 0;};
int	tcsetattr(int _fildes, int _optional_actions, const struct termios *_termios_p) {return 0;};
#else
#include <termios.h>
#endif
#include "nga.c"
#define NGURA_TTY
#define NGURA_KBD
#define NGURA_FS
#define NGURA_BLK
#include "ngura.c"
void processOpcodes() {
  CELL opcode;
  ip = 0;
  while (ip < IMAGE_SIZE) {
    opcode = memory[ip];
    if (ngaValidatePackedOpcodes(opcode) != 0) {
      ngaProcessPackedOpcodes(opcode);
    } else if (opcode >= 0 && opcode < 27) {
      ngaProcessOpcode(opcode);
    } else {
      nguraProcessOpcode(opcode);
    }
    ip++;
  }
}
int main(int argc, char **argv) {
  ngaPrepare();
  if (argc == 2)
      ngaLoadImage(argv[1]);
  else
      ngaLoadImage("ngaImage");
  nguraInitialize();
  processOpcodes();
  nguraCleanup();
  for (CELL i = 1; i <= sp; i++)
    printf("%d ", data[i]);
  printf("\n");
  exit(0);
}
