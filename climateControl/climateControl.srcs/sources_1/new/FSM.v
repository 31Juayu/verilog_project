`timescale 1ns / 1ps

module FSM #(parameter F1=3'b000,F2=3'b001,F3=3'b010,F4 =3'b011,F5 =3'b100) (
input wire clk,
input wire reset,
input wire [2:0] outT, 
input wire [2:0] expT, 
input wire [3:0] pCnt,
output reg [2:0] curT,
output reg ifStar, // Used to control whether the SSD will light.
output reg ifOpen, //Used to indicate whether the controller is starting up, displayed on an SSD.

//
output reg enable_10,
output reg enable_20,

//the light in vault
output reg [3:0] light
    );
    reg [2:0] state;
    reg [2:0] nextstate;
    wire beat_0_5;
    
    //cnt 10 s
    wire beat_10;
    //cnt 20 s
    wire beat_20;
    //These intermediate variables are obtained by right-shifting my output by 2 bits, 
    //so when taking them, we take the left 3 bits.
    reg [4:0] curToExpT_1;
    reg [4:0] curToExpT_0_5;
    reg [4:0] curToOutT;
    //When the state transitions to F4, pre_F4_state is used to store the previous state. 
    //Because in this state, my SSD will maintain the same output as the previous state.
    reg [2:0] pre_F4_state;

  
     clockDividerHB #(.THRESHOLD(25_000_000)) clockDividerInst_0_5 (
    .clk(clk),   // Assuming inputClock is your main clock signal
    .reset(reset),      // Assuming reset is your reset signal
    .enable(1'b1),
    .dividedClk(),      // Since dividedClk is not used, leave the bracket empty
    .beat(beat_0_5)         // Connect the output beat signal to the top-level beat wire
  );
  
     clockDividerHB #(.THRESHOLD(500_000_000)) clockDividerInst_10 (
    .clk(clk),   // Assuming inputClock is your main clock signal
    .reset(reset),      // Assuming reset is your reset signal
    .enable(enable_10),
    .dividedClk(),      // Since dividedClk is not used, leave the bracket empty
    .beat(beat_10)         // Connect the output beat signal to the top-level beat wire
  );
  
     clockDividerHB #(.THRESHOLD(1000_000_000)) clockDividerInst_20 (
    .clk(clk),   // Assuming inputClock is your main clock signal
    .reset(reset),      // Assuming reset is your reset signal
    .enable(enable_20),
    .dividedClk(),      // Since dividedClk is not used, leave the bracket empty
    .beat(beat_20)         // Connect the output beat signal to the top-level beat wire
  );
    //register state block
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= F1;  
        end 
        else begin
            state <= nextstate; 
        end
    end
    
     //next state block
    always@(*)begin
        case(state)
        F1: begin
            if(pCnt > 0 && pCnt<= 5) nextstate= F2;
            else if (pCnt > 5) nextstate = F3;
            else nextstate=F1;
        end
        F2 : begin
            if(pCnt == 0) begin
                pre_F4_state = F2; //record previoous state before F4
                nextstate= F4; 
            end
            else if (pCnt > 5) nextstate = F3;
            else nextstate=F2;
        end
        F3 : begin
            if(pCnt == 0) begin 
                pre_F4_state = F3; //record previoous state before F4
                nextstate= F4;
            end
            else if (pCnt > 0 && pCnt<= 5) nextstate = F2;
            else nextstate=F3;        
        end
        F4 : begin
            if(beat_10) nextstate=F5;
            else nextstate=F4;
        end
        F5 : begin
            if(beat_20) nextstate=F1;
            else nextstate=F5;
        end
        default : begin
            nextstate=F1;
        end
        endcase
    end
    
    //output logic
    always@(*)begin
        case(state)
        F1: begin
            curT = outT;
            ifStar = 0; 
            ifOpen = 0; 
            enable_10 = 0;
            enable_20 = 0;
            light = 4'b0000; //no person, turn off the light
        end
        F2: begin
            curT = {curToExpT_0_5[4],curToExpT_0_5[3],curToExpT_0_5[2]};
            ifStar = 1; 
            ifOpen = 1; 
            enable_10 = 0;
            enable_20 = 0;
            light = 4'b1111; //  turn on the light
        end
        F3: begin
            curT = {curToExpT_1[4],curToExpT_1[3],curToExpT_1[2]};
            ifStar = 1; 
            ifOpen = 1; 
            enable_10 = 0;
            enable_20 = 0;
            light = 4'b1111; //  turn on the light
        end        
        F4 : begin
            if (pre_F4_state == F2) curT = {curToExpT_0_5[4],curToExpT_0_5[3],curToExpT_0_5[2]};
            else curT = {curToExpT_1[4],curToExpT_1[3],curToExpT_1[2]};
            ifStar = 1; 
            ifOpen = 1; 
            enable_10 = 1;
            enable_20 = 0;
            light = 4'b1111; //  turn on the light
        end
        F5 : begin
            curT = {curToOutT[4],curToOutT[3],curToOutT[2]};
            ifStar = 1; 
            ifOpen = 0; 
            enable_10 = 0;
            enable_20 = 1;
            light = 4'b0000; //people go out, turn off
        end
        default: begin
            curT = outT;
            ifStar = 0; 
            ifOpen = 0; 
            enable_10 = 0;
            enable_20 = 0;
            light <= 4'b0000;  
        end
        endcase
    end
    
    wire next_0;
    sync s0 (.in(beat_0_5),.clk(clk),.out(next_0));
    
    //The main idea of my state machine is to convert the changes in three different 
    //temperatures¡ªchanging by one degree every 0.5 seconds, one degree every second, 
    //and one degree every two seconds¡ªinto a unified triggering condition: transforming 
    //them into changes of one degree every 0.5 seconds, 0.5 degrees every 0.5 seconds, 
    //and 0.25 degrees every 0.5 seconds.
     
    always@(posedge next_0)begin
         case(state)
            F2: begin
                if ({curToExpT_0_5[4],curToExpT_0_5[3],curToExpT_0_5[2]} > expT) begin
                    curToExpT_0_5 <= curToExpT_0_5 - 5'b00100;
                end 
                else if({curToExpT_0_5[4],curToExpT_0_5[3],curToExpT_0_5[2]} < expT)begin
                    curToExpT_0_5 <= curToExpT_0_5 + 5'b00100;
                end
            end
            F3: begin
                    curToExpT_0_5 <= curToExpT_1;
                end
            F4: begin
                    curToExpT_0_5 <= curToExpT_0_5;
                end                        
           default: begin
                    curToExpT_0_5 <= {outT,2'b00};
            end
        endcase       
    end
    
    wire next_1;
    sync s1 (.in(beat_0_5),.clk(clk),.out(next_1));
    always@(posedge next_1)begin
         case(state)
            F2: begin
                curToExpT_1 <= curToExpT_0_5;
            end
            F3: begin
                if ({curToExpT_1[4],curToExpT_1[3],curToExpT_1[2]} > expT) begin
                    curToExpT_1 <= curToExpT_1 - 5'b00010;
                end 
                else if({curToExpT_1[4],curToExpT_1[3],curToExpT_1[2]} < expT)begin
                    curToExpT_1 <= curToExpT_1 + 5'b00010;
                end            
            end  
            F4: begin
                    curToExpT_1 <= curToExpT_1;
                end              
            default: begin
                 curToExpT_1 <= {outT,2'b00};
            end
        endcase       
    end
    
    wire next_2;
    sync s2 (.in(next_1),.clk(clk),.out(next_2));
    always@(posedge next_2)begin
            case(state)
                F2: begin
                   curToOutT  <= curToExpT_0_5;
                end
                F3: begin
                   curToOutT  <= curToExpT_1;
                end
                F4: begin
                     if (pre_F4_state == F2) begin
                        curToOutT  <= curToExpT_0_5;
                    end 
                    else if(pre_F4_state == F3)begin
                        curToOutT  <= curToExpT_1;
                    end         
                end
                F5: begin
                     if ({curToOutT[4],curToOutT[3],curToOutT[2]} > outT) begin
                        curToOutT <= curToOutT - 5'b00001;
                    end 
                    else if({curToOutT[4],curToOutT[3],curToOutT[2]} < outT)begin
                        curToOutT <= curToOutT + 5'b00001;
                    end         
                end                
                default: begin
                        curToOutT <= {outT,2'b00};
                end
            endcase  
    end
    
  
    //test enter

  
endmodule
