
`include "common_cells/registers.svh"

module bbs32_top #(
    /// The OBI configuration for all ports.
    parameter obi_pkg::obi_cfg_t ObiCfg = obi_pkg::ObiDefaultConfig,
    /// OBI request type
    parameter type obi_req_t         = logic,
    /// OBI response type
    parameter type obi_rsp_t         = logic
)(
    /// Primary input clock
    input  logic                 clk_i,
    /// Asynchronous active-low reset
    input  logic                 rst_ni,

    /// Control interface from interconnect (request).
    input  obi_req_t             obi_req_i,
    /// Control interface back into interconnect (response).
    output obi_rsp_t             obi_rsp_o
);

import bbs32_reg_pkg::*;


// Internal Signals
bbs32_reg2hw_t reg2hw; // Interface from Register to Internal Logic(HW)
bbs32_hw2reg_t hw2reg; // Interface from Internal Logic(HW) to Register


// Instantiate register file
bbs32_reg_top #(
    .obi_req_t(obi_req_t),
    .obi_rsp_t(obi_rsp_t)
) i_reg_file (
    .clk_i,
    .rst_ni,
    .obi_req_i,
    .obi_rsp_o,
    .reg2hw(reg2hw),
    .hw2reg(hw2reg)
);


logic [63:0] m_w;
logic m_valid_w, result_valid_w;

always_comb hw2reg.m_lsb = m_w[31:0];
always_comb hw2reg.m_msb = m_w[63:32];

always_comb hw2reg.m_valid      = m_valid_w;
always_comb hw2reg.result_valid = result_valid_w;

always_comb hw2reg.m_valid_upd      = m_valid_w;
always_comb hw2reg.result_valid_upd = result_valid_w | reg2hw.start;

//BBS32 module
bbs32 bbs32_i (
    .clk(clk_i),
    .nrst(rst_ni),
    //Inputs
    .seed(reg2hw.seed),
    .p(reg2hw.p),
    .q(reg2hw.q),
    .start(reg2hw.start),
    .keep_m(reg2hw.keep_m),
    .use_xnext(reg2hw.use_xnext),
    //Outputs
    .m(m_w),
    .result(hw2reg.rand_word),
    .m_valid(m_valid_w),
    .result_valid(result_valid_w)
);


endmodule