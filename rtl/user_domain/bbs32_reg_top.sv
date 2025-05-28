
`include "common_cells/registers.svh"

module bbs32_reg_top import bbs32_reg_pkg::*; #(
    /// The OBI configuration for all ports.
    parameter obi_pkg::obi_cfg_t ObiCfg = obi_pkg::ObiDefaultConfig,
    /// OBI request type
    parameter type obi_req_t = logic,
    /// OBI response type
    parameter type obi_rsp_t = logic
)(
    /// Clock
    input  logic clk_i,
    /// Active-low reset
    input  logic rst_ni,

    /// Connection to Obi
    /// OBI request interface : a.addr, a.we, a.be, a.wdata, a.aid | rready, req
    input  obi_req_t  obi_req_i,
    /// OBI response interface : r.rdata, r.rid, r.obi_err | gnt, rvalid
    output obi_rsp_t obi_rsp_o,

    /// Communication with control logic
    /// Signals from registers to logic
    output bbs32_reg2hw_t reg2hw,
    /// Signals from logic to registers
    input  bbs32_hw2reg_t hw2reg
);


////////////////////////////////////////////////////////////////////////////////////////////////////
// Obi Preparations //
////////////////////////////////////////////////////////////////////////////////////////////////////

// Signals for the OBI response
logic                           valid_d, valid_q;         // delayed to the response phase
logic                           we_d, we_q;               // delayed to the response phase
logic                           req_d, req_q;             // delayed to the response phase
logic [AddressWidth-1:0]        write_addr;               // in request phase (word addr)
logic [AddressWidth-1:0]        read_addr_d, read_addr_q; // delayed to the response phase (word addr)
logic [ObiCfg.IdWidth-1:0]      id_d, id_q;               // delayed to the response phase
logic                           obi_err;
logic                           w_err_d, w_err_q;         // delay write error to response phase
// signals used in read/write for register
logic [ObiCfg.DataWidth-1:0]    obi_rdata, obi_wdata;
logic                           obi_read_request, obi_write_request;

// OBI rsp Assignment
always_comb begin
    obi_rsp_o              = '0;
    obi_rsp_o.r.rdata      = obi_rdata;
    obi_rsp_o.r.rid        = id_q;
    obi_rsp_o.r.err        = obi_err;
    obi_rsp_o.gnt          = obi_req_i.req;
    obi_rsp_o.rvalid       = valid_q;
end

// internally used signals
assign obi_wdata         = obi_req_i.a.wdata;
assign obi_read_request  = req_q & ~we_q;                  // in response phase (one cycle later)
assign obi_write_request = obi_req_i.req & obi_req_i.a.we; // in request phase (same cycle)

// id, valid and address handling
assign id_d          = obi_req_i.a.aid;
assign valid_d       = obi_req_i.req;
assign write_addr    = obi_req_i.a.addr[AddressWidth-1:2]; // write in same cycle
assign read_addr_d   = obi_req_i.a.addr[AddressWidth-1:2]; // delay read to response phase
assign we_d          = obi_req_i.a.we;
assign req_d         = obi_req_i.req;

    // FF for the obi rsp signals (id, valid, address, we and req)
    `FF(id_q, id_d, '0, clk_i, rst_ni)
    `FF(valid_q, valid_d, '0, clk_i, rst_ni)
    `FF(read_addr_q, read_addr_d, '0, clk_i, rst_ni)
    `FF(req_q, req_d, '0, clk_i, rst_ni)
    `FF(we_q, we_d, '0, clk_i, rst_ni)
    `FF(w_err_q, w_err_d, '0, clk_i, rst_ni)

////////////////////////////////////////////////////////////////////////////////////////////////////
// Registers //
////////////////////////////////////////////////////////////////////////////////////////////////////
// bits in register organized together to ease read/write
typedef struct packed {
    logic result_valid; //Reg #7[8]
    logic m_valid;      //Reg #7[0]
    logic [31:0] rand_word;    //Reg #6
    logic [31:0] m_msb; //Reg #5
    logic [31:0] m_lsb; //Reg #4
    //
    logic use_xnext;    //Reg #3[2]
    logic keep_m;       //Reg #3[1]
    logic start;        //Reg #3[0]
    logic [31:0] seed;  //Reg #2
    logic [31:0] q;     //Reg #1
    logic [31:0] p;     //Reg #0
} gpio_reg_fields_t;

// register signals
gpio_reg_fields_t reg_d, reg_q;
`FF(reg_q, reg_d, '0, clk_i, rst_ni)

gpio_reg_fields_t new_reg; // new value of regs if there is no OBI transaction

////////////////////////////////////////////////////////////////////////////////////////////////////
// COMB LOGIC //
////////////////////////////////////////////////////////////////////////////////////////////////////

// bit enable/strobe; defines which bits are written to by wdata of the OBI request
logic [ObiCfg.DataWidth-1:0] bit_mask;
for (genvar i = 0; unsigned'(i) < ObiCfg.DataWidth/8; ++i ) begin : gen_write_mask
    assign bit_mask[8*i +: 8] = {8{obi_req_i.a.be[i]}};
end

// output data from internal register
always_comb begin
    reg2hw.use_xnext    = reg_q.use_xnext;   //Reg #3[2]
    reg2hw.keep_m       = reg_q.keep_m;      //Reg #3[1]
    reg2hw.start        = reg_q.start;       //Reg #3[0]
    reg2hw.seed         = reg_q.seed;        //Reg #2
    reg2hw.q            = reg_q.q;           //Reg #1
    reg2hw.p            = reg_q.p;           //Reg #0
end

// update registers
always_comb begin
    // defaults
    obi_rdata  = 32'h0;   // default value for read
    obi_err    = w_err_q;
    w_err_d    = 1'b0;
    new_reg    = reg_q;   // registers stay the same

    // update OUT from hw2reg if set to valid
    if (hw2reg.m_valid_upd) begin
        new_reg.m_valid = hw2reg.m_valid;
        new_reg.m_msb = hw2reg.m_msb;
        new_reg.m_lsb = hw2reg.m_lsb;
    end
    if (hw2reg.result_valid_upd) begin
        new_reg.result_valid = hw2reg.result_valid;
        new_reg.rand_word = hw2reg.rand_word;
    end

    // commit changes
    reg_d      = new_reg; // update regs without OBI transaction

    //---------------------------------------------------------------------------------
    // WRITE
    //---------------------------------------------------------------------------------
    if (obi_write_request) begin
        obi_err = 1'b0;
        case ({write_addr, 2'b00})
            BBS32_P_OFFSET: begin
                reg_d.p = bit_mask & obi_wdata;
            end

            BBS32_Q_OFFSET: begin
                reg_d.q = bit_mask & obi_wdata;
            end

            BBS32_SEED_OFFSET: begin
                reg_d.seed = bit_mask & obi_wdata;
            end

            BBS32_CONTROL_OFFSET: begin
                reg_d.start     = obi_wdata[0];
                reg_d.keep_m    = obi_wdata[1];
                reg_d.use_xnext = obi_wdata[2];
            end

            BBS32_M_LSB_OFFSET: begin
                //Read only
            end

            BBS32_M_MSB_OFFSET: begin
                //Read only
            end

            BBS32_RESULT_OFFSET: begin
                //Read only
            end

            BBS32_STATUS_OFFSET: begin
                //Read only
            end

            default: begin
                w_err_d = 1'b1; // unmapped register access
            end
        endcase
    end

    //---------------------------------------------------------------------------------
    // READ
    //---------------------------------------------------------------------------------
    if (obi_read_request) begin
        obi_err = 1'b0;
        case ({read_addr_q, 2'b00})
            BBS32_P_OFFSET: begin
                obi_rdata = reg_q.p;
            end

            BBS32_Q_OFFSET: begin
                obi_rdata = reg_q.q;
            end

            BBS32_SEED_OFFSET: begin
                obi_rdata = reg_q.seed;
            end

            BBS32_CONTROL_OFFSET: begin
                obi_rdata = '0;
                obi_rdata[0] = reg_q.start;
                obi_rdata[1] = reg_q.keep_m;
                obi_rdata[2] = reg_q.use_xnext;
            end

            BBS32_M_LSB_OFFSET: begin
                obi_rdata = reg_q.m_lsb;
            end

            BBS32_M_MSB_OFFSET: begin
                obi_rdata = reg_q.m_msb;
            end

            BBS32_RESULT_OFFSET: begin
                obi_rdata = reg_q.rand_word;
            end

            BBS32_STATUS_OFFSET: begin
                obi_rdata = '0;
                obi_rdata[0] = reg_q.m_valid;
                obi_rdata[8] = reg_q.result_valid;
            end

            default: begin
                obi_rdata = 32'hBADCAB1E;  // Return error value in devmode for unmapped reads
                obi_err   = 1'b1;
            end
        endcase
    end

end


endmodule