`timescale 1ns / 1ps

module TriggerEveryTwoCycles (
    input wire clk,       // ����ʱ���ź�
    input wire reset,     // ��λ�ź�
    input wire input_sig, // �����ź�
    output reg output_sig // ����ź�
);

// ����һ���Ĵ������ڼ���
reg [1:0] count = 2'b00;

// ͬ��������
always @(posedge clk) begin
    if (reset) begin
        count <= 2'b00; // �ڸ�λʱ���ü�����
        output_sig <= 1'b0; // ��λʱ���Ϊ�͵�ƽ
    end else begin
        // ��������ź�Ϊ�ߵ�ƽ�Ҽ���Ϊ2��������ź���Ϊ�ߵ�ƽ
        if (input_sig && (count == 2'b10)) begin
            output_sig <= 1'b1;
        end else begin
            output_sig <= 1'b0;
        end
        
        // ������ÿ��ʱ�����ڼ�1
        count <= count + 1;
    end
end

endmodule
