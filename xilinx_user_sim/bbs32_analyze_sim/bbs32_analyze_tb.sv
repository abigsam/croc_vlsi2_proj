
`define CLK_PERIOD          (10ns)

`define DEFAULT_P           (32'd29711)
`define DEFAULT_Q           (32'd45543)
`define DEFAULT_SEED        (32'd56686)

// `define RAND_WORDS          (32)
`define RAND_WORDS          (64)
//`define EXPORT_FILE_NAME    ("D:/data_files/git/vlsi2_proj/src/bbs32/sim/bbs32_rtl_results.csv")
`define EXPORT_FILE_NAME    ("./../../../../bbs32_analyze_sim/bbs32_rtl_results.csv")

module bbs32_analyze_tb();

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


task automatic export_results(ref bit[31:0] inq[$]);
begin
    int fd;
    bit [31:0] tmp;
    int bcnt = 0;

    fd = $fopen (`EXPORT_FILE_NAME, "w");

    while(inq.size()) begin
        tmp = inq.pop_front();
        for(int i = 0; i < 32; i++) begin
            $fdisplay(fd, "%0d,", tmp[i]);
            bcnt++;
        end
    end

    $fclose(fd);

    $display("Was written %0d bits", bcnt);
end
endtask //automatic



//TB **********************************************************************************************
initial begin
    bit [31:0] result_rnd = '0;
    bit [31:0] result_q [$];

    {clk, nrst, start, keep_m, use_xnext} = '0;
    
    #100ns;
    nrst = '1;

    first_run(`DEFAULT_P, `DEFAULT_Q, `DEFAULT_SEED, result_rnd); //1848907155
    result_q.push_back(result_rnd);

    repeat(`RAND_WORDS-1) begin
        run_proceed(result_rnd);
        result_q.push_back(result_rnd);
    end

    $display("Received %0d random 32bit values", result_q.size());

    export_results(result_q);

    #1us;
    $finish();

end

    
endmodule