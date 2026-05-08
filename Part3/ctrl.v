// ECE:3350 SISC computer project
// finite state machine - Part 3 version

`timescale 1ns/100ps

module ctrl (
    clk, rst_f, opcode, mm, stat,
    rf_we, alu_op, wb_sel,
    br_sel, pc_rst, pc_write, pc_sel, ir_load,
    dm_we, dm_addr_sel, rb_sel, swap_sel, wr_sel
);

  input clk, rst_f;
  input [3:0] opcode;
  input [3:0] mm;
  input [3:0] stat;

  output reg rf_we;
  output reg [3:0] alu_op;
  output reg wb_sel;

  output reg br_sel;
  output reg pc_rst;
  output reg pc_write;
  output reg pc_sel;
  output reg ir_load;

  // Part 3 control signals
  output reg dm_we;        // data memory write enable
  output reg dm_addr_sel;  // 0 = immediate address, 1 = ALU address
  output reg rb_sel;       // 0 = Rt field, 1 = Rd field into RF read B
  output reg swap_sel;     // 0 = normal writeback, 1 = swap write data
  output reg wr_sel;       // 0 = Rd field, 1 = Rs field as RF write register

  parameter start0 = 0, start1 = 1, fetch = 2, decode = 3, execute = 4, mem = 5, writeback = 6;

  parameter NOOP = 0, REG_OP = 1, REG_IM = 2, SWAP = 3, BRA = 4, BRR = 5, BNE = 6, BNR = 7;
  parameter JPA = 8, JPR = 9, LOD = 10, STR = 11, CALL = 12, RET = 13, HLT = 15;

  parameter AM_ABS = 4'h0;
  parameter AM_IDX = 4'h8;

  reg [2:0] present_state, next_state;

  initial
    present_state = start0;

  always @(posedge clk, negedge rst_f)
  begin
    if (rst_f == 1'b0)
      present_state <= start1;
    else
      present_state <= next_state;
  end

  always @(present_state, rst_f)
  begin
    case(present_state)
      start0:    next_state = start1;
      start1:    next_state = (rst_f == 1'b0) ? start1 : fetch;
      fetch:     next_state = decode;
      decode:    next_state = execute;
      execute:   next_state = mem;
      mem:       next_state = writeback;
      writeback: next_state = fetch;
      default:   next_state = start1;
    endcase
  end

  always @(*)
  begin
    rf_we       = 1'b0;
    wb_sel      = 1'b0;
    alu_op      = 4'b0000;

    br_sel      = 1'b0;
    pc_rst      = 1'b0;
    pc_write    = 1'b0;
    pc_sel      = 1'b0;
    ir_load     = 1'b0;

    dm_we       = 1'b0;
    dm_addr_sel = 1'b0;
    rb_sel      = 1'b0;
    swap_sel    = 1'b0;
    wr_sel      = 1'b0;

    // STA, STX, and SWP need Rd on register-file read port B.
    // For stores, Rd is the value being written to memory.
    if ((opcode == STR) || (opcode == SWAP))
    rb_sel = 1'b1;

    // LDX/STX use Rs + imm as the memory address. LDA/STA use imm directly.
    if ((opcode == LOD || opcode == STR) && mm == AM_IDX)
      dm_addr_sel = 1'b1;

    case (present_state)
      start0,
      start1: begin
        pc_rst = 1'b1;
      end

      fetch: begin
        ir_load  = 1'b1;
        pc_write = 1'b1;
        pc_sel   = 1'b0;
      end

      decode: begin
        case (opcode)
          BRA, BRR: begin
            br_sel = (opcode == BRA) ? 1'b1 : 1'b0;
            if ((mm & stat) != 4'b0000) begin
              pc_sel   = 1'b1;
              pc_write = 1'b1;
            end
          end

          BNE, BNR: begin
            br_sel = (opcode == BNE) ? 1'b1 : 1'b0;
            if ((mm & stat) == 4'b0000) begin
              pc_sel   = 1'b1;
              pc_write = 1'b1;
            end
          end

          JPA, JPR, CALL, RET: begin
            br_sel   = (opcode == JPA || opcode == CALL) ? 1'b1 : 1'b0;
            pc_sel   = 1'b1;
            pc_write = 1'b1;
          end
        endcase
      end

      execute,
      mem,
      writeback: begin
        if (opcode == REG_OP)
          alu_op = 4'b0001;      // RF-RF ALU op, update status
        else if (opcode == REG_IM)
          alu_op = 4'b0011;      // RF-imm ALU op, update status
        else if ((opcode == LOD || opcode == STR) && mm == AM_IDX)
          alu_op = 4'b0100;      // address = Rs + imm, do not update status
      end
    endcase

    if (present_state == mem) begin
      if (opcode == STR) begin
        dm_we = 1'b1;
      end

      // First half of SWP: Rs <- Rd
      if (opcode == SWAP) begin
        rf_we    = 1'b1;
        swap_sel = 1'b1;
        wr_sel   = 1'b1;
      end
    end

    if (present_state == writeback) begin
      if (opcode == REG_OP || opcode == REG_IM) begin
        rf_we = 1'b1;
      end
      else if (opcode == LOD) begin
        rf_we  = 1'b1;
        wb_sel = 1'b1;           // write memory data to Rd
      end
      // Second half of SWP: Rd <- Rs
      else if (opcode == SWAP) begin
        rf_we    = 1'b1;
        swap_sel = 1'b1;
        wr_sel   = 1'b0;
      end
    end
  end

  always @ (opcode)
  begin
    if (opcode == HLT)
    begin
      #5 $display ("Halt.");
      $stop;
    end
  end
endmodule
