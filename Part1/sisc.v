// ECE:3350 SISC processor project
// main SISC module, part 1

`timescale 1ns/100ps  

module sisc (clk, rst_f, ir);

  input clk, rst_f;
  input [31:0] ir;

// declare all internal wires here
// instruction fields
wire [3:0] opcode;
wire [3:0] mm;
wire [3:0] regA;
wire [3:0] regB;
wire [3:0] write_reg;
wire [15:0] imm;

// RF outputs
wire [31:0] rsa;
wire [31:0] rsb;

//controls
wire rf_we;
wire wb_sel; 
wire [3:0] alu_op;

//ALU outputs
wire [3:0] stat_en;
wire [3:0] stat;
wire [31:0] alu_result;

//stat output
wire [3:0] stat_out;

//MUX output
wire [31:0] write_data; //mux out


//assign instructions
assign opcode = ir[31:28];
assign mm = ir[27:24];

assign write_reg = ir[23:20];
assign regA = ir[19:16];
assign regB = ir[15:12];

assign imm = ir[15:0];

// component instantiation goes here
ctrl CTRL (clk, rst_f, opcode, mm, stat_out, rf_we, alu_op, wb_sel);

rf RF (clk, regA, regB, write_reg, write_data, rf_we, rsa, rsb);

alu ALU (clk, rsa, rsb, imm, stat_out[3], alu_op, mm, alu_result, stat, stat_en);

statreg STATREG (clk, stat, stat_en, stat_out);

mux32 MUX (alu_result, 32'b0, wb_sel, write_data);


initial
  $monitor("IR=%h R1=%h R2=%h R3=%h R4=%h R5=%h ALU_OP=%b WB_SEL=%b RF_WE=%b",
            ir,
            RF.ram_array[1],
            RF.ram_array[2],
            RF.ram_array[3],
            RF.ram_array[4],
            RF.ram_array[5],
            alu_op,
            wb_sel,
            rf_we);

endmodule


