`include "define.vh"


/**
 * Display using character LCD.
 * Author: Zhao, Hongyu  <power_zhy@foxmail.com>
 */
module display (
	input wire clk,
	input wire rst,
	input wire [7:0] addr,
	input wire [31:0] data,
	input wire [31:0] inst_addr,
	input wire [31:0] inst_addr_id,
	input wire [31:0] inst_addr_exe,
	input wire [31:0] inst_addr_mem,
	input wire [31:0] inst_addr_wb,
	input wire [31:0] inst_data,
	// character LCD interfaces
	output wire lcd_e,
	output wire lcd_rs,
	output wire lcd_rw,
	output wire [3:0] lcd_dat
	);
	
	reg [255:0] strdata = "* Hello World! *f   d  e  m  b  ";
	
	function [7:0] num2str;
		input [3:0] number;
		begin
			if (number < 10)
				num2str = "0" + number;
			else
				num2str = "A" - 10 + number;
		end
	endfunction
	
	genvar i;
	generate for (i=0; i<8; i=i+1) begin: NUM2STR
		always @(posedge clk) begin
			strdata[128+8*i+7-:8] <= num2str(data[4*i+3-:4]);
		end
	end
	endgenerate
	
	generate for (i=0; i<2; i=i+1) begin: NUM2STR2
		always @(posedge clk) begin
			strdata[104+8*i+7-:8] <= num2str(inst_addr[4*i+3-:4]);
			strdata[72+8*i+7-:8] <= num2str(inst_addr_id[4*i+3-:4]);
			strdata[48+8*i+7-:8] <= num2str(inst_addr_exe[4*i+3-:4]);
			strdata[24+8*i+7-:8] <= num2str(inst_addr_mem[4*i+3-:4]);
			strdata[0+8*i+7-:8] <= num2str(inst_addr_wb[4*i+3-:4]);
		end
	end
	endgenerate

	
	
	
	always @(posedge clk) begin
		strdata[199:192] <= " ";
		case (addr[7:5])
			3'b000: strdata[255:200] <= {"REGS-", num2str(addr[5:4]), num2str(addr[3:0])};
			3'b001: case (addr[4:0])
				// datapath debug signals, MUST be compatible with 'debug_data_signal' in 'datapath.v'
				0: strdata[255:200] <= "IF-ADDR";
				1: strdata[255:200] <= "IF-INST";
				2: strdata[255:200] <= "ID-ADDR";
				3: strdata[255:200] <= "ID-INST";
				4: strdata[255:200] <= "EX-ADDR";
				5: strdata[255:200] <= "EX-INST";
				6: strdata[255:200] <= "MM-ADDR";
				7: strdata[255:200] <= "MM-INST";
				8: strdata[255:200] <= "RS-ADDR";
				9: strdata[255:200] <= "RS-DATA";
				10: strdata[255:200] <= "RT-ADDR";
				11: strdata[255:200] <= "RT-DATA";
				12: strdata[255:200] <= "IMMEDAT";
				13: strdata[255:200] <= "ALU-AIN";
				14: strdata[255:200] <= "ALU-BIN";
				15: strdata[255:200] <= "ALU-OUT";
				16: strdata[255:200] <= "-------";
				17: strdata[255:200] <= "FORWARD";
				18: strdata[255:200] <= "MEMOPER";
				19: strdata[255:200] <= "MEMADDR";
				20: strdata[255:200] <= "MEMDATR";
				21: strdata[255:200] <= "MEMDATW";
				22: strdata[255:200] <= "WB-ADDR";
				23: strdata[255:200] <= "WB-DATA";
				default: strdata[255:200] <= "RESERVE";
			endcase
			3'b010: strdata[255:200] <= {"CP0S-0", num2str(addr[3:0])};
			default: strdata[255:200] <= "RESERVE";
		endcase
	end
	
	reg refresh = 0;
	reg [7:0] addr_buf;
	reg [31:0] data_buf;
	reg [31:0] inst_addr_buf, inst_data_buf;
	reg [22:0] count= 0;
	always @(posedge clk) begin
		addr_buf <= addr;
		data_buf <= data;
		inst_addr_buf <= inst_addr;
		inst_data_buf <= inst_data;
		count <= count + 1;
		refresh <= (count == 0); 
			/*(addr_buf != addr) || 
			(data_buf != data) || 
			(inst_addr_buf != inst_addr) ||
			(inst_data_buf != inst_data);*/
	end
	
	displcd DISPLCD (
		.CCLK(clk),
		.reset(rst | refresh),
		.strdata(strdata),
		.rslcd(lcd_rs),
		.rwlcd(lcd_rw),
		.elcd(lcd_e),
		.lcdd(lcd_dat)
		);
	
endmodule
