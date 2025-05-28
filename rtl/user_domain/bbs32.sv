

module bbs32 (
    input  logic clk,
    input  logic nrst,
    //Inputs
    input  logic [31:0] seed,
    input  logic [31:0] p,
    input  logic [31:0] q,
    input  logic start,
    input  logic keep_m,
    input  logic use_xnext,
    //Outputs
    output logic [63:0] m,
    output logic [31:0] result,
    output logic m_valid,
    output logic result_valid
);

//Local parameters
localparam int RESULT_BITS = 32;
localparam int BIT_CNT_WIDHT = $clog2(RESULT_BITS);


//Variables
logic [31:0] mux1, mux2, mux3;
logic [63:0] mod_out_w;
logic mod_ready_w;
logic use_seed_reg, use_seed_w, use_pq_reg, use_pq_w;
logic mul_ready_w;
logic [63:0] mul_result_w;
logic [63:0] m_reg, xnext_reg;
logic [31:0] result_reg, result_shift_reg;
logic m_load_w, result_load_w, result_shift_en_w;
logic random_bit_w;
logic [BIT_CNT_WIDHT-1 : 0] bit_cnt, bit_cnt_w;
logic bit_cnt_load_w, bit_cnt_count_w;
logic mul32_en_reg, mul32_en_w, mod64_en_reg, mod64_en_w;
logic m_valid_reg, m_valid_w, result_valid_reg, result_valid_w;
logic store_xnext_w;


//Input multiplexers ******************************************************************************
always_comb mux1 = (use_seed_reg) ? seed : xnext_reg[31:0];
always_comb mux2 = (use_pq_reg)   ? p : mux1;
always_comb mux3 = (use_pq_reg)   ? q : mux1;



//Multiplier **************************************************************************************
mul32 mul32_inst (
    .clk(clk),
    .nrst(nrst),
    .en(mul32_en_reg),
    .ready(mul_ready_w),
    .a(mux2),
    .b(mux3),
    .result(mul_result_w)
);


//MOD operation ***********************************************************************************
mod64 mod64_inst (
    .clk(clk),
    .nrst(nrst),
    .en(mod64_en_reg),
    .din(mul_result_w),
    .m(m_reg),
    .rdy(mod_ready_w),
    .mod_out(mod_out_w)
);


//Register for M value ****************************************************************************
always_ff @(posedge clk or negedge nrst) begin
    if (!nrst)
        m_reg <= '0;
    else if (m_load_w)
        m_reg <= mul_result_w;
end


//Register for result *****************************************************************************
always_ff @(posedge clk or negedge nrst) begin
    if (!nrst)
        result_reg <= '0;
    else if (result_load_w)
        result_reg <= result_shift_reg;
end


//Result shift ************************************************************************************
always_ff @(posedge clk or negedge nrst) begin
    if (!nrst)
        result_shift_reg <= '0;
    else if (result_shift_en_w)
        result_shift_reg <= {result_shift_reg[30:0], random_bit_w};
end

always_comb random_bit_w = mod_out_w[0];


//Save XNEXT value ********************************************************************************
always_ff @(posedge clk or negedge nrst) begin
    if (!nrst)
        xnext_reg <= '0;
    else if (store_xnext_w)
        xnext_reg <= mod_out_w;
end


//Main FSM ****************************************************************************************
typedef enum logic [4:0] { 
    IDLE = '0,
    CALC_M,
    WAIT_M,
    SET_M_VALID,
    CALC_SEED_SQ,
    WAIT_SEED_SQ,
    CALC_MOD,
    WAIT_MOD_READY,
    GET_RANDOM_BIT,
    CHECK_BIT_COUNTER,
    CALC_XNEXT,
    WAIT_XNEXT,
    READY
} fsm_t;

fsm_t state, next_state;

always_ff @(posedge clk or negedge nrst) begin
    if (!nrst) begin
        state <= IDLE;
        m_valid_reg <= '0;
        result_valid_reg <= '0;
        use_seed_reg <= '0;
        use_pq_reg <= '0;
        mul32_en_reg <= '0;
        mod64_en_reg <= '0;
        bit_cnt <= '0;
    end else begin
        state <= next_state;
        m_valid_reg <= m_valid_w;
        result_valid_reg <= result_valid_w;
        use_seed_reg <= use_seed_w;
        use_pq_reg <= use_pq_w;
        mul32_en_reg <= mul32_en_w;
        mod64_en_reg <= mod64_en_w;
        bit_cnt <= bit_cnt_w;
    end
end

always_comb begin
    next_state = state;
    //
    case(state)
        IDLE: begin
            if (start) begin
                if (!m_valid_reg)       next_state = CALC_M;
                else if (!keep_m)       next_state = CALC_M;
                else if (!use_xnext)    next_state = CALC_SEED_SQ;
                else                    next_state = CALC_XNEXT;
            end
        end

        CALC_M: begin
            next_state = WAIT_M;
        end

        WAIT_M: begin
            if (mul_ready_w) begin
                next_state = SET_M_VALID;
            end
        end

        SET_M_VALID: begin
            next_state = CALC_SEED_SQ;
        end

        CALC_SEED_SQ: begin
            next_state = WAIT_SEED_SQ;
        end

        WAIT_SEED_SQ: begin
            if (mul_ready_w) begin
                next_state = CALC_MOD;
            end
        end

        CALC_MOD: begin
            next_state = WAIT_MOD_READY;
        end

        WAIT_MOD_READY: begin
            if (mod_ready_w) begin
                next_state = GET_RANDOM_BIT;
            end
        end

        GET_RANDOM_BIT: begin
            next_state = CHECK_BIT_COUNTER;
        end

        CHECK_BIT_COUNTER: begin
            if (bit_cnt == '0) begin
                next_state = READY;
            end else begin
                next_state = CALC_XNEXT;
            end
        end

        CALC_XNEXT: begin
            next_state = WAIT_XNEXT;
        end

        WAIT_XNEXT: begin
            if (mul_ready_w) begin
                next_state = CALC_MOD;
            end
        end

        READY: begin
            if (!start) begin
                next_state = IDLE;
            end
        end

        default: begin
            next_state = IDLE;
        end
    endcase
end

always_comb begin
    m_valid_w = m_valid_reg;
    result_valid_w = result_valid_reg;
    use_seed_w = use_seed_reg;
    use_pq_w = use_pq_reg;
    mul32_en_w = mul32_en_reg;
    mod64_en_w = mod64_en_reg;
    bit_cnt_w = bit_cnt;
    m_load_w = '0;
    result_shift_en_w = '0;
    store_xnext_w = '0;
    result_load_w = '0;
    case(state)
        IDLE: begin
            mul32_en_w = '0;
            mod64_en_w = '0;
            if (start) begin
                result_valid_w = '0;
                bit_cnt_w = RESULT_BITS-1;
                if (!keep_m && m_valid_reg) begin
                    m_valid_w = '0;
                end
                if (!m_valid_reg) begin
                    use_seed_w = '1;
                    use_pq_w = '1;
                end else if (!keep_m) begin
                    use_seed_w = '1;
                    use_pq_w = '1;
                end else if (!use_xnext) begin
                    use_seed_w = '1;
                    use_pq_w = '0;
                end else begin
                    use_seed_w = '0;
                    use_pq_w = '0;
                end
            end
        end

        SET_M_VALID: begin
            m_valid_w = '1;
            m_load_w = '1;
        end

        CALC_SEED_SQ: begin
            mul32_en_w = '1;
            use_seed_w = '1;
            use_pq_w = '0;
        end

        WAIT_SEED_SQ: begin
            if (mul_ready_w) begin
                mul32_en_w = '0;
                use_seed_w = '0;
            end
        end
        
        CALC_M,
        CALC_XNEXT: begin
            mul32_en_w = '1;
        end


        WAIT_M,
        WAIT_XNEXT: begin
            if (mul_ready_w) begin
                mul32_en_w = '0;
            end
        end

        CALC_MOD: begin
            mod64_en_w = '1;
        end

        WAIT_MOD_READY: begin
            if (mod_ready_w) begin
                mod64_en_w = '0;
            end
        end

        GET_RANDOM_BIT: begin
            result_shift_en_w = '1;
            store_xnext_w = '1;
        end

        CHECK_BIT_COUNTER: begin
            if (bit_cnt != '0) begin
                bit_cnt_w = bit_cnt - 'd1;
            end
            if (bit_cnt == '0) begin
                result_load_w = '1;
            end
        end

        READY: begin
            result_valid_w = '1;
        end

        default: begin

        end
    endcase
end



//Outputs *****************************************************************************************
always_comb m_valid      = m_valid_reg;
always_comb result_valid = result_valid_reg;
always_comb m = m_reg;
always_comb result = result_reg;

endmodule