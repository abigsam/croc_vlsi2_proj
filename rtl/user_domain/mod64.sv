

module mod64 (
    input  logic clk,
    input  logic nrst,
    input  logic en,
    input  logic [63:0] din,
    input  logic [63:0] m,
    output logic rdy,
    output logic [63:0] mod_out
);

timeunit 1ns;
timeprecision 1ps;

//Local parameters ********************************************************************************
localparam int DATA_WIDTH = 64;
localparam int CNT_WIDTH = $clog2(DATA_WIDTH);


//Variables ***************************************************************************************
logic ready_reg, ready_w;
logic [63:0] shift_reg, shift_reg_w;
logic shift_en_w, shift_load_w, shift_load_reg;
logic shift_dir_w, shift_dir_reg;
logic [CNT_WIDTH-1 : 0] bit_cnt_reg, bit_cnt_w;
logic [64:0] sub_reg, sub_w, sub_a_w;
logic [63:0] acc_reg;
logic sub_en_w, acc_en_w, sub_use_in_w, sub_use_in_reg, sub_sign_bit;
logic out_en_w;
logic [63:0] out_reg, out_w;
logic out_use_in_w, out_use_in_reg;
logic m_msb_w;


//Shift register **********************************************************************************
always_ff @(posedge clk or negedge nrst) begin
    if (!nrst)
        shift_reg <= '0;
    else if (shift_en_w)
        shift_reg <= shift_reg_w;
end

always_comb shift_reg_w = (shift_load_reg) ? m :
                          (shift_dir_reg)  ? ({shift_reg[62:0], 1'b0}) : //Shift Left
                                             ({1'b0, shift_reg[63:1]});  //Shift Right
always_comb m_msb_w = shift_reg[63];


//Bit counter *************************************************************************************
always_ff @(posedge clk or negedge nrst) begin
    if (!nrst)
        bit_cnt_reg <= '0;
    else if (shift_en_w)
        bit_cnt_reg <= bit_cnt_w;
end

always_comb bit_cnt_w = (shift_load_reg) ? 'd0 :
                        (shift_dir_reg)  ? (bit_cnt_reg + 'd1) :
                                           (bit_cnt_reg - 'd1);


//Subtraction *************************************************************************************
always_ff @(posedge clk or negedge nrst) begin
    if (!nrst)
        sub_reg <= '0;
    else if (sub_en_w)
        sub_reg <= sub_w;
end

always_comb sub_a_w = (sub_use_in_reg) ? {1'b0, din} : acc_reg;
always_comb sub_w = sub_a_w - {1'b0, shift_reg};
always_comb sub_sign_bit = sub_reg[64];


//Accumulator *************************************************************************************
always_ff @(posedge clk or negedge nrst) begin
    if (!nrst)
        acc_reg <= '0;
    else if (acc_en_w)
        acc_reg <= sub_reg[63:0];
end


//Result register *********************************************************************************
always_ff @(posedge clk or negedge nrst) begin
    if (!nrst)
        out_reg <= '0;
    else if (out_en_w)
        out_reg <= out_w;
end

always_comb out_w = (out_use_in_reg) ? din : acc_reg;


//FSM *********************************************************************************************
typedef enum logic[4:0] { 
    IDLE = '0,
    LOAD_SHIFT,
    RUN_SUB_CHEK_IN,
    SUB_CHEK_IN,

    CHECK_M_MSB,
    SHIFT_M_LEFT,

    RUN_SUB_IN_M,
    SUB_IN_M_CHECK,
    SHIFT_M_RIGHT,
    
    RET_RESULT,
    READY
    
} fsm_t;

fsm_t state, next_state;

always_ff @(posedge clk or negedge nrst) begin
    if (!nrst) begin
        state <= IDLE;
        ready_reg <= '0;
        shift_dir_reg <= '0;
        shift_load_reg <= '0;
        sub_use_in_reg <= '0;
        out_use_in_reg <= '0;
    end else begin
        state <= next_state;
        ready_reg <= ready_w;
        shift_dir_reg <= shift_dir_w;
        shift_load_reg <= shift_load_w;
        sub_use_in_reg <= sub_use_in_w;
        out_use_in_reg <= out_use_in_w;
    end
end

always_comb begin
    next_state = state;
    //
    case(state)
        IDLE: begin
            if (en)
                next_state = LOAD_SHIFT;
        end
        
        LOAD_SHIFT: next_state = RUN_SUB_CHEK_IN;

        RUN_SUB_CHEK_IN: next_state = SUB_CHEK_IN;

        SUB_CHEK_IN: begin
            if (sub_sign_bit)
                next_state = RET_RESULT; //Negative value, IN is bigger then M, return IN
            else
                next_state = CHECK_M_MSB;
        end

        CHECK_M_MSB: begin
            if (m_msb_w)
                next_state = RUN_SUB_IN_M;
            else if (bit_cnt_reg == (DATA_WIDTH-1))
                next_state = RET_RESULT;    //Probably M is "0", return IN
            else
                next_state = SHIFT_M_LEFT;
        end

        SHIFT_M_LEFT: next_state = CHECK_M_MSB;

        RUN_SUB_IN_M: next_state = SUB_IN_M_CHECK;

        SUB_IN_M_CHECK: begin
            if (sub_sign_bit)
                if (bit_cnt_reg == '0)
                    next_state = RET_RESULT;    //MOD operation ends, return ACC value
                else
                    next_state = SHIFT_M_RIGHT;
            else
                next_state = RUN_SUB_IN_M;
        end
        
        SHIFT_M_RIGHT: next_state = RUN_SUB_IN_M;

        RET_RESULT: next_state = READY;

        READY: begin
            if (!en)
                next_state = IDLE;
        end

        default: next_state = IDLE;
    endcase
end


always_comb begin
    ready_w = ready_reg;
    shift_dir_w = shift_dir_reg;
    shift_load_w = shift_load_reg;
    sub_use_in_w = sub_use_in_reg;
    out_use_in_w = out_use_in_reg;

    shift_en_w = '0;
    sub_en_w = '0;
    acc_en_w = '0;
    out_en_w = '0;

    case(state)
        IDLE: begin
            ready_w = '0;
            shift_dir_w = '0;
            shift_load_w = '0;
            sub_use_in_w = '0;
            out_use_in_w = '0;
            if (en) begin
                shift_load_w = '1;
            end
        end

        LOAD_SHIFT: begin
            shift_en_w = '1;
            shift_load_w = '0;
            sub_use_in_w = '1;
        end

        RUN_SUB_CHEK_IN: begin
            sub_en_w = '1;
        end

        SUB_CHEK_IN: begin
            if (sub_sign_bit) begin
                out_use_in_w = '1;  //Negative value, IN is bigger then M, return IN
            end
            if (!sub_sign_bit) begin
                acc_en_w = '1;
            end
        end

        CHECK_M_MSB: begin
            if (m_msb_w) begin
                sub_use_in_w = '0;
            end else if (bit_cnt_reg == (DATA_WIDTH-1)) begin
                out_use_in_w = '1;  //Probably M is "0", return IN
            end else begin
                shift_load_w = '0;
                shift_dir_w = '1; //Shift left
            end
        end

        SHIFT_M_LEFT: begin
            shift_en_w = '1;
        end

        RUN_SUB_IN_M: begin
            sub_en_w = '1;
        end

        SUB_IN_M_CHECK: begin
            if (sub_sign_bit) begin
                if (bit_cnt_reg == '0) begin
                    out_use_in_w = '0;  //MOD operation ends, return ACC value
                end else begin
                    shift_load_w = '0;
                    shift_dir_w = '0;
                end
            end else begin
                sub_use_in_w = '0;
                acc_en_w = '1;
            end
        end

        SHIFT_M_RIGHT: begin
            shift_en_w = '1;
        end

        RET_RESULT: begin
            out_en_w = '1;
            out_use_in_w = '0;
        end

        READY: begin
            ready_w = '1;
        end

        default: begin

        end
    endcase
end


//Outputs *****************************************************************************************
always_comb rdy = ready_reg;
always_comb mod_out = out_reg;


endmodule