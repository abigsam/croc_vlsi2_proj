
`define CLK_PERIOD          (10ns)

module bbs32_tb();

//DUT signals
logic clk, nrst;
logic [31:0] seed, p, q;
logic start, keep_m, use_xnext;
logic [63:0] m;
logic [31:0] result;
logic m_valid, result_valid;

//DUT *********************************************************************************************
bbs32 DUT (.*);


//Clock
always #(`CLK_PERIOD/2) clk = ~clk;


//Tasks
task automatic first_run(input bit[31:0] p_val, q_val, seed_val, output bit [31:0] out_val);
begin
    @(posedge clk) begin
        p <= p_val;
        q <= q_val;
        seed <= seed_val;
        start <= '1;
        keep_m <= '0;
        use_xnext <= '0;
    end
    repeat(4) @(posedge clk);
    wait(m_valid);
    @(posedge clk);
    $display("First run: P = %0d, Q = %0d, calculated M = %0d", p_val, q_val, m);
    if (m != (p_val * q_val)) begin
        $error("Expected value %0d, but received %0d", (p_val * q_val), m);
        $finish();
    end else begin
        $display("M calculated successfully");
    end
    wait(result_valid);
    @(posedge clk) start <= '0;
    @(posedge clk) out_val = result;
    $display("Result %0d", result);
end
endtask //automatic


task automatic run_proceed(output bit [31:0] out_val);
begin
    @(posedge clk) begin
        start <= '1;
        keep_m <= '1;
        use_xnext <= '1;
    end
    $display("Generate next random word without changing configuration");
    repeat(4) @(posedge clk);
    wait(result_valid);
    @(posedge clk) begin
        start <= '0;
        keep_m <= '0;
        use_xnext <= '0;
    end
    @(posedge clk) out_val = result;
    $display("Result %0d", result);
end
endtask //automatic


task automatic run_upd_seed(input bit [31:0] seed_val, output bit [31:0] out_val);
begin
    @(posedge clk) begin
        start <= '1;
        keep_m <= '1;
        use_xnext <= '0;
        seed <= seed_val;
    end
    $display("Generate random word with new SEED");
    repeat(4) @(posedge clk);
    wait(result_valid);
    @(posedge clk) begin
        start <= '0;
        keep_m <= '0;
    end
    @(posedge clk) out_val = result;
    $display("Result %0d", result);
end
endtask //automatic


task automatic run_upd_all(input bit[31:0] p_val, q_val, seed_val, output bit [31:0] out_val);
begin
    @(posedge clk) begin
        p <= p_val;
        q <= q_val;
        seed <= seed_val;
        start <= '1;
        keep_m <= '0;
        use_xnext <= '0;
    end
    $display("Generate random value with new P, Q, SEED");
    repeat(4) @(posedge clk);
    wait(m_valid);
    $display("Update run: P = %0d, Q = %0d, calculated M = %0d", p_val, q_val, m);
    if (m != (p_val * q_val)) begin
        $error("Expected value %0d, but received %0d", (p_val * q_val), m);
        $finish();
    end else begin
        $display("M calculated successfully");
    end
    wait(result_valid);
    @(posedge clk) start <= '0;
    @(posedge clk) out_val = result;
    $display("Result %0d", result);
end
endtask //automatic


//TB **********************************************************************************************
initial begin
    bit [31:0] result_rnd = '0;

    {clk, nrst, start, keep_m, use_xnext} = '0;
    
    #100ns;
    nrst = '1;

    first_run(29711, 45543, 56686, result_rnd); //1848907155 | 0x6E341593

    run_proceed(result_rnd); //3861864124 | 0xE62F5EBC
    run_proceed(result_rnd); //2925785739
    run_proceed(result_rnd); //108805144
    run_proceed(result_rnd); //3605217625
    run_proceed(result_rnd); //1046672875

    run_upd_seed(5665, result_rnd); //2864200858

    run_proceed(result_rnd); //3865842683
    run_proceed(result_rnd); //2326662950
    run_proceed(result_rnd); //3113944318
    run_proceed(result_rnd); //3802891209
    run_proceed(result_rnd); //2925969727
    run_proceed(result_rnd); //3098206450

    run_upd_all(29711+4, 45543+4, 56686, result_rnd); //1317898683
    run_upd_all(29711+4, 45543+4, 56686, result_rnd); //1317898683

    run_proceed(result_rnd); //2192164605
    run_proceed(result_rnd); //2222407496
    run_proceed(result_rnd); //4192058734
    run_proceed(result_rnd); //3425872681
    run_proceed(result_rnd); //1533123949
    run_proceed(result_rnd); //892968444

    #1us;
    $finish();

end


endmodule