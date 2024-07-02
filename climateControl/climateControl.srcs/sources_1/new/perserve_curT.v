`timescale 1ns / 1ps


module perserve_curT(
input wire [2:0] curT,
input wire clk,
input wire reset,
output reg [2:0] prev_curT
    );
    
     always @(posedge clk or posedge reset) begin
        if (reset) begin
            prev_curT <= 3'b000;  // ³õÊ¼ÖµÎª 0
        end 
        else begin
            prev_curT <= curT;
        end
    end
endmodule
