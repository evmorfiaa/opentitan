// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// FPV top for rv_dm in the Earl Grey configuration (as earlgrey_pd_main.sv instantiates it): JTAG
// transport (UseDmiInterface = 0), CHERIoT support, one hart, no RACL. Every rv_dm port is a free
// input or an observed output; the checks are bound in by rv_dm_bind_fpv.sv. clk_lc_i is the same
// clock as clk_i in Earl Grey, so the top has one clock.
module rv_dm_tb
  import rv_dm_reg_pkg::*;
(
  input  logic                                 clk_i,
  input  logic                                 rst_ni,
  input  logic                                 rst_lc_ni,
  input  logic [31:0]                          next_dm_addr_i,
  input  lc_ctrl_pkg::lc_tx_t                  lc_hw_debug_clr_i,
  input  lc_ctrl_pkg::lc_tx_t                  lc_hw_debug_en_i,
  input  lc_ctrl_pkg::lc_tx_t                  lc_dft_en_i,
  input  lc_ctrl_pkg::lc_tx_t                  pinmux_hw_debug_en_i,
  input  lc_ctrl_pkg::lc_tx_t                  lc_check_byp_en_i,
  input  lc_ctrl_pkg::lc_tx_t                  lc_escalate_en_i,
  input  lc_ctrl_pkg::lc_tx_t                  lc_init_done_i,
  input  logic                                 strap_en_i,
  input  logic                                 strap_en_override_i,
  input  prim_mubi_pkg::mubi8_t                otp_dis_rv_dm_late_debug_i,
  input  prim_mubi_pkg::mubi4_t                cheriot_ena_i,
  input  prim_mubi_pkg::mubi4_t                scanmode_i,
  input  logic                                 scan_rst_ni,
  output logic                                 ndmreset_req_o,
  output logic                                 dmactive_o,
  output logic [NrHarts-1:0]                   debug_req_o,
  input  logic [NrHarts-1:0]                   unavailable_i,
  input  tlul_pkg::tl_h2d_t                    regs_tl_d_i,
  output tlul_pkg::tl_d2h_t                    regs_tl_d_o,
  input  tlul_pkg::tl_h2d_t                    mem_tl_d_i,
  output tlul_pkg::tl_d2h_t                    mem_tl_d_o,
  output tlul_pkg::tl_h2d_t                    sba_tl_h_o,
  input  tlul_pkg::tl_d2h_t                    sba_tl_h_i,
  input  prim_alert_pkg::alert_rx_t [NumAlerts-1:0] alert_rx_i,
  output prim_alert_pkg::alert_tx_t [NumAlerts-1:0] alert_tx_o,
  input  top_racl_pkg::racl_policy_vec_t       racl_policies_i,
  output top_racl_pkg::racl_error_log_t        racl_error_o,
  input  jtag_pkg::jtag_req_t                  jtag_i,
  output jtag_pkg::jtag_rsp_t                  jtag_o,
  input  tlul_pkg::tl_h2d_t                    dbg_tl_d_i,
  output tlul_pkg::tl_d2h_t                    dbg_tl_d_o
);

  rv_dm #(
    .UseDmiInterface (1'b0),
    .CheriotSupport  (1'b1)
  ) dut (
    .clk_i,
    .clk_lc_i (clk_i),
    .rst_ni,
    .rst_lc_ni,
    .next_dm_addr_i,
    .lc_hw_debug_clr_i,
    .lc_hw_debug_en_i,
    .lc_dft_en_i,
    .pinmux_hw_debug_en_i,
    .lc_check_byp_en_i,
    .lc_escalate_en_i,
    .lc_init_done_i,
    .strap_en_i,
    .strap_en_override_i,
    .otp_dis_rv_dm_late_debug_i,
    .cheriot_ena_i,
    .scanmode_i,
    .scan_rst_ni,
    .ndmreset_req_o,
    .dmactive_o,
    .debug_req_o,
    .unavailable_i,
    .regs_tl_d_i,
    .regs_tl_d_o,
    .mem_tl_d_i,
    .mem_tl_d_o,
    .sba_tl_h_o,
    .sba_tl_h_i,
    .alert_rx_i,
    .alert_tx_o,
    .racl_policies_i,
    .racl_error_o,
    .jtag_i,
    .jtag_o,
    .dbg_tl_d_i,
    .dbg_tl_d_o
  );

endmodule : rv_dm_tb
