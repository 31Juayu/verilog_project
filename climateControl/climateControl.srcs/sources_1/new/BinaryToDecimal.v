`timescale 1ns / 1ps


module BinaryToDecimal(
    input [4:0] binary,
    output reg [7:0] decimal
);

always @(*) begin
    case(binary)
        5'b00000: decimal = 8'd0;
        5'b00001: decimal = 8'd1;
        5'b00010: decimal = 8'd2;
        5'b00011: decimal = 8'd3;
        5'b00100: decimal = 8'd4;
        5'b00101: decimal = 8'd5;
        5'b00110: decimal = 8'd6;
        5'b00111: decimal = 8'd7;
        5'b01000: decimal = 8'd8;
        5'b01001: decimal = 8'd9;
        5'b01010: decimal = 8'd10;
        5'b01011: decimal = 8'd11;
        5'b01100: decimal = 8'd12;
        5'b01101: decimal = 8'd13;
        5'b01110: decimal = 8'd14;
        5'b01111: decimal = 8'd15;
        5'b10000: decimal = 8'd16;
        5'b10001: decimal = 8'd17;
        5'b10010: decimal = 8'd18;
        5'b10011: decimal = 8'd19;
        5'b10100: decimal = 8'd20;
        5'b10101: decimal = 8'd21;
        5'b10110: decimal = 8'd22;
        5'b10111: decimal = 8'd23;
        5'b11000: decimal = 8'd24;
        // Add more cases for other binary inputs if necessary
        default: decimal = 8'd0; // Default to zero if binary input is out of range
    endcase
end

endmodule

