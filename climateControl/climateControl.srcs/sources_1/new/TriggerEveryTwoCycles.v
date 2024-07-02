`timescale 1ns / 1ps

module TriggerEveryTwoCycles (
    input wire clk,       // 输入时钟信号
    input wire reset,     // 复位信号
    input wire input_sig, // 输入信号
    output reg output_sig // 输出信号
);

// 定义一个寄存器用于计数
reg [1:0] count = 2'b00;

// 同步触发器
always @(posedge clk) begin
    if (reset) begin
        count <= 2'b00; // 在复位时重置计数器
        output_sig <= 1'b0; // 复位时输出为低电平
    end else begin
        // 如果输入信号为高电平且计数为2，则将输出信号置为高电平
        if (input_sig && (count == 2'b10)) begin
            output_sig <= 1'b1;
        end else begin
            output_sig <= 1'b0;
        end
        
        // 计数器每个时钟周期加1
        count <= count + 1;
    end
end

endmodule
