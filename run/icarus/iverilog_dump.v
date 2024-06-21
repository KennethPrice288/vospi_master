module iverilog_dump();
initial begin
    $dumpfile("testbench.fst");
    $dumpvars(0, testbench);
end
endmodule
