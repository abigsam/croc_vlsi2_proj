

module mul32 (
    input  logic clk,
    input  logic nrst,
    //
    input  logic en,
    output logic ready,
    //
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic [63:0] result
);
    
//Local parameters
localparam int OPERAND_BITS = 32;
localparam int BIT_CNT_WIDHT = $clog2(OPERAND_BITS);


//Variables
logic [63:0] areg, areg_w, areg_in_w, areg_shift_left_w;
logic [63:0] accreg, accreg_w;
logic [31:0] breg, breg_w, breg_shift_right_w;
logic [BIT_CNT_WIDHT-1 : 0] bit_cnt, bit_cnt_w;
logic bit_cnt_last;
//
logic load_w, shift_w, acc_en_w, acc_rst_w;



//Areg ********************************************************************************************
always_ff @(posedge clk or negedge nrst) begin
    if (!nrst)
        areg <= '0;
    else
        areg <= areg_w;
end
//
always_comb areg_w = (load_w)  ?  areg_in_w :
                     (shift_w) ? areg_shift_left_w : areg;
//
always_comb areg_in_w = {{OPERAND_BITS{1'b0}}, a};
always_comb areg_shift_left_w = {areg[62:0], 1'b0};
//


//Breg ********************************************************************************************
always_ff @(posedge clk or negedge nrst) begin
    if (!nrst)
        breg <= '0;
    else
        breg <= breg_w;
end
//
always_comb breg_w = (load_w)  ? b :
                     (shift_w) ? breg_shift_right_w : breg;
always_comb breg_shift_right_w = {1'b0, breg[31:1]};


//Accumulator *************************************************************************************
always_ff @(posedge clk) begin
    if (acc_rst_w)
        accreg <= '0;
    else if (acc_en_w)
        accreg <= accreg_w;
end
//
always_comb accreg_w = accreg + areg;


//Bitcounter **************************************************************************************
always_ff @(posedge clk or negedge nrst) begin
    if (!nrst)
        bit_cnt <= '0;
    else
        bit_cnt <= bit_cnt_w;
end
//
always_comb bit_cnt_w = (load_w)  ? (OPERAND_BITS-1) :
                        (shift_w) ? (bit_cnt - 'd1)  : bit_cnt;
//
//Detect last
always_ff @(posedge clk or negedge nrst) begin
    if (!nrst)
        bit_cnt_last <= '0;
    else
        bit_cnt_last <= (bit_cnt == '0);
end


//Main FSM ****************************************************************************************
typedef enum logic [3:0] { 
    IDLE = '0,
    LOAD,
    CHECK_B_LSB,
    CHECK_LAST_BIT,
    SHIFT_DATA,
    READY
} fsm_t;

fsm_t state, next_state;
logic ready_w, ready_reg;


always_ff @(posedge clk or negedge nrst) begin
    if (!nrst) begin
        state <= IDLE;
        ready_reg <= '0;
    end else begin
        state <= next_state;
        ready_reg <= ready_w;
    end
end


always_comb begin
    next_state = state;
    //
    case(state)
        IDLE: begin
            if (en)
                next_state = LOAD;
        end

        LOAD: begin
            next_state = CHECK_B_LSB;
        end

        CHECK_B_LSB: begin
            next_state = CHECK_LAST_BIT;
        end

        CHECK_LAST_BIT: begin
            if (bit_cnt_last)
                next_state = READY;
            else
                next_state = SHIFT_DATA;
        end

        SHIFT_DATA: begin
            next_state = CHECK_B_LSB;
        end

        READY: begin
            if (!en)
                next_state = IDLE;
        end

        default: begin
            next_state = IDLE;
        end
    endcase
end


always_comb begin
    ready_w = ready_reg;
    load_w = '0;
    shift_w = '0;
    acc_en_w = '0;
    acc_rst_w = '0;
    //
    case(state)
        IDLE: begin
            ready_w = '0;
        end

        LOAD: begin
            load_w = '1;
            acc_rst_w = '1;
        end

        CHECK_B_LSB: begin
            if (breg[0]) begin
                acc_en_w = '1;
            end
        end

        CHECK_LAST_BIT: begin
            
        end

        SHIFT_DATA: begin
            shift_w = '1;
        end

        READY: begin
            ready_w = '1;
        end

        default: begin
            ready_w = '0;
        end

    endcase
end


//Outputs *****************************************************************************************
always_comb result = accreg;
always_comb ready = ready_reg;

endmodule