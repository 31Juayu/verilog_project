`timescale 1ns / 1ps

module DoorExitFSM(
    input wire clk,                // Clock signal
    input wire morse,              // Input for Morse signal
    input wire reset,              // Input for reset signal
    input wire [2:0] door_state,  // Current state of the door
    input wire beat,               // Beat signal for timing
    output reg [3:0] morse_state,  // Output representing the state of the Morse FSM
    output reg [3:0] debug         // Output for debugging purposes
);

    // Define FSM states as parameters
    parameter Closed=3'd0, Open=3'd1, BeginClose=3'd2, BeginOpen=3'd3;
    // Door FSM as parameters
    parameter CLEAR=3'd0, IDLE=3'd1, DOT=3'd2, DASH=3'd4, OUTPUT=3'd5, INIT=3'd6; // BeginOpen=3'd3
    
    // Define registers for FSM state, next state, current input, valid inputs, and timeouts
    reg [9:0] current_input;
    reg [3:0] state, nextstate;
    reg [9:0] valid1, valid2, valid3, valid4, valid5, valid6, 
              valid7, valid8, valid9, valid10, valid11, valid12;
    
    reg one_bit;
    reg [3:0] cnt;
    reg [1:0] dot_timeout, dash_timeout;
    reg [5:0] timeout;
    
    // Initialize count, state, next state, valid inputs, and timeouts
    initial begin
        cnt = 0;                        // Initialize count to 0
        state = CLEAR;                  // Initialize state to CLEAR
        nextstate = CLEAR;              // Initialize next state to CLEAR
    
        // Define valid Morse code inputs
        valid1= 10'b11_1111_1110;
        valid2= 10'b01_1111_1111;
        valid3= 10'b00_1110_0011;
        valid4= 10'b00_0110_0001;
        valid5= 10'b00_0001_0000;
        valid6= 10'b10_0001_1000;
        valid7= 10'b11_0000_0111;
        valid8= 10'b11_0001_1100;
        valid9= 10'b00_0111_1000;
        valid10= 10'b00_0010_0000;
        valid11= 10'b11_1001_1110;
        valid12= 10'b11_1100_0111;
    end

    // Synchronize state and current input on positive clock edge
    always @(posedge clk) begin 
        if (nextstate == CLEAR) begin
            current_input = 10'd0;      // Reset current input
            cnt = 4'd0;                  // Reset count
        end else if (nextstate == OUTPUT) begin
            current_input[cnt] <= one_bit; // Assign current bit
            cnt <= cnt + 1;                // Increment count
        end
        
        state = nextstate;                  // Update state
    end
    
    // Synchronize dot_timeout and dash_timeout
    always @(posedge clk) begin
        if (state == IDLE) begin
            if (morse && beat && dot_timeout != 0) dot_timeout <= dot_timeout - 1; // Decrement dot timeout
        end else if (state == DOT) begin
            if (morse && beat && dash_timeout != 0) dash_timeout <= dash_timeout - 1; // Decrement dash timeout
        end else begin
            dot_timeout = 2'd1;          // Reset dot timeout
            dash_timeout = 2'd2;         // Reset dash timeout
        end
    end
    
    // Synchronize timeout
    always @(posedge clk) begin
        if (state == CLEAR || state == INIT) timeout = 6'd50; // Set initial timeout
        else if (state != BeginOpen && state != OUTPUT) begin
            if (timeout != 0 && beat) timeout <= timeout - 1'b1; // Decrement timeout if not zero
        end
    end
    
    // nextstate logic
    always @(*) begin
        case(state)
            INIT: begin
                if (reset) nextstate = CLEAR;
                else if (morse) nextstate = IDLE;
                else nextstate = INIT;
                
            end
    
            IDLE: begin
                if (reset) nextstate = CLEAR;
                else if (cnt == 4'd10) begin
                    if (current_input == valid1 || current_input == valid2 || current_input == valid3
                     || current_input == valid4 || current_input == valid5 || current_input == valid6
                     || current_input == valid7 || current_input == valid8 || current_input == valid9
                     || current_input == valid10|| current_input == valid11|| current_input == valid12) begin
                        nextstate = BeginOpen; // Transition to BeginOpen if valid Morse code input received
                    end else nextstate = CLEAR; // Otherwise, reset state
                end else if (timeout == 0) nextstate = CLEAR; // Reset state if timeout
                else if (morse && dot_timeout == 0) nextstate = DOT; // Transition to DOT if dot timeout
                else nextstate = IDLE; // Remain in IDLE otherwise
            end
            
            DOT: begin
                one_bit = 1'b0; // Set one bit for DOT
                if (reset) nextstate = CLEAR; // Reset state if reset signal
                else if (!morse && dash_timeout != 0) nextstate = OUTPUT; // Transition to OUTPUT if not Morse signal and dash timeout
                else if (morse && dash_timeout == 0) nextstate = DASH; // Transition to DASH if Morse signal and dash timeout
                else nextstate = DOT; // Remain in DOT otherwise
            end
            
            DASH: begin
                one_bit = 1'b1; // Set one bit for DASH
                if (reset) nextstate = CLEAR; // Reset state if reset signal
                else if (morse) nextstate = DASH; // Remain in DASH if Morse signal
                else nextstate = OUTPUT; // Transition to OUTPUT otherwise
            end
            
            OUTPUT: begin
                if (reset) nextstate = CLEAR; // Reset state if reset signal
                else nextstate = IDLE; // Transition to IDLE otherwise
            end
            
            BeginOpen: begin
                if (reset) nextstate = CLEAR; // Reset state if reset signal
                else if (door_state == BeginClose) nextstate = CLEAR; // Reset state if door begins closing
                else nextstate = BeginOpen; // Remain in BeginOpen otherwise
            end
                 
            CLEAR: begin
                if (morse) nextstate = INIT; // Transition to INIT if Morse signal
                else nextstate = CLEAR; // Remain in CLEAR otherwise
            end
            
        endcase
    end
    
    // output logic
    always @(*) begin
        morse_state = state;
        debug = cnt;
    end
    
    endmodule
