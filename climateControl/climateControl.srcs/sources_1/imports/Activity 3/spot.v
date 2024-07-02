module spot (
input wire clk,
input wire spot_in,
output wire spot_out);
reg out;
// you write the module code!
  always @(posedge clk) begin
    out <= spot_in; 
  end

  assign spot_out = (~out) & spot_in; 

endmodule