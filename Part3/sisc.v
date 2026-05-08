// ECE:3350 SISC processor project
// main SISC module, part 3

`timescale 1ns/100ps

module sisc (clk, rst_f);

  input clk, rst_f;

  // instruction fields
  wire [3:0] opcode;
  wire [3:0] mm;
  wire [3:0] regA;
  wire [3:0] regB;
  wire [3:0] regB_muxed;
  wire [3:0] write_reg;
  wire [3:0] write_reg_muxed;
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

  // Part 3 controls
  wire dm_we;
  wire dm_addr_sel;
  wire rb_sel;
  wire swap_sel;
  wire wr_sel;

  // ALU outputs
  wire [3:0] stat_en;
  wire [3:0] stat;
  wire [31:0] alu_result;

  // stat output
  wire [3:0] stat_out;

  // data memory wires
  wire [15:0] dm_addr;
  wire [31:0] dm_read_data;

  // writeback wires
  wire [31:0] normal_write_data;
  wire [31:0] swap_write_data;
  wire [31:0] write_data;

  // instruction field assignments
  assign opcode = instr[31:28];
  assign mm = instr[27:24];

  assign write_reg = instr[23:20];  // Rd
  assign regA = instr[19:16];       // Rs
  assign regB = instr[15:12];       // Rt for register-register ops

  assign imm = instr[15:0];

  ctrl CTRL (
      clk, rst_f,
      opcode, mm, stat_out,
      rf_we, alu_op, wb_sel,
      br_sel, pc_rst, pc_write, pc_sel, ir_load,
      dm_we, dm_addr_sel, rb_sel, swap_sel, wr_sel
  );

  // For normal ALU instructions, read_regb = Rt.
  // For STX and SWP, read_regb = Rd so the value in Rd is available on rsb.
  mux4 RBMUX (regB, write_reg, rb_sel, regB_muxed);

  // For normal writes, write Rd. During the first SWP write, write Rs.
  mux4 WRMUX (write_reg, regA, wr_sel, write_reg_muxed);

  rf u2 (clk, regA, regB_muxed, write_reg_muxed, write_data, rf_we, rsa, rsb);

  alu ALU (clk, rsa, rsb, imm, stat_out[3], alu_op, mm, alu_result, stat, stat_en);

  statreg STATREG (clk, stat, stat_en, stat_out);

  // Memory address mux:
  // LDA/STA use imm directly. LDX/STX use low 16 bits of ALU result = Rs + imm.
  mux16 DMMUX (imm, alu_result[15:0], dm_addr_sel, dm_addr);

  dm u11 (dm_addr, dm_addr, rsb, dm_we, dm_read_data);

  // Normal writeback is ALU result, except loads write data memory output.
  mux32 WBMUX (alu_result, dm_read_data, wb_sel, normal_write_data);

  // SWP writes rsb first into Rs, then rsa into Rd.
  // wr_sel is high only during the first SWP write.
  mux32 SWPMUX (rsa, rsb, wr_sel, swap_write_data);

  mux32 FINALWBMUX (normal_write_data, swap_write_data, swap_sel, write_data);

  im IM (pc_out, im_data);

  ir u9 (clk, ir_load, im_data, instr);

  pc u10 (clk, br_addr, pc_sel, pc_write, pc_rst, pc_out);

  br BR (pc_out, imm, br_sel, br_addr);

  initial begin
    $display(" time |   instr  |   pc    | op mm wd a  b  |    r1    |    r2    |    r3    |  alu_out | dm_data  | stat | alu  br pw ps we dwen");
    $monitor("%5t | %08h | %08h | %1h  %1h  %1h  %1h  %1h | %08h | %08h | %08h | %08h | %08h | %04b | %03b  %1b  %1b  %1b  %1b  %1b",
             $time,
             instr,
             pc_out,
             opcode,
             mm,
             write_reg_muxed,
             regA,
             regB_muxed,
             u2.ram_array[1],
             u2.ram_array[2],
             u2.ram_array[3],
             alu_result,
             dm_read_data,
             stat_out,
             alu_op,
             br_sel,
             pc_write,
             pc_sel,
             rf_we,
             dm_we);
  end
endmodule
