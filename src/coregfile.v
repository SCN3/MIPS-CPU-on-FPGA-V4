
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    00:30:24 06/09/2016 
// Design Name: 
// Module Name:    coregfile 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module coregfile (
	input wire clk,  // main clock
	// debug
	`ifdef DEBUG
	input wire [3:0] debug_addr,  // debug address
	output wire [31:0] debug_data_cp,  // debug data
	`endif
	// read channel 
	input wire [3:0] addr_r_cp,
	output wire [31:0] data_r_cp,
	// write channel W
	input wire en_w_cp,
	input wire [3:0] addr_w_cp,
	input wire [31:0] data_w_cp,
	output wire [31:0] data_r_epc,
	input wire en_w_epc,
	input wire [31:0] data_w_epc,
	output wire [31:0] data_r_status,
	input wire en_w_status_set,
	input wire en_w_status_reset,
	output wire [31:0] data_r_ehb,
	input wire [2:0] interrupter_no,
	output wire [31:0] data_r_cause
	);
	`include "mips_define.vh"
	reg [31:0] regfile [0:15];  // $zero is always zero
	/*
	// write
	always @(posedge clk) begin
		if (en_w && addr_w != 0)
			regfile[addr_w] <= data_w;
	end
	
	// read
	always @(negedge clk) begin
		data_a <= addr_a == 0 ? 0 : regfile[addr_a];
		data_b <= addr_b == 0 ? 0 : regfile[addr_b];
	end
	
	// debug
	`ifdef DEBUG
	always @(negedge clk) begin
		debug_data <= debug_addr == 0 ? 0 : regfile[debug_addr];
	end
	`endif
	*/
	
	// write
	always @(negedge clk) begin
		if (en_w_cp)
			regfile[addr_w_cp] <= data_w_cp;
		if (en_w_epc) begin
			regfile[CP_ADDR_CAUSE] <= 1 << interrupter_no;
			regfile[CP_ADDR_EPC] <= data_w_epc;
		end
		if (en_w_status_reset) 
			regfile[CP_ADDR_STATUS] <= 0;
		else if (en_w_status_set)
			regfile[CP_ADDR_STATUS] <= 1;
	end
	// read
//	always @(*) begin
//		data_a = addr_a == 0 ? 0 : regfile[addr_a];
//		data_b = addr_b == 0 ? 0 : regfile[addr_b];
//	end
	assign data_r_cp = regfile[addr_r_cp];
	assign data_r_epc = regfile[CP_ADDR_EPC];
	assign data_r_status = regfile[CP_ADDR_STATUS];
	assign data_r_ehb = regfile[CP_ADDR_EHB];
	assign data_r_cause = regfile[CP_ADDR_CAUSE];
	// debug
	`ifdef DEBUG
	assign debug_data_cp = regfile[debug_addr];
//	always @(*) begin
//		debug_data = debug_addr == 0 ? 0 : regfile[debug_addr];
//	end
	`endif
	
endmodule

