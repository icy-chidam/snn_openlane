# Post-Layout Metrics Summary

**Design:** `snn_top_v3`  
**Run date:** 2026-04-19  
**PDK:** SkyWater Sky130A — `sky130_fd_sc_hd` (high-density)  
**Flow:** OpenLane 2  

---

## Physical Implementation

| Parameter | Value |
|---|---|
| Standard cell count | 8,879 |
| Sequential cells (flip-flops) | 279 |
| Combinational cells | 5,513 |
| Buffers / Inverters | 1 / 187 |
| Timing repair buffers | 990 |
| Clock buffers | 46 |
| Clock inverters | 30 |
| Antenna diode cells | 24 |
| Fill cells | 9,495 |
| Tap cells | 1,809 |
| Die area | 142,130 µm² (0.142 mm²) |
| Core area | 129,319 µm² (0.129 mm²) |
| Core utilisation | 44.3 % |
| IO pins | 39 |

---

## Routing

| Parameter | Value |
|---|---|
| Total wirelength | 167,115 µm |
| Via count | 48,335 (all single-cut) |
| Routing DRC errors (final) | **0** |
| DRC iterations to clean | 6 |
| Antenna violations (post-fix) | 3 (resolved by diode insertion) |
| Disconnected pins | 0 |

---

## Power (TT / 25 °C / 1.80 V — Nominal Corner)

| Component | Power |
|---|---|
| Internal (cell) | 7.919 mW |
| Switching (dynamic) | 8.106 mW |
| Leakage | 0.064 µW |
| **Total** | **16.025 mW** |

---

## Timing (TT / 25 °C / 1.80 V)

| Parameter | Value |
|---|---|
| Clock period | 10.000 ns |
| Setup slack (worst) | **+1.567 ns** |
| Hold slack (worst) | **+0.305 ns** |
| Setup violations | **0** |
| Hold violations | **0** |
| Clock skew (setup) | 0.438 ns |
| Clock skew (hold) | −0.446 ns |
| Max frequency | **118.6 MHz** |

---

## Physical Verification

| Check | Result |
|---|---|
| Magic DRC | **0 errors** |
| KLayout DRC | **0 errors** |
| LVS (Netgen) | **0 mismatches** |
| Illegal overlaps | 0 |
| Power grid DRC (VPWR) | 0 violations |
| Power grid DRC (VGND) | 0 violations |
| IR drop (worst, VPWR) | 2.36 mV |
| XOR layout difference | 0 (vs. reference) |

---

## IR Drop (Nominal Corner)

| Net | Worst drop | Average drop |
|---|---|---|
| VPWR | 2.36 mV | 0.24 mV |
| VGND | 2.40 mV | 0.25 mV |

Worst supply voltage on VPWR: **1.7976 V** (well within 5 % tolerance of 1.80 V).
