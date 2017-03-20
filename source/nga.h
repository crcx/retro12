#define CELL         int32_t
#define IMAGE_SIZE   524288
#define ADDRESSES    128
#define STACK_DEPTH  32
typedef void (*Handler)(void);
CELL address[ADDRESSES];
CELL data[STACK_DEPTH];
void inst_add();
void inst_and();
void inst_call();
void inst_ccall();
void inst_divmod();
void inst_drop();
void inst_dup();
void inst_end();
void inst_eq();
void inst_fetch();
void inst_gt();
void inst_jump();
void inst_lit();
void inst_lt();
void inst_mul();
void inst_neq();
void inst_nop();
void inst_or();
void inst_pop();
void inst_push();
void inst_return();
void inst_shift();
void inst_store();
void inst_sub();
void inst_swap();
void inst_xor();
void inst_zret();
CELL ngaLoadImage(char *imageFile);
void ngaPrepare();
void ngaProcessOpcode(CELL opcode);
void ngaProcessPackedOpcodes(int opcode);
int ngaValidatePackedOpcodes(CELL opcode);
extern CELL sp, rp, ip;
extern CELL memory[IMAGE_SIZE];
