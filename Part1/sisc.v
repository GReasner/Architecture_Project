// ECE:3350 SISC processor project
// main SISC module, part 1

`timescale 1ns/100ps  

module sisc (clk, rst_f, ir);

  input clk, rst_f;
  input [31:0] ir;

// declare all internal wires here
// instruction fields
wire [31:28] alu_opcode;
wire [27:24] mm;
wire [19:16] regA;
wire [15:12] regB;
wire [23:20] write_reg;
wire [15:0] imm;

// RF outputs
wire [31:0] rsa;
wire [31:0] rsb;

//ALU controls
wire rf_we;
wire wb_sel; 
wire [3:0] alu_op;

//ALU outputs
wire [3:0] stat_en;
wire [3:0] stat;
wire [31:0] alu_result;

//stat output
wire [3:0] stat_out

//MUX output
wire [15:0] mux_out


// component instantiation goes here



  initial
  
// put a $monitor statement here.  



endmodule


