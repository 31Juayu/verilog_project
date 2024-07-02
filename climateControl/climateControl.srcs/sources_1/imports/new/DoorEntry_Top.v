`timescale 1ns / 1ps

module DoorEntry_Top(
    input wire clk,
    
    input wire btn_enter,       // btn_E
    input wire btn_security_reset,       // btn_W
    input wire btn_door_master, // btn_C
    
    input wire btn_morse,       // btn_N
    input wire btn_reset,        // btn_S

    input wire [6:0] password_switches, // input password for entry
    
    output reg [3:0] vault_door_led,   // led[0:3]
    output reg [3:0] alarm_led,        // led[4:7]
    output reg [3:0] morse_led,        // led[8:11]
    
//    output wire [6:0] ssdCathode,   // display number of people entry/exit
//    output reg  [3:0] ssdAnode,
    output wire [4:0] pCnt
);
    
    /////////////////////////////////////////////////////////////////////////////
    // produce debounced the button inputs
    // ignore this code block!
    /////////////////////////////////////////////////////////////////////////////
    wire east_deb, east_syn, east_sig, enter;
    wire west_deb, west_syn, west_sig, security_reset;
    wire north_deb, north_syn, north_sig, morse;
    wire south_deb, south_syn, south_sig, reset;
    wire center_deb, center_syn, center_sig, door_master;
    
    debouncer east_debouncer(.switchIn(btn_enter), .clk(clk), .reset(reset), .debounceout(east_deb));
    debouncer west_debouncer(.switchIn(btn_security_reset), .clk(clk), .reset(reset), .debounceout(west_deb));
    debouncer north_debouncer(.switchIn(btn_morse), .clk(clk), .reset(reset), .debounceout(north_deb));
    debouncer south_debouncer(.switchIn(btn_reset), .clk(clk), .reset(reset), .debounceout(south_deb));
    debouncer center_debouncer(.switchIn(btn_door_master), .clk(clk), .reset(reset), .debounceout(center_deb));
    
    sync east_sync(.in(btn_enter), .clk(clk), .out(east_syn));
    sync west_sync(.in(btn_security_reset), .clk(clk), .out(west_syn));
    sync north_sync(.in(btn_morse), .clk(clk), .out(north_syn));
    sync south_sync(.in(btn_reset), .clk(clk), .out(south_syn));
    sync center_sync(.in(btn_door_master), .clk(clk), .out(center_syn));
    
    assign east_sig = east_deb | east_syn;
    assign west_sig = west_deb | west_syn;
    assign north_sig = north_deb | north_syn;
    assign south_sig = south_deb | south_syn;
    assign center_sig = center_deb | center_syn;
        
    spot east_spot(.clk(clk), .spot_in(east_sig), .spot_out(enter));
    spot west_spot(.clk(clk), .spot_in(west_sig), .spot_out(security_reset));
    spot north_spot(.clk(clk), .spot_in(north_sig), .spot_out(morse));
    spot south_spot(.clk(clk), .spot_in(south_sig), .spot_out(reset));
    spot center_spot(.clk(clk), .spot_in(center_sig), .spot_out(door_master));
    
    ///////////////////////////////////////////////////////////////////////////////
    
    
    parameter Closed=3'd0, Open=3'd1, BeginClose=3'd2, BeginOpen=3'd3, DoorMaster=3'd4, Reset=3'd5; // door states
    parameter S1=3'd0, S2=3'd1, Trapped=3'd2, Success=3'd3; // password state
    parameter CLEAR=3'd0, IDLE=3'd1, DOT=3'd2, DASH=3'd4, OUTPUT=3'd5, INIT=3'd6; // morse states
    wire beat1hz, beat05hz, beat2hz;
    
    // Define registers for various states and timeouts
    reg [2:0] door_state, nextstate;
    wire [2:0] password_state;
    wire [3:0] morse_state;
    reg enter_enable, morse_enable; // to disable inputs to sub FSM
                                    // in BeginClose and BeginOpen state
                                    
    reg [4:0] door_timeout; // door on/off time
    reg [4:0] open_timeout; // time that door keep open after a correct password
                            // if door_open_timeout == 5'd31, never close door again until manually change.                
    
    reg [4:0] people_count, next_people_count;
    reg [3:0] ledtoggle;

    // Initialize registers and variables
    initial begin
        door_state=Closed;
        nextstate=Closed;
        enter_enable=1'b1;
        morse_enable=1'b1;
        door_timeout=5'd4;
        open_timeout=5'd30;
        alarm_led = 4'b0000;
        vault_door_led = 4'b0000;
        people_count = 0;
        next_people_count = 0;
        ledtoggle = 4'b1111;
    end
    
    // password logic initiate
    DoorEntryFSM password_fsm(
        .clk(clk),
        .enter(enter & enter_enable),
        .reset(reset | security_reset),
        .switchIn(password_switches),
        .door_state(door_state),
        .beat(beat1hz),
        .password_state(password_state)
    );
    
    // morse code initiate
    wire [3:0] debug;
    DoorExitFSM morse_fsm(
        .clk(clk),
        .morse(north_deb & morse_enable),
        .reset(reset | security_reset),
        .door_state(door_state),
        .beat(beat1hz),
        .morse_state(morse_state),
        .debug(debug)
    );

    
    clockDividerHB #(.THRESHOLD(50_000_000)) clock_1hz (.clk(clk), .reset(reset), .enable(1'b1), .dividedClk(), .beat(beat1hz));
    clockDividerHB #(.THRESHOLD(100_000_000)) clock_05hz (.clk(clk), .reset(reset), .enable(1'b1), .dividedClk(), .beat(beat05hz));
    clockDividerHB #(.THRESHOLD(25_000_000)) clock_2hz (.clk(clk), .reset(reset), .enable(1'b1), .dividedClk(), .beat(beat2hz));

    
    // synchronize door state
    always @(posedge clk) begin 
        door_state = nextstate;
        // Enable enter and morse inputs if the door is closed or in a reset state
        if (door_state == Closed || door_state == Reset) begin
            enter_enable = 1'b1;
            morse_enable = 1'b1;
        end else begin
            enter_enable = 1'b0;
            morse_enable = 1'b0;
        end
    end
    
    // synchronize door_timeout
    always @(posedge beat1hz) begin
        // Decrement the door timeout counter if the door is in BeginOpen or BeginClose state
        if (door_state == BeginOpen || door_state == BeginClose) begin
            if (door_timeout != 0) door_timeout <= door_timeout - 1;
        end else begin
            door_timeout = 5'd4;
        end
    end
    
    // synchronize open_timeout
    always @(posedge beat2hz) begin
         // Decrement the open timeout counter if the door is open
         if (door_state == Open) begin
            if (open_timeout!=0 && open_timeout!=5'd31) open_timeout <= open_timeout - 1;
         end else begin
            open_timeout = 5'd30;
         end
    end
    
    // synchronization for people count 
    always @(*) begin 
        if (door_state == Open || door_state == Reset) begin 
            people_count = next_people_count;
        end 
    end
    
    // next state for people count
    always @(*) begin
        if (door_state == Reset) next_people_count = 0;
        else if (door_state == BeginOpen) begin
            if (morse_state == BeginOpen) begin
                next_people_count = people_count == 0 ? 0 : people_count - 1;
            end
            else if (password_state == Success) begin
                next_people_count = people_count + 1;
            end
            else next_people_count = people_count + 1; // include door master
        end
    end
    
    // next state logic
    always @(*) begin
        case (door_state) 
            Closed: begin
                // Transition to reset state if reset signal asserted, else check for other conditions to change state
                if (reset) nextstate = Reset;
                else if (door_master) nextstate = DoorMaster;
                else if ((password_state == Success || morse_state == BeginOpen) && people_count < 9) begin
                    nextstate = BeginOpen; // Transition to BeginOpen state if conditions met
                end else nextstate = Closed;
            end
            
            BeginOpen: begin
                // Transition to reset state if reset signal asserted, else check door timeout to transition to Open state
                if (reset) nextstate = Reset;
                else if (door_timeout == 0) nextstate = Open;
                else nextstate = BeginOpen;
            end
            
            Open: begin
                // Transition to reset state if reset signal asserted, else check open timeout to transition to BeginClose state
                if (reset) nextstate = Reset;
                else if (open_timeout == 0) nextstate = BeginClose;
                else nextstate = Open;
            end
            
            BeginClose: begin
                // Transition to reset state if reset signal asserted, else check door timeout to transition to Closed state
                if (reset) nextstate = Reset;
                else if (door_timeout == 0) nextstate = Closed;
                else nextstate = BeginClose;
            end
            
            DoorMaster: begin
                // Transition to reset state if reset signal asserted, else always transition to BeginOpen state
                if (reset) nextstate = Reset; 
                else nextstate = BeginOpen;
            end
            
            Reset: begin
                // Stay in Reset state if any of the control signals are active, else return to Reset state
                if (door_master || enter || morse || security_reset) nextstate = Closed;
                else nextstate = Reset;
            end
        endcase    
    end
    

    // output logic - door state
    always @(*) begin
        if (door_state == Reset) vault_door_led = 4'b0000;
        else if (door_state == Closed) vault_door_led = 4'b1111;
        else if (door_state == Open) vault_door_led = 4'b0000;
        else begin
            case (door_timeout)
                5'd4: vault_door_led = 4'b0000;
                5'd3: vault_door_led = door_state == BeginClose? 4'b1000 : 4'b0001;
                5'd2: vault_door_led = door_state == BeginClose? 4'b1100 : 4'b0011;
                5'd1: vault_door_led = door_state == BeginClose? 4'b1110 : 4'b0111;
                5'd0: vault_door_led = 4'b1111;
                default: vault_door_led = 4'b1001;
            endcase 
        end 
    end
    
    
    // output logic - alarm led  
    always @(posedge clk) begin 
        if (password_state == S2) begin
            if (beat05hz) ledtoggle <= ~ledtoggle;
        end else if (password_state == Trapped) begin
            if (beat2hz) ledtoggle <= ~ledtoggle;
        end  
    end
    
    always @(*) begin 
        if (door_state == Reset) alarm_led = 4'b0000;
        else if (password_state == S2 || password_state == Trapped) alarm_led = ledtoggle;
        else alarm_led = ~vault_door_led;
    end
    
    // output logic - morse state
    always @(*) begin
        if (door_state == Reset) morse_led = 4'b0000;
        else morse_led = morse_state;
    end
    
    // output logic - SSD
//    reg [3:0] ssdValue;
//    sevenSegmentDecoder ssd_left(
//        .bcd(ssdValue), 
//        .ssd(ssdCathode) 
//    );
//    always @(*) begin 
//        ssdValue <= people_count;
//        ssdAnode <= 4'b0111;
//    end
    
    assign pCnt = people_count;
    
endmodule
