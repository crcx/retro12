/* c-rx.c, copyright (c) 2016 charles childers */
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include "nga.h"
CELL Dictionary, Heap, Compiler;
CELL notfound;
#define TIB 1471
CELL stack_pop() {
  sp--;
  return data[sp + 1];
}
void stack_push(CELL value) {
  sp++;
  data[sp] = value;
}
void string_inject(char *str, int buffer) {
  int m = strlen(str);
  int i = 0;
  while (m > 0) {
    memory[buffer + i] = (CELL)str[i];
    memory[buffer + i + 1] = 0;
    m--; i++;
  }
}
char string_data[8192];
char *string_extract(int at)
{
  CELL starting = at;
  CELL i = 0;
  while(memory[starting] && i < 8192)
    string_data[i++] = (char)memory[starting++];
  string_data[i] = 0;
  return (char *)string_data;
}
#define D_OFFSET_LINK  0
#define D_OFFSET_XT    1
#define D_OFFSET_CLASS 2
#define D_OFFSET_NAME  3
int d_link(CELL dt) {
  return dt + D_OFFSET_LINK;
}
int d_xt(CELL dt) {
  return dt + D_OFFSET_XT;
}
int d_class(CELL dt) {
  return dt + D_OFFSET_CLASS;
}
int d_name(CELL dt) {
  return dt + D_OFFSET_NAME;
}
int d_count_entries(CELL Dictionary) {
  CELL count = 0;
  CELL i = Dictionary;
  while (memory[i] != 0) {
    count++;
    i = memory[i];
  }
  return count;
}
int d_lookup(CELL Dictionary, char *name) {
  CELL dt = 0;
  CELL i = Dictionary;
  char *dname;
  while (memory[i] != 0 && i != 0) {
    dname = string_extract(d_name(i));
    if (strcmp(dname, name) == 0) {
      dt = i;
      i = 0;
    } else {
      i = memory[i];
    }
  }
  return dt;
}
CELL d_xt_for(char *Name, CELL Dictionary) {
  return memory[d_xt(d_lookup(Dictionary, Name))];
}
CELL d_class_for(char *Name, CELL Dictionary) {
  return memory[d_class(d_lookup(Dictionary, Name))];
}
#define NGURA_FS_OPEN   118
#define NGURA_FS_CLOSE  119
#define NGURA_FS_READ   120
#define NGURA_FS_WRITE  121
#define NGURA_FS_TELL   122
#define NGURA_FS_SEEK   123
#define NGURA_FS_SIZE   124
#define NGURA_FS_DELETE 125
#define MAX_OPEN_FILES 128
FILE *nguraFileHandles[MAX_OPEN_FILES];
CELL nguraGetFileHandle()
{
  CELL i;
  for(i = 1; i < MAX_OPEN_FILES; i++)
    if (nguraFileHandles[i] == 0)
      return i;
  return 0;
}
CELL nguraOpenFile() {
  CELL slot, mode, name;
  slot = nguraGetFileHandle();
  mode = data[sp]; sp--;
  name = data[sp]; sp--;
  char *request = string_extract(name);
  if (slot > 0)
  {
    if (mode == 0)  nguraFileHandles[slot] = fopen(request, "r");
    if (mode == 1)  nguraFileHandles[slot] = fopen(request, "w");
    if (mode == 2)  nguraFileHandles[slot] = fopen(request, "a");
    if (mode == 3)  nguraFileHandles[slot] = fopen(request, "r+");
  }
  if (nguraFileHandles[slot] == NULL)
  {
    nguraFileHandles[slot] = 0;
    slot = 0;
  }
  stack_push(slot);
  return slot;
}
CELL nguraReadFile() {
  CELL c = fgetc(nguraFileHandles[data[sp]]); sp--;
  return (c == EOF) ? 0 : c;
}
CELL nguraWriteFile() {
  CELL slot, c, r;
  slot = data[sp]; sp--;
  c = data[sp]; sp--;
  r = fputc(c, nguraFileHandles[slot]);
  return (r == EOF) ? 0 : 1;
}
CELL nguraCloseFile() {
  fclose(nguraFileHandles[data[sp]]);
  nguraFileHandles[data[sp]] = 0;
  sp--;
  return 0;
}
CELL nguraGetFilePosition() {
  CELL slot = data[sp]; sp--;
  return (CELL) ftell(nguraFileHandles[slot]);
}
CELL nguraSetFilePosition() {
  CELL slot, pos, r;
  slot = data[sp]; sp--;
  pos  = data[sp]; sp--;
  r = fseek(nguraFileHandles[slot], pos, SEEK_SET);
  return r;
}
CELL nguraGetFileSize() {
  CELL slot, current, r, size;
  slot = data[sp]; sp--;
  current = ftell(nguraFileHandles[slot]);
  r = fseek(nguraFileHandles[slot], 0, SEEK_END);
  size = ftell(nguraFileHandles[slot]);
  fseek(nguraFileHandles[slot], current, SEEK_SET);
  return (r == 0) ? size : 0;
}
CELL nguraDeleteFile() {
  CELL name = data[sp]; sp--;
  char *request = string_extract(name);
  return (unlink(request) == 0) ? -1 : 0;
}
void execute(int cell) {
  CELL opcode;
  rp = 1;
  ip = cell;
  while (ip < IMAGE_SIZE) {
    if (ip == notfound) {
      printf("%s ?\n", string_extract(TIB));
    }
    opcode = memory[ip];
    if (ngaValidatePackedOpcodes(opcode) != 0) {
      ngaProcessPackedOpcodes(opcode);
    } else if (opcode >= 0 && opcode < 27) {
      ngaProcessOpcode(opcode);
    } else {
      switch (opcode) {
        case 1000: printf("%c", data[sp]); sp--; break;
        case 1001: stack_push(getc(stdin)); break;
    case NGURA_FS_OPEN:
      nguraOpenFile();
      break;
    case NGURA_FS_CLOSE:
      nguraCloseFile();
      break;
    case NGURA_FS_READ:
      stack_push(nguraReadFile());
      break;
    case NGURA_FS_WRITE:
      nguraWriteFile();
      break;
    case NGURA_FS_TELL:
      nguraGetFilePosition();
      break;
    case NGURA_FS_SEEK:
      nguraSetFilePosition();
      break;
    case NGURA_FS_SIZE:
      nguraGetFileSize();
      break;
    case NGURA_FS_DELETE:
      nguraDeleteFile();
      break;
        default:   printf("Invalid instruction!\n");
                   printf("At %d, opcode %d\n", ip, opcode);
                   exit(1);
      }
    }
    ip++;
    if (rp == 0)
      ip = IMAGE_SIZE;
  }
}
void update_rx() {
  Dictionary = memory[2];
  Heap = memory[3];
  Compiler = d_xt_for("Compiler", Dictionary);
  notfound = d_xt_for("err:notfound", Dictionary);
}
void evaluate(char *s) {
  if (strlen(s) == 0)
    return;
  update_rx();
  CELL interpret = d_xt_for("interpret", Dictionary);
  string_inject(s, TIB);
  stack_push(TIB);
  execute(interpret);
}
int not_eol(int ch) {
  return (ch != (char)10) && (ch != (char)13) && (ch != (char)32) && (ch != EOF);
}
void read_token(FILE *file, char *token_buffer, int echo) {
  int ch = getc(file);
  if (echo != 0)
    putchar(ch);
  int count = 0;
  while (not_eol(ch))
  {
    if ((ch == 8 || ch == 127) && count > 0) {
      count--;
      if (echo != 0) {
        putchar(8);
        putchar(32);
        putchar(8);
      }
    } else {
      token_buffer[count++] = ch;
    }
    ch = getc(file);
    if (echo != 0)
      putchar(ch);
  }
  token_buffer[count] = '\0';
}
