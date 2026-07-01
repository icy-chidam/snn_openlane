# Timing Report — All PVT Corners

**Design:** `snn_top_v3` | **Clock period:** 10 ns | **Tool:** OpenSTA (post-PnR)

---

## Setup Slack (ns) — Positive = Timing Met

| Corner | Temp | Voltage | Setup slack | Hold slack | Setup viol. | Hold viol. |
|---|---|---|---|---|---|---|
| nom_tt_025C_1v80 | 25 °C | 1.80 V | **+1.567** | +0.305 | **0** | **0** |
| nom_ff_n40C_1v95 | −40 °C | 1.95 V | **+4.662** | +0.113 | **0** | **0** |
| nom_ss_100C_1v60 | 100 °C | 1.60 V | −6.140 ⚠️ | +0.823 | 66 | 0 |
| min_tt_025C_1v80 | 25 °C | 1.80 V | **+1.654** | +0.300 | **0** | **0** |
| min_ff_n40C_1v95 | −40 °C | 1.95 V | **+4.707** | +0.111 | **0** | **0** |
| min_ss_100C_1v60 | 100 °C | 1.60 V | −5.925 ⚠️ | +0.821 | 66 | 0 |
| max_tt_025C_1v80 | 25 °C | 1.80 V | **+1.454** | +0.309 | **0** | **0** |
| max_ff_n40C_1v95 | −40 °C | 1.95 V | **+4.611** | +0.117 | **0** | **0** |
| max_ss_100C_1v60 | 100 °C | 1.60 V | −6.358 ⚠️ | +0.827 | 66 | 0 |

---

## Notes

- **Nominal operating corner** is `nom_tt_025C_1v80` (TT / 25 °C / 1.80 V). All metrics in the paper refer to this corner.
- **SS corner violations** (100 °C / 1.60 V) are expected at the 10 ns target period for Sky130 slow-slow characterisation. Increasing the clock period to **17 ns** eliminates all SS violations if operation at elevated temperature is required.
- **Hold violations are zero at all corners**, confirming robust hold margin across the full PVT space.
- **Fanout violations (36)** appear at all corners due to the `MAX_FANOUT_CONSTRAINT: 6` setting. Relaxing this to 8 in `config.json` will eliminate them with minimal timing impact.
- **Slew violations at SS** (10–17 cells): caused by long wire segments in the mode-controller feedback path under slow-corner characterisation. Buffer insertion on these nets resolves the violations.

---

## Clock Skew Summary (Nominal Corner)

| Parameter | Value |
|---|---|
| Worst setup skew | +0.438 ns |
| Worst hold skew  | −0.446 ns |
| Clock buffer count | 46 |
| Clock inverter count | 30 |
