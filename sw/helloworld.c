// Copyright (c) 2024 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0/
//
// Authors:
// - Philippe Sauter <phsauter@iis.ee.ethz.ch>

#include "uart.h"
#include "print.h"
#include "timer.h"
#include "gpio.h"
#include "util.h"

#include "bbs32.h"

/// @brief Example integer square root
/// @return integer square root of n
uint32_t isqrt(uint32_t n) {
    uint32_t res = 0;
    uint32_t bit = (uint32_t)1 << 30;

    while (bit > n) bit >>= 2;

    while (bit) {
        if (n >= res + bit) {
            n -= res + bit;
            res = (res >> 1) + bit;
        } else {
            res >>= 1;
        }
        bit >>= 2;
    }
    return res;
}

int main() {
    uart_init(); // setup the uart peripheral

    // simple printf support (only prints text and hex numbers)
    printf("Hello World!\n");
    // wait until uart has finished sending
    uart_write_flush();

    // // toggling some GPIOs
    // gpio_set_direction(0xFFFF, 0x000F); // lowest four as outputs
    // gpio_write(0x0A);  // ready output pattern
    // gpio_enable(0xFF); // enable lowest eight
    // // wait a few cycles to give GPIO signal time to propagate
    // asm volatile ("nop; nop; nop; nop; nop;");
    // printf("GPIO (expect 0xA0): 0x%x\n", gpio_read());

    // gpio_toggle(0x0F); // toggle lower 8 GPIOs
    // asm volatile ("nop; nop; nop; nop; nop;");
    // printf("GPIO (expect 0x50): 0x%x\n", gpio_read());
    // uart_write_flush();

    // // doing some compute
    // uint32_t start = get_mcycle();
    // uint32_t res   = isqrt(1234567890UL);
    // uint32_t end   = get_mcycle();
    // printf("Result: 0x%x, Cycles: 0x%x\n", res, end - start);
    // uart_write_flush();

    // // using the timer
    // printf("Tick\n");
    // sleep_ms(10);
    // printf("Tock\n");
    // uart_write_flush();

    // //Simple check check user periphery
    // bbs32_write_seed(0xdeadbeef);
    // uint32_t read_res = bbs32_read_seed();
    // if (read_res != 0xdeadbeef) {
    //     printf("ERROR: value 0x%x\n", read_res);
    // } 
    // else {
    //     printf("Success\n");
    // }
    // uart_write_flush();

    //Write P, Q, Seed
    uint32_t res = 0u;
    bbs32_write_pq(29711, 45543);
    bbs32_write_seed(56686);
    bbs32_first_run();
    bbs32_wait_ready();
    res = bbs32_read_result();
    printf("Result 0x%x", res);
    if (res != 0x6E341593) printf("--> Unexpected result\n");
    else                   printf("--> Expected result\n");
    uart_write_flush();

    bbs32_next_run();
    bbs32_wait_ready();
    res = bbs32_read_result();
    printf("Result 0x%x", res);
    if (res != 0xE62F5EBC) printf("--> Unexpected result\n");
    else                   printf("--> Expected result\n");
    uart_write_flush();

    return 1;
}
