`include "define.vh"


/**
 * Controller for MIPS 5-stage pipelined CPU.
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module controller (/*AUTOARG*/
	input wire clk,  // main clock
	input wire rst,  // synchronous reset
	input wire interrupter,
	// debug
	`ifdef DEBUG
	input wire debug_en,  // debug enable
	input wire debug_step,  // debug step clock
	`endif
	// instruction decode
	input wire [31:0] inst,  // instruction
	input wire is_jump_exe,  // whether instruction in EXE stage is jump/branch instruction
	input wire [4:0] regw_addr_exe,  // register write address from EXE stage
	input wire wb_wen_exe,  // register write enable signal feedback from EXE stage
	input wire is_jump_mem,  // whether instruction in MEM stage is jump/branch instruction
	input wire [4:0] regw_addr_mem,  // register write address from MEM stage
	input wire wb_wen_mem,  // register write enable signal feedback from MEM stage
	
	output reg [2:0] pc_src,  // how would PC change to next
	output reg imm_ext,  // whether using sign extended to immediate data
	output reg [1:0] exe_a_src,  // data source of operand A for ALU
	output reg [2:0] exe_b_src,  // data source of operand B for ALU
	output reg [3:0] exe_alu_oper,  // ALU operation type
	output reg mem_ren,  // memory read enable signal
	output reg mem_wen,  // memory write enable signal
	output reg [1:0] wb_addr_src,  // address source to write data back to registers
	output reg wb_data_src,  // data source of data being written back to registers
	output reg wb_wen,  // register write enable signal
	output reg wb_wen_cp,
	output reg unrecognized,  // whether current instruction can not be recognized
	// pipeline control
	output reg if_rst,  // stage reset signal
	output reg if_en,  // stage enable signal
	input wire if_valid,  // stage valid flag
	
	output reg id_rst,
	output reg id_en,
	input wire id_valid,
	
	output reg exe_rst,
	output reg exe_en,
	input wire exe_valid,
	
	output reg mem_rst,
	output reg mem_en,
	input wire mem_valid,
	
	output reg wb_rst,
	output reg wb_en,
	input wire wb_valid,
	output reg [1:0] forwards,
	output reg [1:0] forwardt,
	output reg [1:0] forward_cp,
	input wire mem_ren_exe,
	input wire mem_ren_mem,
	input wire predict_wrong,
	input wire wb_wen_cp_exe,
	input wire wb_wen_cp_mem,
	output reg epc_wen,
	output reg status_set,
	output reg pc_ehb,
	input wire status,
	output wire valid_interrupter
	);
	
	`include "mips_define.vh"
	
	// instruction decode
	reg rs_used, rt_used, cp_used;
	reg is_save;

	always @(*) begin
		pc_src = PC_NEXT;
		imm_ext = 0;
		exe_a_src = EXE_A_RS;
		exe_b_src = EXE_B_RT;
		exe_alu_oper = EXE_ALU_ADD;
		mem_ren = 0;
		mem_wen = 0;
		wb_addr_src = WB_ADDR_RD;
		wb_data_src = WB_DATA_ALU;
		wb_wen = 0;
		rs_used = 0;
		rt_used = 0;
		unrecognized = 0;
		is_save = 0;
		wb_wen_cp = 0;
		cp_used = 0;
		case (inst[31:26])
			INST_R: begin
				case (inst[5:0])
					R_FUNC_JR: begin
						pc_src = PC_JR;
						rs_used = 1;
					end
					R_FUNC_ADD: begin
						exe_alu_oper = EXE_ALU_ADD;
						wb_addr_src = WB_ADDR_RD;
						wb_data_src = WB_DATA_ALU;
						wb_wen = 1;
						rs_used = 1;
						rt_used = 1;
					end
					R_FUNC_SUB: begin
						exe_alu_oper = EXE_ALU_SUB;
						wb_addr_src = WB_ADDR_RD;
						wb_data_src = WB_DATA_ALU;
						wb_wen = 1;
						rs_used = 1;
						rt_used = 1;
					end
					R_FUNC_AND: begin
						exe_alu_oper = EXE_ALU_AND;
						wb_addr_src = WB_ADDR_RD;
						wb_data_src = WB_DATA_ALU;
						wb_wen = 1;
						rs_used = 1;
						rt_used = 1;
					end
					R_FUNC_OR: begin
						exe_alu_oper = EXE_ALU_OR;
						wb_addr_src = WB_ADDR_RD;
						wb_data_src = WB_DATA_ALU;
						wb_wen = 1;
						rs_used = 1;
						rt_used = 1;
					end
					R_FUNC_SLT: begin
						exe_alu_oper = EXE_ALU_SLT;
						wb_addr_src = WB_ADDR_RD;
						wb_data_src = WB_DATA_ALU;
						wb_wen = 1;
						rs_used = 1;
						rt_used = 1;
					end
					R_FUNC_SRL: begin
						exe_alu_oper = EXE_ALU_SR;
						exe_a_src = EXE_A_SA;
						wb_addr_src = WB_ADDR_RD;
						wb_data_src = WB_DATA_ALU;
						wb_wen = 1;
						rt_used = 1;
					end
					default: begin
						unrecognized = 1;
					end
				endcase
			end
			INST_CP: begin
				if (inst[25:21] == CP_FUNC_MTC) begin
					exe_alu_oper = EXE_ALU_ADD;
					exe_a_src = EXE_A_LINK;
					exe_b_src = EXE_B_RT;
					wb_addr_src = WB_ADDR_RD;
					wb_data_src = WB_DATA_ALU;
					wb_wen_cp = 1;
					rt_used = 1;
				end
				else if (inst[25:21] == CP_FUNC_MFC) begin
					exe_alu_oper = EXE_ALU_ADD;
					exe_a_src = EXE_A_LINK;
					exe_b_src = EXE_B_CP;
					wb_addr_src = WB_ADDR_RT;
					wb_data_src = WB_DATA_ALU;
					wb_wen = 1;
					cp_used = 1;
				end
				else if (inst[5:0] == CP_ERET) begin
					pc_src = PC_ERET;
				end
				else 
					unrecognized = 1;
			end
			INST_J: begin
				pc_src = PC_JUMP;
			end
			INST_JAL: begin
				pc_src = PC_JUMP;
				exe_a_src = EXE_A_LINK;
				exe_b_src = EXE_B_LINK;
				exe_alu_oper = EXE_ALU_ADD;
				wb_addr_src = WB_ADDR_LINK;
				wb_data_src = WB_DATA_ALU;
				wb_wen = 1;
			end
			INST_BEQ: begin
				pc_src = PC_BEQ;
				exe_a_src = EXE_A_BRANCH;
				exe_b_src = EXE_A_BRANCH;
				exe_alu_oper = EXE_ALU_ADD;
				imm_ext = 1;
				rs_used = 1;
				rt_used = 1;
			end
			INST_BNE: begin
				pc_src = PC_BNE;
				exe_a_src = EXE_A_BRANCH;
				exe_b_src = EXE_A_BRANCH;
				exe_alu_oper = EXE_ALU_ADD;
				imm_ext = 1;
				rs_used = 1;
				rt_used = 1;
			end
			INST_ADDI: begin
				imm_ext = 1;
				exe_b_src = EXE_B_IMM;
				exe_alu_oper = EXE_ALU_ADD;
				wb_addr_src = WB_ADDR_RT;
				wb_data_src = WB_DATA_ALU;
				wb_wen = 1;
				rs_used = 1;
			end
			INST_ANDI: begin
				imm_ext = 0;
				exe_b_src = EXE_B_IMM;
				exe_alu_oper = EXE_ALU_AND;
				wb_addr_src = WB_ADDR_RT;
				wb_data_src = WB_DATA_ALU;
				wb_wen = 1;
				rs_used = 1;
			end
			INST_ORI: begin
				imm_ext = 0;
				exe_b_src = EXE_B_IMM;
				exe_alu_oper = EXE_ALU_OR;
				wb_addr_src = WB_ADDR_RT;
				wb_data_src = WB_DATA_ALU;
				wb_wen = 1;
				rs_used = 1;
			end
			INST_SLTI: begin
				imm_ext = 1;
				exe_b_src = EXE_B_IMM;
				exe_alu_oper = EXE_ALU_SLT;
				wb_addr_src = WB_ADDR_RT;
				wb_data_src = WB_DATA_ALU;
				wb_wen = 1;
				rs_used = 1;
			end
			INST_LW: begin
				imm_ext = 1;
				exe_a_src = EXE_A_RS;
				exe_b_src = EXE_B_IMM;
				exe_alu_oper = EXE_ALU_ADD;
				mem_ren = 1;
				wb_addr_src = WB_ADDR_RT;
				wb_data_src = WB_DATA_MEM;
				wb_wen = 1;
				rs_used = 1;
			end
			INST_SW: begin
				imm_ext = 1;
				exe_a_src = EXE_A_RS;
				exe_b_src = EXE_B_IMM;
				exe_alu_oper = EXE_ALU_ADD;
				mem_wen = 1;
				rs_used = 1;
				rt_used = 1;
				is_save = 1;
			end
			INST_LUI: begin
				imm_ext = 1;
				exe_alu_oper = EXE_ALU_LUI;
				wb_addr_src = WB_ADDR_RT;
				wb_data_src = WB_DATA_ALU;
				exe_b_src = EXE_B_IMM;
				wb_wen = 1;
				rt_used = 1;
			end
			default: begin
				unrecognized = 1;
			end
		endcase
	end
	
	// pipeline control
	reg reg_stall;
	reg [1:0] branch_stall;
	wire [4:0] addr_rs, addr_rt;
	
	assign
		addr_rs = inst[25:21],
		addr_rt = inst[20:16],
		addr_rd = inst[15:11];
	
	always @(*) begin
		reg_stall = 0;
		forwards = 0;
		forwardt = 0; 
		if (rt_used && addr_rt != 0) begin
			if (regw_addr_exe == addr_rt && wb_wen_exe) begin
				if (mem_ren_exe == 1) begin
					if (is_save == 1)
						forwardt = 3;
					else 
						reg_stall = 1;
				end
				else 
					forwardt = 1;
			end
			else if (regw_addr_mem == addr_rt && wb_wen_mem) begin
				if (mem_ren_mem == 0)
					forwardt = 2;
				else
					forwardt = 3;
			end
		end
		if (rs_used && addr_rs != 0) begin
			if (regw_addr_exe == addr_rs && wb_wen_exe) begin
				if (mem_ren_exe == 1) begin
					reg_stall = 1;
				end
				else 
					forwards = 1;
			end
			else if (regw_addr_mem == addr_rs && wb_wen_mem) begin
				if (mem_ren_mem == 0)
					forwards = 2;
				else
					forwards = 3;
			end
		end
		if (cp_used) begin
			if (regw_addr_exe == addr_rd && wb_wen_cp_exe)
				forward_cp = 1;
			else if (regw_addr_mem == addr_rd && wb_wen_cp_mem)
				forward_cp = 2;
		end
		if (reg_stall) begin
			forwards = 0;
			forwardt = 0;
		end
	end
	
	always @(*) begin
		branch_stall = 0;
		if (pc_src == PC_JUMP || pc_src == PC_JR || pc_src == PC_ERET || is_jump_exe) 
			branch_stall = 1;
		else if (is_jump_mem)
			branch_stall = 2;
	end
	
	`ifdef DEBUG
	reg debug_step_prev;
	
	always @(posedge clk) begin
		debug_step_prev <= debug_step;
	end
	`endif
	assign valid_interrupter = (status == 1)? 0: interrupter;

	always @(*) begin
		if_rst = 0;
		if_en = 1;
		id_rst = 0;
		id_en = 1;
		exe_rst = 0;
		exe_en = 1;
		mem_rst = 0;
		mem_en = 1;
		wb_rst = 0;
		wb_en = 1;
		status_set = 0;
		epc_wen = 0;
		pc_ehb = 0;
		if (valid_interrupter) begin
			if_en = 0;
			id_en = 0;
			exe_en = 0;
			mem_en = 0;
			wb_en = 1;
			if_rst = 1;
			id_rst = 1;
			exe_rst = 1;
			mem_rst = 1;
			epc_wen = 1;
			status_set = 1;
			pc_ehb = 1;
		end 
		else begin
			if (rst) begin
				if_rst = 1;
				id_rst = 1;
				exe_rst = 1;
				mem_rst = 1;
				wb_rst = 1;
			end
			`ifdef DEBUG
			// suspend and step execution
			else if ((debug_en) && ~(~debug_step_prev && debug_step)) begin
				if_en = 0;
				id_en = 0;
				exe_en = 0;
				mem_en = 0;
				wb_en = 0;
			end
			`endif
			// this stall indicate that ID is waiting for previous instruction, should insert NOPs between ID and EXE.
			else if (reg_stall) begin
				if_en = 0;
				id_en = 0;
				exe_rst = 1;
			end
			// this stall indicate that a jump/branch instruction is running, so that 3 NOP should be inserted between IF and ID
			else if (branch_stall == 1) begin
				if_en = 0;
				if_rst = 1;
				id_rst = 1;
			end 
			else if (branch_stall == 2) begin
				id_rst = 1;
			end
			else if (predict_wrong) begin
				id_rst = 1;
				exe_rst = 1;
				mem_rst = 1;
			end
		end
	end

endmodule
