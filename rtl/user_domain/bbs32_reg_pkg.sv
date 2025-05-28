


package bbs32_reg_pkg;

    // Address width within this peripheral used for address decoding (peripheral occupies 4KB)
    parameter int AddressWidth = 12;

    //-----------------------------------------------------------------------------------------------
    // Signals from registers to logic
    //-----------------------------------------------------------------------------------------------
    typedef struct packed {
        logic use_xnext;    //Reg #3[2]
        logic keep_m;       //Reg #3[1]
        logic start;        //Reg #3[0]
        logic [31:0] seed;  //Reg #2
        logic [31:0] q;     //Reg #1
        logic [31:0] p;     //Reg #0
    } bbs32_reg2hw_t;


    //-----------------------------------------------------------------------------------------------
    // Signals from logic to registers
    //-----------------------------------------------------------------------------------------------
    typedef struct packed {
        logic m_valid_upd;
        logic result_valid_upd;
        //
        logic result_valid; //Reg #7[8]
        logic m_valid;      //Reg #7[0]
        logic [31:0] rand_word;    //Reg #6
        logic [31:0] m_msb; //Reg #5
        logic [31:0] m_lsb; //Reg #4
    } bbs32_hw2reg_t;

    //-----------------------------------------------------------------------------------------------
    // Offsets
    //-----------------------------------------------------------------------------------------------
    // Register address offsets from GPIO base address
    parameter logic [AddressWidth-1:0] BBS32_P_OFFSET       = 11'h00;
    parameter logic [AddressWidth-1:0] BBS32_Q_OFFSET       = 11'h04;
    parameter logic [AddressWidth-1:0] BBS32_SEED_OFFSET    = 11'h08;
    parameter logic [AddressWidth-1:0] BBS32_CONTROL_OFFSET = 11'h0C;
    parameter logic [AddressWidth-1:0] BBS32_M_LSB_OFFSET   = 11'h10;
    parameter logic [AddressWidth-1:0] BBS32_M_MSB_OFFSET   = 11'h14;
    parameter logic [AddressWidth-1:0] BBS32_RESULT_OFFSET  = 11'h18;
    parameter logic [AddressWidth-1:0] BBS32_STATUS_OFFSET  = 11'h1C;

endpackage