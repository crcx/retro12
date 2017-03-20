#ifdef NGURA_TTY
#define NGURA_TTY_PUTC  100
#define NGURA_TTY_PUTN  101
#define NGURA_TTY_PUTS  102
#define NGURA_TTY_PUTSC 103
#define NGURA_TTY_CLEAR 104
#endif
#ifdef NGURA_KBD
#define NGURA_KBD_GETC 110
#define NGURA_KBD_GETN 111
#define NGURA_KBD_GETS 112
#endif
#ifdef NGURA_FS
#define NGURA_FS_OPEN   118
#define NGURA_FS_CLOSE  119
#define NGURA_FS_READ   120
#define NGURA_FS_WRITE  121
#define NGURA_FS_TELL   122
#define NGURA_FS_SEEK   123
#define NGURA_FS_SIZE   124
#define NGURA_FS_DELETE 125
#endif
#define NGURA_SAVE_IMAGE 130
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
char request[8192];
void nguraGetString(int starting)
{
  CELL i = 0;
  while(memory[starting] && i < 8192)
    request[i++] = (char)memory[starting++];
  request[i] = 0;
}
#if defined(NGURA_TTY) || defined(NGURA_KBD)
#ifdef _WIN32
#include "termios.h"
#else
#include <termios.h>
#endif
struct termios nguraConsoleOriginalTermios;
struct termios nguraConsoleTermios;
void nguraConsoleInit() {
  tcgetattr(0, &nguraConsoleOriginalTermios);
  nguraConsoleTermios = nguraConsoleOriginalTermios;
  nguraConsoleTermios.c_iflag &= ~(BRKINT+ISTRIP+IXON+IXOFF);
  nguraConsoleTermios.c_iflag |= (IGNBRK+IGNPAR);
  nguraConsoleTermios.c_lflag &= ~(ICANON+ISIG+IEXTEN+ECHO);
  nguraConsoleTermios.c_cc[VMIN] = 1;
  nguraConsoleTermios.c_cc[VTIME] = 0;
  tcsetattr(0, TCSANOW, &nguraConsoleTermios);
}
void nguraConsoleCleanup() {
  tcsetattr(0, TCSANOW, &nguraConsoleOriginalTermios);
}
#endif
#ifdef NGURA_TTY
void nguraTTYPutChar(char c) {
  putchar(c);
  if (c == 8) {
    putchar(32);
    putchar(8);
  }
}
void nguraTTYPutNumber(int i) {
  printf("%d", i);
}
void nguraTTYPutString(CELL addr) {
  nguraGetString(addr);
  printf("%s", request);
}
void nguraTTYPutStringCounted(CELL addr, CELL length) {
  CELL i = 0;
  while(memory[addr] && i < length) {
    nguraTTYPutChar((char)memory[addr++]);
    i++;
  }
}
void nguraTTYClearDisplay() {
  printf("\033[2J\033[1;1H");
}
#endif
#ifdef NGURA_KBD
int nguraKBDGetChar() {
  int i = 0;
  i = (int)getc(stdin);
  if (i == 10 || i == 13)
    i = 32;
  nguraTTYPutChar((char)i);
  return i;
}
void nguraKBDGetString(CELL delim, CELL limit, CELL starting) {
  CELL i = starting;
  CELL k = 0;
  CELL done = 0;
  while (done == 0) {
    k = nguraKBDGetChar();
    if (k == delim)
      done = 1;
    else
      memory[i++] = k;
    if (i >= (limit + starting))
      done = 1;
  }
  memory[i] = 0;
}
CELL nguraKBDGetNumber(int delim) {
  CELL i = 0;
  CELL k = 0;
  CELL done = 0;
  while (done == 0) {
    k = nguraKBDGetChar();
    if (k == delim)
      done = 1;
    if (i > 8192)
      done = 1;
    if (done == 0) {
      request[i] = k;
    }
    i++;
  }
  request[i] = 0;
  k = atol(request);
  return k;
}
#endif
#ifdef NGURA_FS
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
  mode = TOS; sp--;
  name = TOS; sp--;
  nguraGetString(name);
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
  return slot;
}
CELL nguraReadFile() {
  CELL c = fgetc(nguraFileHandles[TOS]); sp--;
  return (c == EOF) ? 0 : c;
}
CELL nguraWriteFile() {
  CELL slot, c, r;
  slot = TOS; sp--;
  c = TOS; sp--;
  r = fputc(c, nguraFileHandles[slot]);
  return (r == EOF) ? 0 : 1;
}
CELL nguraCloseFile() {
  fclose(nguraFileHandles[TOS]);
  nguraFileHandles[TOS] = 0;
  sp--;
  return 0;
}
CELL nguraGetFilePosition() {
  CELL slot = TOS; sp--;
  return (CELL) ftell(nguraFileHandles[slot]);
}
CELL nguraSetFilePosition() {
  CELL slot, pos, r;
  slot = TOS; sp--;
  pos  = TOS; sp--;
  r = fseek(nguraFileHandles[slot], pos, SEEK_SET);
  return r;
}
CELL nguraGetFileSize() {
  CELL slot, current, r, size;
  slot = TOS; sp--;
  current = ftell(nguraFileHandles[slot]);
  r = fseek(nguraFileHandles[slot], 0, SEEK_END);
  size = ftell(nguraFileHandles[slot]);
  fseek(nguraFileHandles[slot], current, SEEK_SET);
  return (r == 0) ? size : 0;
}
CELL nguraDeleteFile() {
  CELL name = TOS; sp--;
  nguraGetString(name);
  return (unlink(request) == 0) ? -1 : 0;
}
#endif
void nguraSaveImage() {
  FILE *fp;
  if ((fp = fopen("rx.nga", "wb")) == NULL) {
    printf("Unable to save the ngaImage!\n");
    exit(2);
  }
  fwrite(&memory, sizeof(CELL), IMAGE_SIZE, fp);
  fclose(fp);
}
void nguraInitialize() {
#if defined(NGURA_TTY) || defined(NGURA_KBD)
  nguraConsoleInit();
#endif
}
void nguraCleanup() {
#if defined(NGURA_TTY) || defined(NGURA_KBD)
  nguraConsoleCleanup();
#endif
}
void nguraProcessOpcode(CELL opcode) {
  CELL addr, length;
  CELL delim, limit, starting;
  switch(opcode) {
#ifdef NGURA_TTY
    case NGURA_TTY_PUTC:
      nguraTTYPutChar((char)data[sp]);
      sp--;
      break;
    case NGURA_TTY_PUTN:
      nguraTTYPutNumber(data[sp]);
      sp--;
      break;
    case NGURA_TTY_PUTS:
      nguraTTYPutString(TOS);
      sp--;
      break;
    case NGURA_TTY_PUTSC:
      addr = TOS;
      sp--;
      length = TOS;
      sp--;
      nguraTTYPutStringCounted(addr, length);
      break;
    case NGURA_TTY_CLEAR:
      nguraTTYClearDisplay();
      break;
#endif
#ifdef NGURA_KBD
    case NGURA_KBD_GETC:
      sp++;
      TOS = nguraKBDGetChar();
      break;
    case NGURA_KBD_GETN:
      delim = TOS;
      TOS = nguraKBDGetNumber(delim);
      break;
    case NGURA_KBD_GETS:
      starting = TOS; sp--;
      limit = TOS; sp--;
      delim = TOS; sp--;
      nguraKBDGetString(delim, limit, starting);
      break;
#endif
#ifdef NGURA_FS
    case NGURA_FS_OPEN:
      nguraOpenFile();
      break;
    case NGURA_FS_CLOSE:
      nguraCloseFile();
      break;
    case NGURA_FS_READ:
      nguraReadFile();
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
#endif
    case NGURA_SAVE_IMAGE:
      nguraSaveImage();
      break;
  }
}
