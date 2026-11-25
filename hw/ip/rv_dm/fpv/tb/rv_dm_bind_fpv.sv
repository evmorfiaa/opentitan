// Copyright lowRISC contributors (OpenTitan project).
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// The formal testbench sees every rv_dm port (.*) plus the internal DMI. Once the JTAG DTM
// (dmi_jtag) is black-boxed, its outputs become free inputs: the request, its valid and the
// response ready before the TAP gate (*_raw), and the DMI reset. The testbench constrains those,
// and observes the request and response at the Debug Module, after the gate.
bind rv_dm rv_dm_assert_fpv #(
  .CheriotSupport (CheriotSupport)
) tb_i (
  .dmi_req,
  .dmi_req_valid,
  .dmi_req_ready,
  .dmi_rsp,
  .dmi_rsp_valid,
  .dmi_rsp_ready,
  .dmi_req_valid_raw (gen_jtag_gating.dmi_req_valid_raw),
  .dmi_rsp_ready_raw (gen_jtag_gating.dmi_rsp_ready_raw),
  .dmi_rst_n,
  .*
);

// TL-UL protocol checks on the three bus ports (V1: PRELIMINARY_ASSERTION_CHECKS_ADDED). On a
// device port (regs, mem) the incoming requests become assumptions (*_M) and the responses
// assertions (*_A); on the host port (sba) the other way round.
// dbg_tl_d is not checked: it belongs to the DMI variant and is tied off in Earl Grey.
bind rv_dm tlul_assert #(.EndpointType("Device")) tlul_assert_regs_i (
  .clk_i, .rst_ni, .h2d(regs_tl_d_i), .d2h(regs_tl_d_o)
);
bind rv_dm tlul_assert #(.EndpointType("Device")) tlul_assert_mem_i (
  .clk_i, .rst_ni, .h2d(mem_tl_d_i), .d2h(mem_tl_d_o)
);
bind rv_dm tlul_assert #(.EndpointType("Host")) tlul_assert_sba_i (
  .clk_i, .rst_ni, .h2d(sba_tl_h_o), .d2h(sba_tl_h_i)
);
