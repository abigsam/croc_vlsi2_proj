
#include "bbs32.h"
#include "util.h"
#include "config.h"


//Write
void bbs32_write_pq(uint32_t p, uint32_t q)
{
    *reg32(BBS32_BASE_ADDR, BBS32_P_REG_OFFSET) = p;
    *reg32(BBS32_BASE_ADDR, BBS32_Q_REG_OFFSET) = q;
}

void bbs32_write_seed(uint32_t seed)
{
    *reg32(BBS32_BASE_ADDR, BBS32_SEED_REG_OFFSET) = seed;
}

//P,Q,SEED should be already written to the registers
void bbs32_first_run() {
    *reg32(BBS32_BASE_ADDR, BBS32_CONTROL_REG_OFFSET) = 0x0;
    *reg32(BBS32_BASE_ADDR, BBS32_CONTROL_REG_OFFSET) = BBS32_CONTROL_START;
    bbs32_wait_not_ready();
}

void bbs32_next_run() {
    *reg32(BBS32_BASE_ADDR, BBS32_CONTROL_REG_OFFSET) = (BBS32_CONTROL_START | BBS32_CONTROL_KEEP_M | BBS32_CONTROL_USE_XNEXT);
    bbs32_wait_not_ready();
}

void bbs32_updated_seed_run() {
    *reg32(BBS32_BASE_ADDR, BBS32_CONTROL_REG_OFFSET) = (BBS32_CONTROL_START | BBS32_CONTROL_KEEP_M);
    bbs32_wait_not_ready();
}

void bbs32_updated_all_run() {
    *reg32(BBS32_BASE_ADDR, BBS32_CONTROL_REG_OFFSET) = (BBS32_CONTROL_START);
    bbs32_wait_not_ready();
}

void bbs32_wait_ready() {
    uint32_t tmp;
    do {
        tmp = *reg32(BBS32_BASE_ADDR, BBS32_STATUS_REG_OFFSET);
        tmp &= (BBS32_STATUS_M_VALID | BBS32_STATUS_RESULT_VALID);
    } while (tmp != (BBS32_STATUS_M_VALID | BBS32_STATUS_RESULT_VALID));
    //
    tmp = *reg32(BBS32_BASE_ADDR, BBS32_CONTROL_REG_OFFSET);
    tmp &= ~BBS32_CONTROL_START;
    *reg32(BBS32_BASE_ADDR, BBS32_CONTROL_REG_OFFSET) = tmp;
}

void bbs32_wait_not_ready()
{
    uint32_t tmp;
    do {
        tmp = *reg32(BBS32_BASE_ADDR, BBS32_STATUS_REG_OFFSET);
        tmp &= BBS32_STATUS_RESULT_VALID;
    } while (tmp == BBS32_STATUS_RESULT_VALID);
}


//Read
uint32_t bbs32_read_result()
{
    return (*reg32(BBS32_BASE_ADDR, BBS32_RESULT_REG_OFFSET));
}

//For debug only:
uint32_t bbs32_read_seed()
{
    return (*reg32(BBS32_BASE_ADDR, BBS32_SEED_REG_OFFSET));
}