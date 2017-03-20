#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include "nga.c"
int main(int argc, char **argv) {
  ngaPrepare();
  int32_t size = 0;
  if (argc == 2)
      size = ngaLoadImage(argv[1]);
  else
      size = ngaLoadImage("ngaImage");
  int32_t i;
  printf("#include <stdint.h>\n");
  printf("int32_t ngaImageCells = %d;\n", size);
  printf("int32_t ngaImage[] = { ");
  i = 0;
  while (i < size) {
    if (i+1 < size)
      printf("%d,", memory[i]);
    else
      printf("%d };\n", memory[i]);
    i++;
  }
  exit(0);
}
