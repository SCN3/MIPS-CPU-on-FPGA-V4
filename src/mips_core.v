`include "define.vh"


/**
 * MIPS 5-stage pipeline CPU Core, including data path and co-processors.
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module mips_core (
	input wire clk,  // main clock
	input wire rst,  // synchronous reset
	input wire interrupter,
	// debug
	`ifdef DEBUG
	input wire debug_en,  // debug enable
	input wire debug_step,  // debug step clock
	input wire [6:0] debug_addr,  // debug address
	output wire [31:0] debug_data,  // debug data
	`endif
	input wire [2:0] interrupter_no,
	output wire [31:0] inst_addr_id,
	output wire [31:0] inst_addr_exe,
	output wire [31:0] inst_addr_mem,
	output wire [31:0] inst_addr_wb,
	// instruction interfaces
	output wire inst_ren,  // instruction read enable signal
	output wire [31:0] inst_addr,  // address of instruction needed
	input wire [31:0] inst_data,  // instruction fetched
	// memory interfaces
	output wire mem_ren,  // memory read enable signal
	output wire mem_wen,  // memory write enable signal
	output wire [31:0] mem_addr,  // address of memory
	output wire [31:0] mem_dout,  // data writing to memory
	input wire [31:0] mem_din  // data read from memory
	);
	
	// control signals
	wire [31:0] inst_data_ctrl;
	
	wire [2:0] pc_src_ctrl;
	wire imm_ext_ctrl;
	wire [1:0] exe_a_src_ctrl;
	wire [2:0] exe_b_src_ctrl;
	wire [3:0] exe_alu_oper_ctrl;
	wire mem_ren_ctrl;
	wire mem_wen_ctrl;
	wire [1:0] wb_addr_src_ctrl;
	wire wb_data_src_ctrl;
	wire wb_wen_ctrl;
	
	wire is_jump_exe, is_jump_mem;
	wire [4:0] regw_addr_exe, regw_addr_mem;
	wire wb_wen_exe, wb_wen_mem;
	
	wire if_rst, if_en, if_valid;
	wire id_rst, id_en, id_valid;
	wire exe_rst, exe_en, exe_valid;
	wire mem_rst, mem_en, mem_valid;
	wire wb_rst, wb_en, wb_valid;
	wire [1:0] forwards;
	wire [1:0] forwardt;
	wire [1:0] forward_cp;
	wire mem_ren_exe, mem_ren_mem;
	wire wb_wen_cp_ctrl, wb_wen_cp_exe, wb_wen_cp_mem;
	wire epc_wen;
	wire status_set;
	wire status_reset;
	wire pc_ehb;
	wire status;
	wire valid_interrupter;
	// controller
	controller CONTROLLER (
		.clk(clk),
		.rst(rst),
		.interrupter(interrupter),
		`ifdef DEBUG
		.debug_en(debug_en),
		.debug_step(debug_step),
		`endif
		.inst(inst_data_ctrl),
		.is_jump_exe(is_jump_exe),
		.regw_addr_exe(regw_addr_exe),
		.wb_wen_exe(wb_wen_exe),
		.is_jump_mem(is_jump_mem),
		.regw_addr_mem(regw_addr_mem),
		.wb_wen_mem(wb_wen_mem),
		.pc_src(pc_src_ctrl),
		.imm_ext(imm_ext_ctrl),
		.exe_a_src(exe_a_src_ctrl),
		.exe_b_src(exe_b_src_ctrl),
		.exe_alu_oper(exe_alu_oper_ctrl),
		.mem_ren(mem_ren_ctrl),
		.mem_wen(mem_wen_ctrl),
		.wb_addr_src(wb_addr_src_ctrl),
		.wb_data_src(wb_data_src_ctrl),
		.wb_wen(wb_wen_ctrl),
		.unrecognized(),
		.if_rst(if_rst),
		.if_en(if_en),
		.if_valid(if_valid),
		.id_rst(id_rst),
		.id_en(id_en),
		.id_valid(id_valid),
		.exe_rst(exe_rst),
		.exe_en(exe_en),
		.exe_valid(exe_valid),
		.mem_rst(mem_rst),
		.mem_en(mem_en),
		.mem_valid(mem_valid),
		.wb_rst(wb_rst),
		.wb_en(wb_en),
		.wb_valid(wb_valid),
		.forwards(forwards),
		.forwardt(forwardt),
		.mem_ren_exe(mem_ren_exe),
		.mem_ren_mem(mem_ren_mem),
		.predict_wrong(predict_wrong),
		.wb_wen_cp(wb_wen_cp_ctrl),
		.wb_wen_cp_exe(wb_wen_cp_exe),
		.wb_wen_cp_mem(wb_wen_cp_mem),
		.forward_cp(forward_cp),
		.epc_wen(epc_wen),
		.status_set(status_set),
		.pc_ehb(pc_ehb),
		.status(status),
		.valid_interrupter(valid_interrupter)
	);
	
	// data path
	datapath DATAPATH (
		.clk(clk),
		`ifdef DEBUG
		.debug_addr(debug_addr),
		.debug_data(debug_data),
		.inst_addr_id(inst_addr_id),
		.inst_addr_exe(inst_addr_exe),
		.inst_addr_mem(inst_addr_mem),
		.inst_addr_wb(inst_addr_wb),
		`endif
		.interrupter_no(interrupter_no),
		.inst_data_id(inst_data_ctrl),
		.is_jump_exe(is_jump_exe),
		.regw_addr_exe(regw_addr_exe),
		.wb_wen_exe(wb_wen_exe),
		.is_jump_mem(is_jump_mem),
		.regw_addr_mem(regw_addr_mem),
		.wb_wen_mem(wb_wen_mem),
		.pc_src_ctrl(pc_src_ctrl),
		.imm_ext_ctrl(imm_ext_ctrl),
		.exe_a_src_ctrl(exe_a_src_ctrl),
		.exe_b_src_ctrl(exe_b_src_ctrl),
		.exe_alu_oper_ctrl(exe_alu_oper_ctrl),
		.mem_ren_ctrl(mem_ren_ctrl),
		.mem_wen_ctrl(mem_wen_ctrl),
		.wb_addr_src_ctrl(wb_addr_src_ctrl),
		.wb_data_src_ctrl(wb_data_src_ctrl),
		.wb_wen_ctrl(wb_wen_ctrl),
		.if_rst(if_rst),
		.if_en(if_en),
		.if_valid(if_valid),
		.inst_ren(inst_ren),
		.inst_addr(inst_addr),
		.inst_data(inst_data),
		.id_rst(id_rst),
		.id_en(id_en),
		.id_valid(id_valid),
		.exe_rst(exe_rst),
		.exe_en(exe_en),
		.exe_valid(exe_valid),
		.mem_rst(mem_rst),
		.mem_en(mem_en),
		.mem_valid(mem_valid),
		.mem_ren(mem_ren),
		.mem_wen(mem_wen),
		.mem_addr(mem_addr),
		.mem_dout(mem_dout),
		.mem_din(mem_din),
		.wb_rst(wb_rst),
		.wb_en(wb_en),
		.wb_valid(wb_valid),
		.forwards(forwards),
		.forwardt(forwardt),
		.mem_ren_exe(mem_ren_exe),
		.mem_ren_mem(mem_ren_mem),
		.predict_wrong(predict_wrong),
		.wb_wen_cp_ctrl(wb_wen_cp_ctrl),
		.wb_wen_cp_exe(wb_wen_cp_exe),
		.wb_wen_cp_mem(wb_wen_cp_mem),
		.forward_cp(forward_cp),
		.epc_wen(epc_wen),
		.status_set(status_set),
		.pc_ehb(pc_ehb),
		.status(status),
		.valid_interrupter(valid_interrupter),
		.interrupter(interrupter)
	);
	
endmodule
