module testbench  (output logic error_o = 0
,output logic pass_o = 0);

    // Parameters
    localparam CLK_PERIOD = 25; // 40 MHz Clock for 640x480 @ 60Hz (25ns)
    

    // Parameters
    localparam packet_bytes_p = 164;
    localparam frame_packets_p = 60;
    
    // Clock and reset signals
    wire clk_i;
    reg reset_i;
    
    // Inputs
    reg start_i;
    reg miso_i;
    
    // Outputs
    wire sclk_o;
    wire cs_o;
    wire [7:0] data_o;
    wire valid_o;

    logic sending_discards = 0;


    //instantiate vospi_master dut
    vospi_master #(
        .packet_bytes_p(packet_bytes_p),
        .frame_packets_p(frame_packets_p),
        .sync_idle_cycles_p(10) //extremely low sync idle for easy testing
    ) dut (
        .clk_i(clk_i)
        ,.reset_i(reset_i)
        ,.start_i(start_i)
        ,.miso_i(miso_i)
        ,.sclk_o(sclk_o)
        ,.cs_o(cs_o)
        ,.data_o(data_o)
        ,.valid_o(valid_o)
    );

    // Clock generator
    nonsynth_clock_gen #(.cycle_time_p(10)) clock_gen_inst(.clk_o(clk_i));
    // Testbench procedure
    initial begin
    `ifndef COCOTB
    `ifdef VERILATOR
        $dumpfile("verilator.vcd");
    `else
        $dumpfile("iverilog.vcd");
    `endif
        $dumpvars;
    `endif

        // Initialize Inputs
        reset_i = 1;
        start_i = 0;
        miso_i = 0;
        
        // Wait 100 ns for global reset to finish
        #100;
        reset_i = 0;
        
        // Apply a test stimulus
        @(negedge clk_i); start_i = 1;
        @(negedge clk_i); start_i = 0;

        @(negedge clk_i); send_packet(16'h0F00); // Simulate discard packet


        send_frame();
        between_frames(2);
        send_frame();
        between_frames(5);
        send_frame();


        pass_o = 1; #1;
        $finish;
    end

    // Task to send a byte via MISO
    task send_byte;
    input [7:0] byte_i;
    begin
        for (integer i = 0; i < 8; i++) begin
            @(negedge sclk_o);
            miso_i = byte_i[7-i];
            $display("Sending bit: %b of byte: %b", miso_i, byte_i);
            @(posedge sclk_o); #1;
        end
    end
    endtask

    // Task to send a packet
    task send_packet;
    input [15:0] id;
    logic [7:0] id_msb;
    logic [7:0] id_lsb;
    begin
        id_msb = id[15:8];
        id_lsb = id[7:0];
        // Send the ID
        $display("Sending id byte %h", id_msb);
        send_byte(id_msb);
        $display("Sending id byte %h", id_lsb);
        send_byte(id_lsb);
    
        // Send CRC (dummy, not calculated here)
        $display("Sending crc byte %h", id_msb);
        send_byte(id_msb);
        $display("Sending crc byte %h", id_lsb);
        send_byte(id_lsb);

        // Send dummy payload data
        for (integer i = 0; i < packet_bytes_p - 4; i++) begin
        send_byte(8'h00); // Fill the rest with dummy data
        end
    
    end
endtask

task send_frame;
    begin
        for(logic [15:0] i = 0; i < 16'd80; i++) begin
            send_packet(i);
        end
    end
endtask

task between_frames;
    input integer x;
    begin
        integer random;
        sending_discards = 1;
        do begin
            random = $urandom_range(1, x);
            send_packet(16'h0F00);
        end while (random != 1);
        sending_discards = 0;
    end
endtask

endmodule
