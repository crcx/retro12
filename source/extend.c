/*  ____   ____ ______ ____    ___
    || \\ ||    | || | || \\  // \\
    ||_// ||==    ||   ||_// ((   ))
    || \\ ||___   ||   || \\  \\_//
    a personal, minimalistic forth

    This is a quick interface layer that loads and runs a
    source file, then saves a new image file. It's used to
    merge the `retro.forth` into the base `rx` image.

    Copyright (c) 2016, 2017 Charles Childers
*/

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <stdint.h>

#include "bridge.c"

int include_file(char *fname) {
  int tokens = 0;
  char source[64000];
  FILE *fp;
  fp = fopen(fname, "r");
  if (fp == NULL)
    return 0;
  while (!feof(fp))
  {
    read_token(fp, source, 0);
#ifdef VERBOSE
    printf("compiling ___ %s ___\n", source);
#endif
    evaluate(source);
    tokens++;
  }
  fclose(fp);
  return tokens;
}

void stats() {
  update_rx();
  printf("  Heap @ %d\n", Heap);
}

int main(int argc, char **argv) {
  printf("RETRO12\n");
  printf("+ initialize\n");
  ngaPrepare();
  printf("+ load image\n");
  ngaLoadImage("ngaImage");
  stats();
  printf("+ load %s\n", argv[1]);
  int tokens = include_file(argv[1]);
  printf("  processed %d tokens\n", tokens);
  stats();
  printf("+ save new image\n");
  FILE *fp;
  if ((fp = fopen("ngaImage", "wb")) == NULL) {
    printf("Unable to save the ngaImage!\n");
    exit(2);
  }
  fwrite(&memory, sizeof(CELL), memory[3] + 1, fp);
  fclose(fp);
  return 0;
}
