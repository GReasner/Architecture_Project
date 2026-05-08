// ECE:3350 SISC processor project
// main SISC module, part 2

`timescale 1ns/100ps  

module sisc (clk, rst_f);

  input clk, rst_f;

// declare all internal wires here
// instruction fields
wire [3:0] opcode;
wire [3:0] mm;
wire [3:0] regA;
wire [3:0] regB;
wire [3:0] write_reg;
wire [15:0] imm;

// instruction / pc wires
wire [31:0] instr;
wire [31:0] im_data;
wire [15:0] pc_out;
wire [15:0] br_addr;

// RF outputs
wire [31:0] rsa;
wire [31:0] rsb;

// controls
wire rf_we;
wire wb_sel; 
wire [3:0] alu_op;

wire br_sel;
wire pc_rst;
wire pc_write;
wire pc_sel;
wire ir_load;

// ALU outputs
wire [3:0] stat_en;
wire [3:0] stat;
wire [31:0] alu_result;

// stat output
wire [3:0] stat_out;

// MUX output
wire [31:0] write_data;


// assign instructions
assign opcode = instr[31:28];
assign mm = instr[27:24];

assign write_reg = instr[23:20];
assign regA = instr[19:16];
assign regB = instr[15:12];

assign imm = instr[15:0];

// component instantiation goes here
ctrl CTRL (
    clk, rst_f,
    opcode, mm, stat_out,
    rf_we, alu_op, wb_sel,
    br_sel, pc_rst, pc_write, pc_sel, ir_load
);

rf u2 (clk, regA, regB, write_reg, write_data, rf_we, rsa, rsb);

alu ALU (clk, rsa, rsb, imm, stat_out[3], alu_op, mm, alu_result, stat, stat_en);

statreg STATREG (clk, stat, stat_en, stat_out);

mux32 MUX (alu_result, 32'b0, wb_sel, write_data);

im IM (pc_out, im_data);

ir u9 (clk, ir_load, im_data, instr);

pc u10 (clk, br_addr, pc_sel, pc_write, pc_rst, pc_out);

br BR (pc_out, imm, br_sel, br_addr);

initial begin
  $display(" time |   instr  |   pc    | op mm wd a  b  |    r1    |    r2    |    r3    |  alu_out | stat | alu  br pw ps we");
  $monitor("%5t | %08h | %08h | %1h  %1h  %1h  %1h  %1h | %08h | %08h | %08h | %08h | %04b | %03b  %1b  %1b  %1b  %1b",
           $time,
           instr,
           pc_out,
           opcode,
           mm,
           write_reg,
           regA,
           regB,
           u2.ram_array[1],
           u2.ram_array[2],
           u2.ram_array[3],
           alu_result,
           stat_out,
           alu_op,
           br_sel,
           pc_write,
           pc_sel,
           rf_we);
end

endmodule