# Naje

Naje is a minimalistic assembler for the Nga instruction set. It provides:

* Two passes: assemble, then resolve lables
* Lables
* Basic literals
* Symbolic names for all instructions
* Facilities for inlining simple data

Naje is intended to be a stepping stone for supporting larger applications.
It wasn't designed to be easy or fun to use, just to provide the essentials
needed to build useful things.

## Instruction Set

Nga has a very small set of instructions. These can be briefly listed in a
short table:

    0  nop        7  jump      14  gt        21  and
    1  lit <v>    8  call      15  fetch     22  or
    2  dup        9  ccall     16  store     23  xor
    3  drop      10  return    17  add       24  shift
    4  swap      11  eq        18  sub       25  zret
    5  push      12  neq       19  mul       26  end
    6  pop       13  lt        20  divmod

All instructions except for **lit** are one cell long. **lit** takes two: one
for the instruction and one for the value to push to the stack.

Naje provides a simple syntax. A short example:

    .output test.nga
    :add
      add
      return
    :subtract
      sub
      return
    :increment
      lit 1
      lit &add
      call
      return
    :main
      lit 100
      lit 95
      lit &subtract
      call
      lit &increment
      call
      end

Delving a bit deeper:

* Blank lines are ok and will be stripped out
* One instruction (or assembler directive) per line
* Labels start with a colon
* A **lit** can be followed by a number or a label name
* References to labels must start with an &

### Technical Notes

Naje has a trivial parser. In deciding how to deal with a line, it will first
strip it to its core elements, then proceed. So given a line like:

    lit 100 ... push 100 to the stack! ...

Naje will take the first two characters of the first token (*li*) to identify
the instruction and the second token for the value. The rest is ignored.

## Instruction Packing

Nga allows for packing multiple instructions per memory location. The Nga code
does this automatically.

What this does is effectively reduce the memory a program takes significantly.
In a standard configuration, cells are 32-bits in length.  With one
instruction per cell, much potential space is wasted. Packing allows up to
four to be stored in each cell.

Some notes on this:

- unused slots are stored as NOP instructions
- packing ends when:

  * four instructions have been queued
  * a flow control instruction has been queued

    - JUMP
    - CCALL
    - CALL
    - RET
    - ZRET
    - END

  * a label is being declared
  * when a **.data** directive is issued

## Code

Include the standard headers and Nga. (This uses various constants and some
dat structures from Nga)

````
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include "nga.c"
````

Rob Judd has made me aware that some platforms (Windows) lack **strtok_r** which is used by the simple parser code. This will enable it if it's not present. It's from a public domain implemenation from Charlie Gordon.

````
#ifndef strtok_r
char* strtok_r(char *str, const char *delim, char **nextp) {
  char *ret;
  if (str == NULL) {
    str = *nextp;
  }
  str += strspn(str, delim);
  if (*str == '\0') {
    return NULL;
  }
  ret = str;
  str += strcspn(str, delim);
  if (*str) {
    *str++ = '\0';
  }
  *nextp = str;
  return ret;
}
#endif
````

Global variables.

| name         | description                                                |
| ------------ | ---------------------------------------------------------- |
| latest       | index into the **memory** buffer (buffer in *nga.c*)       |
| packed       | array of opcodes for packing                               |
| pindex       | index into **packed**                                      |
| dataList     | array of data elements waiting to be stored                |
| dataType     | array of type codes for data elements                      |
| dindex       | index into **dataList** and **dataType**                   |
| najeLabels   | array of label names                                       |
| najePointers | array of pointers that go with **najeLabels**              |
| np           | index into **najeLabels** and **najePointers**             |
| references   | array of types used to identify references needing patched |
| pass         | 0: first pass (references unresoled) 1: second pass        |

````
CELL latest;
CELL packed[4];
CELL pindex;

CELL dataList[1024];
CELL dataType[1024];
CELL dindex;

#define MAX_NAMES 1024
#define STRING_LEN 64

CELL packMode;

char najeLabels[MAX_NAMES][STRING_LEN];
CELL najePointers[MAX_NAMES];
CELL najeRefCount[MAX_NAMES];
CELL np;

CELL references[IMAGE_SIZE];

CELL pass;

char outputName[STRING_LEN];


CELL najeLookup(char *name) {
  CELL slice = -1;
  CELL n = np;
  while (n > 0) {
    n--;
    if (strcmp(najeLabels[n], name) == 0)
      slice = najePointers[n];
  }
  return slice;
}


CELL najeLookupPtr(char *name) {
  CELL slice = -1;
  CELL n = np;
  while (n > 0) {
    n--;
    if (strcmp(najeLabels[n], name) == 0)
      slice = n;
  }
  return slice;
}


void najeAddLabel(char *name, CELL slice) {
  if (pass == 1)  // labels recorded only in 1st pass
    return;
  if (najeLookup(name) == -1) {
    strcpy(najeLabels[np], name);
    najePointers[np] = slice;
    najeRefCount[np] = 0;
    np++;
  } else {
    printf("Fatal error: %s already defined\n", name);
    exit(0);
  }
}

````

A *map* is a file which, along with the image file, can be used to identify
specific stored elements.

Mapfiles are stored as tab separated values with a format like:

    type <tab> identifier/value <tab> offset

| type    | usage                 |
| ------- | --------------------- |
| label   | a named offset        |
| literal | a numeric value       |
| pointer | pointer to an address |

To enable this, compile with -DENABLE_MAP.

````
void najeWriteMap() {
#ifdef ENABLE_MAP
  FILE *fp;
  CELL i;

  if ((fp = fopen(strcat(outputName, ".map"), "w")) == NULL) {
    printf("Unable to save the ngaImage.map!\n");
    exit(2);
  }

  for (i = 0; i < np; i++)
    fprintf(fp, "LABEL\t%s\t%d\n", najeLabels[i], najePointers[i]);

  for (i = 0; i < latest; i++) {
    if (references[i] == 0)
      fprintf(fp, "LITERAL\t%d\t%d\n", memory[i], i);
  }

  for (i = 0; i < latest; i++) {
    if (references[i] == -1)
      fprintf(fp, "POINTER\t%d\t%d\n", memory[i], i);
  }

  fclose(fp);
#else
  return;
#endif
}
````

````
void najeStore(CELL type, CELL value) {
  memory[latest] = value;
  references[latest] = type;
  latest = latest + 1;
}


void najeSync() {
  CELL i;

  if (packMode == 0)
    return;

  if (pindex == 0 && dindex == 0)
    return;

  if (pindex != 0) {
    unsigned int opcode = 0;
    opcode = packed[3];
    opcode = opcode << 8;
    opcode += packed[2];
    opcode = opcode << 8;
    opcode += packed[1];
    opcode = opcode << 8;
    opcode += packed[0];
    najeStore(2, opcode);
  }
  if (dindex != 0) {
    for (i = 0; i < dindex; i++)
      najeStore(dataType[i], dataList[i]);
  }
  pindex = 0;
  dindex = 0;
  packed[0] = 0;
  packed[1] = 0;
  packed[2] = 0;
  packed[3] = 0;
}

void najeInst(CELL opcode) {
  if (packMode == 0)
    najeStore(0, opcode);
  else {
    if (pindex == 4) {
      najeSync();
    }

    packed[pindex] = opcode;
    pindex++;

    switch (opcode) {
      case 7:
      case 8:
      case 9:
      case 10:
      case 25:
      case 26: najeSync();
               break;
      default: break;
    }
  }
}

void najeData(CELL type, CELL data) {
  if (packMode == 0)
    najeStore(type, data);
  else {
    dataList[dindex] = data;
    dataType[dindex] = type;
    dindex++;
  }
}

void najeAssemble(char *source) {
  CELL i;
  char *token;
  char *rest;
  char *ptr = source;

  char relevant[3];
  relevant[0] = 0;
  relevant[1] = 0;
  relevant[2] = 0;

  if (strlen(source) == 0)
    return;

  token = strtok_r(ptr, " ,", &rest);
  ptr = rest;
  relevant[0] = (char)token[0];
  relevant[1] = (char)token[1];

  /* Labels start with : */
  if (relevant[0] == ':') {
    najeSync();
    najeAddLabel((char *)token + 1, latest);
  }

  /* Directives start with . */
  if (relevant[0] == '.') {
    switch (relevant[1]) {
      case 'r': /* .reference */
                token = strtok_r(ptr, " ,", &rest);
                if (pass == 0) {
                  najeData(1, -9999);
                } else {
                  najeData(-1, najeLookup((char *) token));
		  najeRefCount[najeLookupPtr((char *) token)]++;
		}
                break;
      case 'c': /* .comment */
                break;
      case 'd': /* .data */
                token = strtok_r(ptr, " ,", &rest);
                najeSync();
                najeData(0, atoi(token));
                najeSync();
                break;
      case 'o': /* .output */
                token = strtok_r(ptr, " ,", &rest);
                strcpy(outputName, token);
                break;
      case 'p': /* set packed mode */
                packMode = 1;
                break;
      case 'u': /* set unpacked mode */
                najeSync();
                packMode = 0;
                break;
      case 'a': /* .allocate */
                token = strtok_r(ptr, " ,", &rest);
                i = atoi(token);
                najeSync();
                while (i > 0) {
                  najeData(0, 0);
                  i--;
                }
                najeSync();
                break;
      case 's': /* .string */
                token = strtok_r(ptr, "\n", &rest);
                i = 0;
                najeSync();
                while (i < strlen(token)) {
                  najeData(0, token[i]);
                  i++;
                }
                najeData(0, 0);
                najeSync();
                break;
    }
  }


  /* Instructions */
  if (strcmp(relevant, "no") == 0)
    najeInst(0);
  if (strcmp(relevant, "li") == 0) {
    token = strtok_r(ptr, " ,", &rest);
    najeInst(1);
    if (token[0] == '&') {
      if (pass == 0) {
        najeData(1, -9999);
      } else {
        najeData(-1, najeLookup((char *) token+1));
        najeRefCount[najeLookupPtr((char *) token+1)]++;
      }
    } else {
      najeData(0, atoi(token));
    }
  }
  if (strcmp(relevant, "du") == 0)
    najeInst(2);
  if (strcmp(relevant, "dr") == 0)
    najeInst(3);
  if (strcmp(relevant, "sw") == 0)
    najeInst(4);
  if (strcmp(relevant, "pu") == 0)
    najeInst(5);
  if (strcmp(relevant, "po") == 0)
    najeInst(6);
  if (strcmp(relevant, "ju") == 0)
    najeInst(7);
  if (strcmp(relevant, "ca") == 0)
    najeInst(8);
  if (strcmp(relevant, "cc") == 0)
    najeInst(9);
  if (strcmp(relevant, "re") == 0)
    najeInst(10);
  if (strcmp(relevant, "eq") == 0)
    najeInst(11);
  if (strcmp(relevant, "ne") == 0)
    najeInst(12);
  if (strcmp(relevant, "lt") == 0)
    najeInst(13);
  if (strcmp(relevant, "gt") == 0)
    najeInst(14);
  if (strcmp(relevant, "fe") == 0)
    najeInst(15);
  if (strcmp(relevant, "st") == 0)
    najeInst(16);
  if (strcmp(relevant, "ad") == 0)
    najeInst(17);
  if (strcmp(relevant, "su") == 0)
    najeInst(18);
  if (strcmp(relevant, "mu") == 0)
    najeInst(19);
  if (strcmp(relevant, "di") == 0)
    najeInst(20);
  if (strcmp(relevant, "an") == 0)
    najeInst(21);
  if (strcmp(relevant, "or") == 0)
    najeInst(22);
  if (strcmp(relevant, "xo") == 0)
    najeInst(23);
  if (strcmp(relevant, "sh") == 0)
    najeInst(24);
  if (strcmp(relevant, "zr") == 0)
    najeInst(25);
  if (strcmp(relevant, "en") == 0)
    najeInst(26);
}

void prepare() {
  if (pass == 0)
    np = 0;
  latest = 0;
  packMode = 1;

  strcpy(outputName, "ngaImage");

  /* assemble the standard preamble (a jump to :main) */
  najeInst(1);  /* LIT */
  najeData(0, 0);  /* placeholder */
  najeInst(7);  /* JUMP */
}


void finish() {
  CELL entry = najeLookup("main");
  memory[1] = entry;
}


void read_line(FILE *file, char *line_buffer) {
  if (file == NULL) {
    printf("Error: file pointer is null.");
    exit(1);
  }

  if (line_buffer == NULL) {
    printf("Error allocating memory for line buffer.");
    exit(1);
  }

  int ch = getc(file);
  CELL count = 0;

  while ((ch != '\n') && (ch != EOF)) {
    line_buffer[count] = ch;
    count++;
    ch = getc(file);
  }

  line_buffer[count] = '\0';
}


void process_file(char *fname) {
  char source[64000];

  FILE *fp;

  fp = fopen(fname, "r");
  if (fp == NULL)
    return;

  while (!feof(fp)) {
    read_line(fp, source);
    najeAssemble(source);
  }

  fclose(fp);
}

void save() {
  FILE *fp;

  if ((fp = fopen(outputName, "wb")) == NULL) {
    printf("Unable to save the ngaImage!\n");
    exit(2);
  }

  fwrite(&memory, sizeof(CELL), latest, fp);
  fclose(fp);
}

CELL main(int argc, char **argv) {
  CELL i;

  pass = 0;
  prepare();
    process_file(argv[1]);
    najeSync();
  finish();

  pass = 1;
  prepare();
    process_file(argv[1]);
    najeSync();
  finish();

  save();
  najeWriteMap();

#ifdef DEBUG
  printf("\nBytecode\n[");
  for (i = 0; i < latest; i++)
    printf("%d, ", memory[i]);
  printf("]\nLabels\n");
  for (i = 0; i < np; i++)
    printf("%s^%d.%d ", najeLabels[i], najePointers[i], najeRefCount[i]);
  printf("\n");

  printf("%d cells written to %s\n", latest, outputName);
#endif

  return 0;
}
````
