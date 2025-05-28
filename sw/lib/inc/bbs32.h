#pragma once

#include <stdint.h>
#include "config.h"


#define BBS32_P_REG_OFFSET          0x000
#define BBS32_Q_REG_OFFSET          0x004
#define BBS32_SEED_REG_OFFSET       0x008
#define BBS32_CONTROL_REG_OFFSET    0x00C
#define BBS32_M_LSB_REG_OFFSET      0x010
#define BBS32_M_MSB_REG_OFFSET      0x014
#define BBS32_RESULT_REG_OFFSET     0x018
#define BBS32_STATUS_REG_OFFSET     0x01C

#define BBS32_STATUS_M_VALID        ((uint32_t)0x01u)
#define BBS32_STATUS_RESULT_VALID   ((uint32_t)(1u << 8u))

#define BBS32_CONTROL_START         ((uint32_t)0x01u)
#define BBS32_CONTROL_KEEP_M        ((uint32_t)0x02u)
#define BBS32_CONTROL_USE_XNEXT     ((uint32_t)0x04u)

//Write
void bbs32_write_pq(uint32_t p, uint32_t q);
void bbs32_write_seed(uint32_t seed);

//Control
void bbs32_first_run();
void bbs32_next_run();
void bbs32_updated_seed_run();
void bbs32_updated_all_run();
void bbs32_wait_ready();
void bbs32_wait_not_ready();

//Read
uint32_t bbs32_read_result();
//For debug only:
uint32_t bbs32_read_seed();