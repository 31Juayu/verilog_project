`timescale 1ns / 1ps

module DoorEntryFSM(
    input wire clk,                // Clock signal
    input wire enter,              // Button to enter password (btn_E)
    input wire reset,              // Button to reset (btn_C)
    input wire [6:0] switchIn,     // Input password switches
    input wire [2:0] door_state,   // Current state of the door
    input wire beat,               // Beat signal for timing
    output reg [3:0] password_state // Output representing the state of the password FSM
);

// Define FSM states as parameters
parameter S1=3'd0, S2=3'd1, Trapped=3'd2, Success=3'd3;
// Door FSM outside
parameter Closed=3'd0, Open=3'd1, BeginClose=3'd2, BeginOpen=3'd3;

// Define registers for FSM state, next state, password, and timeout
reg [2:0] state, nextstate;
reg [7:0] password;
reg [5:0] S2_timeout;

initial begin
    password = 7'd50;         // Set password
    S2_timeout = 5'd20;       // Set S2 timeout
    state = S1;               // Initialize state to S1
    nextstate = S1;           // Initialize next state to S1
end


// synchronization
always @(posedge clk) begin
    state <= nextstate;
end

// Decrement S2 timeout if in S2 state and beat signal is active, otherwise reset timeout
always @(posedge clk) begin
    if (state == S2) begin
        // Decrement timeout if not zero
        if (S2_timeout != 0 && beat) S2_timeout <= S2_timeout - 1;  
    end else S2_timeout = 5'd20; // Reset timeout if not in S2 state
end

// next state logic
always @(*) begin
    case(state)
        S1: begin
            if (enter && switchIn == password) nextstate = Success; // Transition to Success if correct password entered
            else if (enter) nextstate = S2;                        // Transition to S2 if enter button pressed
            else nextstate = S1;                                    // Remain in S1 otherwise
        end
        
        S2: begin
            if (S2_timeout == 0) nextstate = Trapped;              // Transition to Trapped if S2 timeout
            else if (enter && switchIn == password) nextstate = Success; // Transition to Success if correct password entered
            else if (enter) nextstate = Trapped;                    // Transition to Trapped if enter button pressed
            else nextstate = S2;                                    // Remain in S2 otherwise
        end
        
        Trapped: begin
            if (reset) nextstate = S1;                              // Transition to S1 if reset button pressed
            else nextstate = Trapped;                               // Remain in Trapped otherwise
        end
        
        Success: begin
            if (reset || door_state == BeginClose) nextstate = S1;  // Transition to S1 if reset button pressed or door begins closing
            else nextstate = Success;                               // Remain in Success otherwise
        end
    endcase 
end


// output logic 
always @(*) begin
    password_state = state;
end

endmodule 
