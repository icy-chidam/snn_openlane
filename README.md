# Approximate SNN Accelerator — Sky130 ASIC

> **Runtime-Configurable Approximate Spiking Neural Network Accelerator with Spike-Density-Driven MAC Switching in Open-Source 130 nm CMOS**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Technology](https://img.shields.io/badge/Technology-SkyWater%20130nm-blue.svg)](https://github.com/google/skywater-pdk)
[![Flow](https://img.shields.io/badge/EDA%20Flow-OpenLane%202-green.svg)](https://github.com/efabless/openlane2)
[![DRC](https://img.shields.io/badge/DRC-Clean-brightgreen.svg)]()
[![LVS](https://img.shields.io/badge/LVS-Clean-brightgreen.svg)]()
[![Frequency](https://img.shields.io/badge/Max%20Frequency-118.6%20MHz-orange.svg)]()

---

## Overview

This repository contains the complete RTL design, OpenLane 2 implementation configuration, post-layout verification reports, and accompanying IEEE conference paper for a configurable approximate Spiking Neural Network (SNN) accelerator targeting the open-source SkyWater 130 nm process (Sky130A).

The accelerator implements a two-layer fully-connected SNN topology (2 inputs → 8 hidden LIF neurons → 2 output LIF neurons) with five hardware-level novelties not present in any prior open-source neuromorphic ASIC:

| Novel Feature | Description |
|---|---|
| **3-mode MAC unit** | Selects exact, Mitchell logarithmic, or truncation approximate multiplication at runtime via a 2-bit control signal |
| **Spike-density mode controller** | Autonomous hardware block that switches MAC precision based on an 8-cycle sliding window of hidden-layer spike activity — no software intervention required |
| **On-chip LFSR spike encoder** | Converts 8-bit rate-coded inputs to Bernoulli spike trains using a Galois LFSR, eliminating off-chip spike generation |
| **Writable weight register file** | Synthesisable 16 × 8-bit synchronous register file with runtime write port — reprogrammable without re-synthesis |
| **Spike-activity clock gating** | De-asserts clock enable after 8 consecutive idle cycles; maps to `sky130_fd_sc_hd__dlclkp_1` ICG cells automatically |

The design closes timing with **zero DRC errors** and **zero LVS mismatches** at the nominal process corner (TT / 25 °C / 1.80 V).

---

## Key Results

| Metric | Value |
|---|---|
| Technology | SkyWater Sky130A (130 nm CMOS) |
| Supply voltage | 1.80 V |
| Clock period | 10 ns |
| **Maximum frequency** | **118.6 MHz** |
| Standard cell count | 8,879 |
| Core area | 0.129 mm² |
| Die area | 0.142 mm² |
| Core utilisation | 44.3 % |
| Setup slack (TT) | +1.567 ns |
| Hold slack (TT) | +0.305 ns |
| **Total power (TT, active)** | **16.03 mW** |
| Internal power | 7.919 mW |
| Switching power | 8.106 mW |
| Leakage power | 0.064 µW |
| DRC errors | **0** |
| LVS errors | **0** |
| Route wirelength | 167,115 µm |

### MAC Mode Trade-off

| Mode | MAC Power | Classification Error vs Exact | Condition |
|---|---|---|---|
| Exact (00) | 9.20 mW | baseline | High spike activity |
| Mitchell approx (01) | 6.62 mW | +3.8 % | Medium spike activity |
| Truncation approx (10) | 5.42 mW | +11.2 % | Low spike activity |

---

## Repository Structure

```
approximate-snn-sky130/
│
├── src/
│   ├── snn_top_v3.v          # Top-level RTL — all 6 sub-modules in one file
│   └── tb_snn_top_v3.v       # 10-test self-checking testbench
|
├── reports/
│   ├── metrics_summary.md    # Human-readable post-layout metrics
│   └── timing_corners.md     # Setup/hold slack across all 9 PVT corners
│
├── docs/
│   ├── blockdiag.pdf         # System block diagram (vector)
│   ├── blockdiag.png         # System block diagram (raster, 300 dpi)
│   └── snn_paper.pdf         # IEEE conference paper (pre-print)
│
├── LICENSE                   # MIT License
├── CITATION.cff              # Citation metadata
├── .gitignore                # Ignores large run artefacts
└── README.md                 # This file
```

---

## Architecture

```
act_0 ──► Spike encoder (LFSR #0) ──►┐
                                      ├──► Weight memory ──► 3-mode MAC ──► ×8 Hidden LIF ──► ×2 Output LIF ──► spikes[1:0]
act_1 ──► Spike encoder (LFSR #1) ──►┘      (16×8)               ▲               │                   │
                                                                   │               │                   │
                                                          Mode controller ◄────────┘                   │
                                                          (spike density)                              ▼
                                                                                         Clock-gate monitor
                                                                                         (clk_enable out)
```

The mode controller monitors the 8-cycle sliding sum of hidden-layer spikes and selects the MAC mode according to:

```
sum > 48  →  Exact (00)      # high activity: critical decision region
16 < sum ≤ 48  →  Mitchell (01)   # medium: balanced accuracy/power
sum ≤ 16  →  Truncation (10)  # low activity: maximum power saving
```

---

## Module Hierarchy

```
snn_top_v3                          (top)
├── spike_encoder  ×2               (LFSR Bernoulli encoder)
├── weight_mem     ×16              (synthesisable register file)
├── mac_unit       ×16              (3-mode: exact / Mitchell / trunc)
├── mode_controller                 (sliding-window spike counter)
├── lif_neuron_v3  ×8              (hidden layer)
├── lif_neuron_v3  ×2              (output layer)
└── spike_activity_monitor          (clock gate controller)
```

---

## Getting Started

### Prerequisites

| Tool | Version | Purpose |
|---|---|---|
| [OpenLane 2](https://github.com/efabless/openlane2) | ≥ 2.1.0 | RTL-to-GDSII flow |
| [SkyWater PDK](https://github.com/google/skywater-pdk) | sky130A | Process design kit |
| [Icarus Verilog](https://github.com/steveicarus/iverilog) | ≥ 11.0 | Behavioural simulation |
| [GTKWave](https://gtkwave.sourceforge.net) | ≥ 3.3 | Waveform viewing |
| Python | ≥ 3.9 | OpenLane scripting |

### 1 — Behavioural Simulation

```bash
# Clone the repository
git clone https://github.com/<your-username>/approximate-snn-sky130.git
cd approximate-snn-sky130

# Compile and simulate
iverilog -o sim.vvp src/snn_top_v3.v src/tb_snn_top_v3.v
vvp sim.vvp

# View waveform
gtkwave tb_snn_top_v3.vcd &
```

Expected console output:

```
========================================
  SNN Top v3 Testbench — 10 Tests
========================================
PASS T1  | spikes=00 mode=01 clk_en=1
PASS T2  | spikes=00 mode=10 clk_en=1
...
  >> SPIKE detected t=... spikes=11 mode=00 clk_en=1
PASS T10 | clk_enable de-asserted after idle
========================================
  Results: 10 PASS  0 FAIL
========================================
```

### 2 — OpenLane ASIC Implementation

```bash
# Set environment variables (adjust paths for your installation)
export PDK_ROOT=/path/to/skywater-pdk
export PDK=sky130A

# Run the complete RTL-to-GDSII flow
cd openlane
openlane config.json

# View the GDSII layout
klayout runs/<RUN_TAG>/final/gds/snn_top_v3.gds
```

The flow runs the following steps automatically:

```
Lint → Synthesis (Yosys) → Floorplan → Placement → CTS →
Global Routing → Detailed Routing (TritonRoute) → RCX →
Post-PnR STA (OpenSTA) → DRC (Magic) → LVS (Netgen) → GDSII
```

Full run time on a modern 8-core workstation: approximately 25–40 minutes.

---

## Reproducing the Results

The run directory included in this repository (`openlane/runs/`) contains the complete intermediate artefacts from the verified run dated **2026-04-19**. Key output files:

| File | Location | Description |
|---|---|---|
| `snn_top_v3.gds` | `runs/.../final/gds/` | Final GDSII layout |
| `snn_top_v3.lef` | `runs/.../final/lef/` | Abstract layout (LEF) |
| `snn_top_v3.spice` | `runs/.../final/spice/` | Extracted netlist |
| `snn_top_v3.sdf` | `runs/.../final/sdf/` | Timing annotation |
| `metrics.json` | `runs/.../final/` | All flow metrics (JSON) |

To inspect the full metric set programmatically:

```python
import json

with open("openlane/runs/<RUN_TAG>/final/metrics.json") as f:
    m = json.load(f)

print(f"Total power:  {m['power__total']*1000:.3f} mW")
print(f"Core area:    {m['design__core__area']/1e6:.3f} mm²")
print(f"Setup slack:  {m['timing__setup__ws__corner:nom_tt_025C_1v80']:.3f} ns")
```

---

## Timing Summary (All PVT Corners)

| Corner | Temp | Voltage | Setup slack | Hold slack | Violations |
|---|---|---|---|---|---|
| TT (nominal) | 25 °C | 1.80 V | **+1.567 ns** | +0.305 ns | **0** |
| FF (fast) | −40 °C | 1.95 V | +4.662 ns | +0.113 ns | 0 |
| SS (slow) | 100 °C | 1.60 V | −6.358 ns | +0.827 ns | 66 ⚠️ |

> **Note:** The SS corner at 100 °C / 1.60 V exceeds the intended operating envelope. The design is specified for the TT corner. Increasing the clock period to 17 ns eliminates all SS violations if extreme-temperature operation is required.

---

## Design Parameters

All key parameters are exposed as Verilog `parameter` declarations and can be changed without modifying the flow:

| Parameter | Module | Default | Description |
|---|---|---|---|
| `WIDTH` | all | `8` | Datapath width (bits) |
| `LEAK` | `lif_neuron_v3` | `8'h04` | Per-cycle membrane leak |
| `THRESH` | `lif_neuron_v3` | `8'h60` / `8'h40` | Firing threshold (hidden / output) |
| `WINDOW` | `mode_controller` | `8` | Spike-density sliding window (cycles) |
| `HI_THRESH` | `mode_controller` | `6` | High-activity threshold (→ exact mode) |
| `LO_THRESH` | `mode_controller` | `2` | Low-activity threshold (→ trunc mode) |
| `IDLE_CYCLES` | `spike_activity_monitor` | `8` | Cycles before clock gate asserts |

---


## License

This project is released under the **MIT License**. See [`LICENSE`](LICENSE) for the full text.

The SkyWater Sky130A PDK is licensed separately under the [Apache 2.0 License](https://github.com/google/skywater-pdk/blob/main/LICENSE).  
OpenLane is licensed under the [Apache 2.0 License](https://github.com/efabless/openlane2/blob/main/LICENSE).

---

## Acknowledgements

- The SkyWater Technology / Google / Efabless team for the open-source Sky130 PDK and OpenLane flow
- The developers of Yosys, OpenROAD, TritonRoute, Magic, Netgen, and KLayout
- SRM Institute of Science & Technology for computational resources

---

<sub>Last updated: April 2026 · N. Chidambaresh · cn7414@srmist.edu.in</sub>
