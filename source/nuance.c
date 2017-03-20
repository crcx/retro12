#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
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
char reform[999];
void resetReform() {
  memset(reform, '\0', 999);
}
int cycle = 0;
int compile(char *source) {
  char *token;
  char *state;
  char prefix;
  int scratch;
  int i;
  int nest;
  int nmax;
  nmax = 0;
  nest = 0;
  printf(".comment %s\n", source);
  for (token = strtok_r(source, " ", &state); token != NULL; token = strtok_r(NULL, " ", &state)) {
    prefix = (char)token[0];
    switch (prefix) {
      case '\'':
        if (token[strlen(token) - 1] == '\'') {
          resetReform();
          memcpy(reform, &token[1], strlen(token) - 2);
          reform[strlen(token) - 2] = '\0';
          printf("  .string %s\n", reform);
        } else {
          resetReform();
          memset(reform, '\0', 999);
          memcpy(reform, &token[1], strlen(token) - 1);
          i = 0;
          while (i == 0) {
            strcat(reform, " ");
            token = strtok_r(NULL, " ", &state);
            if (token[strlen(token) - 1] == '\'' || token == NULL) {
              i = 1;
              token[strlen(token) - 1] = '\0';
              strcat(reform, token);
            }
            else
              strcat(reform, token);
          }
          printf("  .string %s\n", reform);
        }
        break;
      case '"':
        if (token[strlen(token) - 1] != '"') {
          i = 0;
          while (i == 0) {
            token = strtok_r(NULL, " ", &state);
            if (token[strlen(token) - 1] == '"' || token == NULL)
              i = 1;
          }
        }
        break;
      case ':':
        printf("%s\n", token);
        break;
      case '#':
        resetReform();
        memcpy(reform, &token[1], strlen(token) - 1);
        printf("  lit %s\n", (char *)token+1);
        break;
      case '~':
        resetReform();
        memcpy(reform, &token[1], strlen(token) - 1);
        printf("  .allocate %s\n", reform);
        break;
      case '&':
        resetReform();
        memcpy(reform, &token[1], strlen(token) - 1);
        printf("  lit &%s\n", reform);
        break;
      case '^':
        resetReform();
        memcpy(reform, &token[1], strlen(token) - 1);
        printf("  lit &%s\n  jump\n", reform);
        break;
      case '$':
        scratch = (int) token[1];
        printf("  lit %d\n", scratch);
        break;
      case '`':
        resetReform();
        memcpy(reform, &token[1], strlen(token) - 1);
        printf("  .data %s\n", reform);
        break;
      case '|':
        resetReform();
        memcpy(reform, &token[1], strlen(token) - 1);
        printf("  .ref %s\n", reform);
        break;
      default:
        if (strcmp(token, "[") == 0) {
          if (nmax > 0 && nest == 0)
            cycle = cycle + 1;
          nest = nest + 1;
          printf("  lit &%d<%d_s>\n", cycle, nest);
          printf("  lit &%d<%d_e>\n  jump\n", cycle, nest);
          printf(":%d<%d_s>\n", cycle, nest);
        } else if (strcmp(token, "]") == 0) {
          printf("  ret\n");
          printf(":%d<%d_e>\n", cycle, nest);
          if (nest > nmax)
            nmax = nest;
          nest = nest - 1;
        } else if (strcmp(token, "0;") == 0) {
          printf("  zret\n");
        } else if (strcmp(token, "push") == 0) {
          printf("  push\n");
        } else if (strcmp(token, "pop") == 0) {
          printf("  pop\n");
        } else {
          if (strcmp(token, ";") == 0)
            printf("  ret\n");
          else
            printf("  lit &%s\n  call\n", token);
        }
        break;
    }
  }
  cycle = cycle + 1;
  return 0;
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
  char ch = getc(file);
  int count = 0;
  while ((ch != '\n') && (ch != EOF)) {
    line_buffer[count] = ch;
    count++;
    ch = getc(file);
  }
  line_buffer[count] = '\0';
}
void parse(char *fname) {
  char source[64000];
  FILE *fp;
  fp = fopen(fname, "r");
  if (fp == NULL)
    return;
  while (!feof(fp)) {
    read_line(fp, source);
    compile(source);
  }
  fclose(fp);
}
int main(int argc, char **argv) {
  int i = 1;
  if (argc > 1) {
    while (i <= argc) {
      parse(argv[i++]);
    }
  }
  return 0;
}
