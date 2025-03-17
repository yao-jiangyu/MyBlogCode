`timescale 1ns/1ps

module tb_mod_2_n();
    // 定义测试信号
    reg clk;
    reg rst_n;
    wire MyFlag;
    
    // 实例化被测模块
    mod_2_n dut (
        .clk(clk),
        .rst_n(rst_n),
        .MyFlag(MyFlag)
    );
    
    // 时钟生成
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns周期（100MHz）时钟
    end
    
    // 测试过程
    initial begin
        // 波形输出
        $dumpfile("tb_mod_2_n.vcd");
        $dumpvars(0, tb_mod_2_n);
        
        // 初始复位
        rst_n = 0;
        #20;
        rst_n = 1;
        
        // 运行足够长的时间以观察多个周期
        #1500; // 运行150个时钟周期，足以观察64个计数和环绕
        
        // 再次复位测试
        rst_n = 0;
        #20;
        rst_n = 1;
        #680;
        
        $display("测试完成");
        $finish;
    end
    
    // 监控信号
    initial begin
        $monitor("Time=%0t, rst_n=%b, wr_addr=%d, rd_addr=%d, MyFlag=%b", 
                 $time, rst_n, dut.wr_addr, dut.rd_addr, MyFlag);
    end
    
endmodule

