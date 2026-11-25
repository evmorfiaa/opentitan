// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// Formal testbench for rv_dm (Earl Grey configuration), bound in by rv_dm_bind_fpv.sv.
//
// For now this holds only the environment: the rules that keep rv_dm's free inputs legal, so that
// the design's own assertions and the TL-UL protocol checks (tlul_assert)


`include "prim_assert.sv"

module rv_dm_assert_fpv
  import tlul_pkg::*;
  import rv_dm_reg_pkg::*;
#(
  parameter bit CheriotSupport = 1'b1  // for the V2 checks
) (
  input logic                           clk_i,
  input logic                           rst_ni,
  input logic                           rst_lc_ni,

  // Debug enable inputs
  input lc_ctrl_pkg::lc_tx_t            lc_hw_debug_en_i,
  input lc_ctrl_pkg::lc_tx_t            lc_dft_en_i,
  input lc_ctrl_pkg::lc_tx_t            lc_hw_debug_clr_i,
  input lc_ctrl_pkg::lc_tx_t            lc_init_done_i,
  input lc_ctrl_pkg::lc_tx_t            lc_check_byp_en_i,
  input lc_ctrl_pkg::lc_tx_t            lc_escalate_en_i,
  input logic                           strap_en_i,
  input logic                           strap_en_override_i,
  input lc_ctrl_pkg::lc_tx_t            pinmux_hw_debug_en_i,
  input prim_mubi_pkg::mubi8_t          otp_dis_rv_dm_late_debug_i,

  // CHERIoT mode, DFT
  input prim_mubi_pkg::mubi4_t          cheriot_ena_i,
  input prim_mubi_pkg::mubi4_t          scanmode_i,
  input logic                           scan_rst_ni,

  // Core and system side
  input logic                           ndmreset_req_o,
  input logic                           dmactive_o,
  input logic [NrHarts-1:0]             debug_req_o,
  input logic [NrHarts-1:0]             unavailable_i,
  input logic [31:0]                    next_dm_addr_i,

  // Bus ports
  input tl_h2d_t                        regs_tl_d_i,
  input tl_d2h_t                        regs_tl_d_o,
  input tl_h2d_t                        mem_tl_d_i,
  input tl_d2h_t                        mem_tl_d_o,
  input tl_h2d_t                        sba_tl_h_o,
  input tl_d2h_t                        sba_tl_h_i,
  input tl_h2d_t                        dbg_tl_d_i,
  input tl_d2h_t                        dbg_tl_d_o,

  // Alerts and RACL
  input prim_alert_pkg::alert_rx_t [NumAlerts-1:0] alert_rx_i,
  input prim_alert_pkg::alert_tx_t [NumAlerts-1:0] alert_tx_o,
  input top_racl_pkg::racl_policy_vec_t racl_policies_i,
  input top_racl_pkg::racl_error_log_t  racl_error_o,

  // JTAG towards pinmux
  input jtag_pkg::jtag_rsp_t            jtag_o,

  // DMI at the Debug Module, after the TAP gate
  input dm::dmi_req_t                   dmi_req,
  input logic                           dmi_req_valid,
  input logic                           dmi_req_ready,
  input dm::dmi_resp_t                  dmi_rsp,
  input logic                           dmi_rsp_valid,
  input logic                           dmi_rsp_ready,

  // DMI as the black-boxed JTAG transport drives it, before the TAP gate: free inputs
  input logic                           dmi_req_valid_raw,
  input logic                           dmi_rsp_ready_raw,
  input logic                           dmi_rst_n
);

  /////////////////
  // Environment //
  /////////////////

  // A handshake at the Debug Module.
  logic dmi_req_fire, dmi_rsp_fire;
  assign dmi_req_fire = dmi_req_valid & dmi_req_ready;
  assign dmi_rsp_fire = dmi_rsp_valid & dmi_rsp_ready;

  // A request has been taken and its response not yet.
  logic dmi_open_q;
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      dmi_open_q <= 1'b0;
    end else if (dmi_req_fire) begin
      dmi_open_q <= 1'b1;
    end else if (dmi_rsp_fire) begin
      dmi_open_q <= 1'b0;
    end
  end

  // The transport resets the DMI only with the system: it never asks for a DMI reset on its own
  // Holds in reset too, so the Debug Module's DMI logic starts from its reset state.
  `ASSUME(Env_DmiRstFollowsRst_M, dmi_rst_n == rst_ni, clk_i, 1'b0)

  // One transaction at a time, no new request until the open one has its response.
  `ASSUME(Env_DmiOneAtATime_M, dmi_open_q |-> !dmi_req_valid_raw)

  // A request is held, unchanged, until the Debug Module takes it.
  `ASSUME(Env_DmiHeld_M,
          dmi_req_valid_raw && !dmi_req_fire |=> dmi_req_valid_raw && $stable(dmi_req))

  // The transport takes every response.
  `ASSUME(Env_DmiRspTaken_M, dmi_rsp_ready_raw)

  // The JTAG transport sends 7-bit DMI addresses the upper address bits are 0.
  `ASSUME(Env_DmiAddr7_M, dmi_req_valid_raw |-> dmi_req.addr[31:7] == '0)

  // No scan test. dbg_tl_d, the bus port of the DMI variant is unused in Earl Grey.
  `ASSUME(Env_NoScan_M, scanmode_i == prim_mubi_pkg::MuBi4False && scan_rst_ni, clk_i, 1'b0)
  `ASSUME(Env_DbgTlIdle_M, dbg_tl_d_i == tlul_pkg::TL_H2D_DEFAULT, clk_i, 1'b0)

  // The inputs Earl Grey ties off keep their tied values.
  `ASSUME(Env_TieOffs_M,
          next_dm_addr_i == '0 && unavailable_i == '0 &&
          lc_escalate_en_i == lc_ctrl_pkg::Off && lc_check_byp_en_i == lc_ctrl_pkg::Off &&
          !strap_en_i && !strap_en_override_i &&
          racl_policies_i == top_racl_pkg::RACL_POLICY_VEC_DEFAULT,
          clk_i, 1'b0)


  // Sanity, requests and responses still happen under these rules.
  `COVER(Env_DmiReqTaken_C, dmi_req_fire)
  `COVER(Env_DmiRspTaken_C, dmi_rsp_fire)

endmodule
