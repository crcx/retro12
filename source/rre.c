/* listener, copyright (c) 2016 charles childers */
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <stdint.h>
#include "bridge.c"
void dump_stack() {
  if (sp == 0)
    return;
  printf("\nStack: ");
  for (CELL i = 1; i <= sp; i++) {
    if (i == sp)
      printf("[ TOS: %d ]", data[i]);
    else
      printf("%d ", data[i]);
  }
  printf("\n");
}
int include_file(char *fname) {
  char source[64000];
  FILE *fp;
  fp = fopen(fname, "r");
  if (fp == NULL)
    return -1;
  while (!feof(fp))
  {
    read_token(fp, source, 0);
    evaluate(source);
  }
  fclose(fp);
  return 0;
}
void prompt() {
  if (memory[Compiler] == 0)
    printf("\nok  ");
}
extern CELL ngaImageCells;
extern CELL ngaImage[];
int main(int argc, char **argv) {
  ngaPrepare();
  for (int i = 0; i < ngaImageCells; i++)
    memory[i] = ngaImage[i];
  update_rx();
  include_file(argv[1]);
  if (sp >=1 )
    dump_stack();
  exit(0);
}
