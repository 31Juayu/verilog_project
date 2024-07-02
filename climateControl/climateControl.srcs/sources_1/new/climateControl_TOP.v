`timescale 1ns / 1ps

module climateControl_TOP(
    input wire clk,
    
    input wire btn_enter,
    input wire btn_security_reset,
    input wire btn_door_master,
        
    input wire btn_morse,
    input wire btn_reset,  // reset
    
    input wire [2:0] expT,
    input wire [2:0] outT,
    input wire [6:0] password_switches,
    
    output wire [6:0] ssdCathode,
    output reg [3:0] ssdAnode,
    
    output reg [3:0] vault_door_led,    // led[0:3]
    output reg [3:0] alarm_led,         // led[4:7]
    output reg [3:0] morse_led,          // led[8:11]
    output reg [3:0] light_out
);
    //debouncer the switch
    wire deb_out_expT_0;
    debouncer deb_0 (.switchIn(expT[0]), .clk(clk), .debounceout(deb_out_expT_0), .reset(btn_reset));
    
    wire deb_out_expT_1;
    debouncer deb_1 (.switchIn(expT[1]), .clk(clk), .debounceout(deb_out_expT_1), .reset(btn_reset));
    
    wire deb_out_expT_2;
    debouncer deb_2 (.switchIn(expT[2]), .clk(clk), .debounceout(deb_out_expT_2), .reset(btn_reset));
    
    wire deb_out_outT_0;
    debouncer deb_3 (.switchIn(outT[0]), .clk(clk), .debounceout(deb_out_outT_0), .reset(btn_reset));
    
    wire deb_out_outT_1;
    debouncer deb_4 (.switchIn(outT[1]), .clk(clk), .debounceout(deb_out_outT_1), .reset(btn_reset));
    
    wire deb_out_outT_2;
    debouncer deb_5 (.switchIn(outT[2]), .clk(clk), .debounceout(deb_out_outT_2), .reset(btn_reset));
    
    //climate control
    wire [2:0] curT;
    wire ifOpen_o;
    wire ifStar;
    wire [4:0] pCnt;
    wire [3:0] light_m;
    
    FSM fsm (.clk(clk),.reset(btn_reset),.outT({deb_out_outT_2,deb_out_outT_1,deb_out_outT_0}),.expT({deb_out_expT_2,deb_out_expT_1,deb_out_expT_0})
    ,.pCnt(pCnt),.curT(curT),.ifStar(ifStar),.ifOpen(ifOpen_o),.enable_10(),.enable_20(),.light(light_m));
    
    // door control logic
    wire [3:0] vault_door, alarm, morse;
    
    DoorEntry_Top door_controller(
        .clk(clk),
        
        .btn_enter(btn_enter),
        .btn_security_reset(btn_security_reset),
        .btn_door_master(btn_door_master),
        .btn_morse(btn_morse),
        .btn_reset(btn_reset),
        
        .password_switches(password_switches),
        .vault_door_led(vault_door),
        .alarm_led(alarm),
        .morse_led(morse),
        
//        .ssdCathode(),
//        .ssdAnode(),
        
        .pCnt(pCnt)
    );

    //dispaly
    
    reg [1:0] activeDisplay;
    wire beat;
    reg [3:0] ssdValue;
    //30_00
    clockDividerHB #(.THRESHOLD(20_000)) clockDividerInst (
    .clk(clk),   // Assuming inputClock is your main clock signal
    .reset(1'b0),      // Assuming reset is your reset signal
    .enable(1'b1),
    .dividedClk(),      // Since dividedClk is not used, leave the bracket empty
    .beat(beat)         // Connect the output beat signal to the top-level beat wire
    );
    
    sevenSegmentDecoder decoderInst (
    .bcd(ssdValue),   
    .ssd(ssdCathode)
    );
    

    
    always @(posedge beat) begin
        activeDisplay <= activeDisplay + 2'b1;
    end
    
    always @(*) begin
        if(ifStar) begin //if climate control is open or closed but within 10s, show on ssd. otherwise, do not show the temperature
             case(activeDisplay)
                2'd0 : begin
                    ssdValue = 4'd2; //1st digit
                    ssdAnode = 4'b0111;
                end
                
                2'd1 : begin
                    ssdValue = curT; //2nd digit
                    ssdAnode = 4'b1011;
                end
                
                2'd2 : begin
                    ssdValue = ifOpen_o; //
                    ssdAnode = 4'b1101;
                end
                
                2'd3 : begin
                    ssdValue = pCnt; // 
                    ssdAnode = 4'b1110;
                end
                //add more cases here
                
                default : begin
                    ssdValue = 4'd10; // undefined
                    ssdAnode = 4'b1111; // none active
                end
            endcase
        end else begin
             case(activeDisplay)
                2'd0 : begin
                    ssdValue = 4'd0; //1st digit
                    ssdAnode = 4'b1111;
                end
                
                2'd1 : begin
                    ssdValue = 4'd0; //2nd digit
                    ssdAnode = 4'b1111;
                end
                
                2'd2 : begin
                    ssdValue = ifOpen_o; //
                    ssdAnode = 4'b1101;
                end
                
                2'd3 : begin
                    ssdValue = pCnt; // 
                    ssdAnode = 4'b1110;
                end
                //add more cases here
                
                default : begin
                    ssdValue = 4'd10; // undefined
                    ssdAnode = 4'b1111; // none active
                end
            endcase          
        end
    end    
    
    always @(*) begin
        vault_door_led <= vault_door;
        alarm_led <= alarm;
        morse_led <= morse;
        light_out <= light_m;
    end
    
    
    
endmodule
