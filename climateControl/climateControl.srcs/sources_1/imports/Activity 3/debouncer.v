module debouncer (
input wire switchIn,
input wire clk,
input wire reset,
output wire debounceout);
wire beat;
reg[2:0] pipeline;
//you write the code!
    clockDividerHB #(.THRESHOLD(3_333_333)) clockDividerInst (
    .clk(clk),   // Assuming inputClock is your main clock signal
    .reset(reset),      // Assuming reset is your reset signal
    .enable(1'b1),
    .dividedClk(),      // Since dividedClk is not used, leave the bracket empty
    .beat(beat)         // Connect the output beat signal to the top-level beat wire
    );
    
    always @(posedge clk) begin
        if (beat) begin
            pipeline[0] <= switchIn;
            pipeline[1] <= pipeline[0];
            pipeline[2] <= pipeline[1];
        end
    end
    
    assign debounceout = &pipeline;
endmodule