# Design Report: MIPS PWM Motor Controller

## Introduction

This project builds a complete CPU-controlled PWM motor controller. A MIPS program is loaded from `memfile.dat`, executes on the 5-stage pipelined CPU, accesses memory-mapped I/O addresses, updates PWM registers, and causes `pwm_out` to change duty cycle.

## System Architecture

The system path is:

```text
memfile.dat -> instruction_memory -> MIPS pipeline -> data_memory MMIO -> pwm_controller -> pwm_out
                                               ^
                                               |
                                         switches[7:0]
```

The top-level `mips` module exposes `clk`, `rst_n`, `switches[7:0]`, and `pwm_out`. The datapath passes `switches` into `data_memory`; `data_memory` owns the PWM duty and enable registers and connects them to `pwm_controller`.

## Pipeline Architecture

The selected source already contains a 5-stage pipeline in `datapath.v`:

| Stage | Evidence |
|---|---|
| IF | `pc`, `instruction_memory`, `pc_plus4_F`, and IF/ID register. |
| ID | Register file read, sign extension, early branch compare. |
| EX | ALU operand forwarding muxes and ALU execution. |
| MEM | EX/MEM register and `data_memory` access. |
| WB | MEM/WB register and `result_W` writeback mux. |

These structures were preserved. The changes only added the `switches` port through the existing top-level/datapath/MMIO boundary.

## Branch Handling

Branches are resolved early in ID. `datapath.v` computes `src_a_D`, `src_b_D`, `equal_D`, `bne_D`, `pc_branch_D`, and `pc_src_D` before the EX stage. The next PC chooses the branch target when `pc_src_D` is asserted. This existing behavior was not weakened.

## Forwarding Paths

The design forwards values in two places:

| Forwarding path | Purpose |
|---|---|
| `forward_a_E`, `forward_b_E` | Select MEM or WB results for ALU operands in EX. |
| `forward_a_D`, `forward_b_D` | Select MEM or WB results for branch operands in ID. |

The forwarding decisions remain in `hazard_unit.v` and the muxes remain in `datapath.v`.

## Hazard Detection / Stall Logic

`hazard_unit.v` detects load-use hazards with `lwstall` and branch operand hazards with `branchstall`. It drives `stall_F`, `stall_D`, and `flush_E`. The Option B program intentionally performs `lw $t0, 0($t1)` followed by `sw $t0, 0($t2)`, so the load-use stall path is exercised while still allowing the MMIO duty update to complete through the CPU.

## MMIO Design

`data_memory.v` implements this map:

| Address | Register | Behavior |
|---|---|---|
| `0x0090` | `switches` | Read-only, returns `{24'b0, switches}`. |
| `0x0098` | `pwm_duty` | Write register, updates from `write_data[7:0]`. |
| `0x009C` | `pwm_enable` | Write register, updates from `write_data[0]`. |

Writes to `0x0090` are ignored. Reads from PWM registers return the current register value, which makes waveform/debug inspection deterministic. Non-MMIO addresses continue to access the normal RAM array.

## PWM Controller Design

`pwm_controller.v` uses Verilog-2001 syntax. It has inputs `clk`, `rst_n`, `en`, `duty[7:0]` and output `pwm_out`. An 8-bit counter increments every clock and naturally wraps from `255` to `0`. The output rule is:

```verilog
pwm_out <= en ? (counter < duty) : 1'b0;
```

Thus `duty = 8'h40` gives about 25% high time, `8'h80` about 50%, `8'hC8` about 78%, and `8'hFF` almost full high time. With the 10 ns testbench clock, the PWM period is `256 * 10 ns = 2.56 us`, or about 390.625 kHz. When `en == 0`, `pwm_out` remains low.

## Software Algorithm

Option B was selected because it directly proves the required CPU-to-MMIO-to-PWM path and requires the least reliable change from the selected source. This option does not need a software delay loop; the visible update rate is set by the polling loop and by the testbench switch-change timing. The program is:

```asm
addi $t3, $zero, 0x009C  # PWM enable address
addi $t0, $zero, 1       # enable value
sw   $t0, 0($t3)         # pwm_enable = 1
addi $t1, $zero, 0x0090  # switches address
addi $t2, $zero, 0x0098  # PWM duty address
loop:
lw   $t0, 0($t1)         # read switches
sw   $t0, 0($t2)         # write duty
j    loop
```

`memfile.dat` contains the corresponding machine code:

| Address | Hex | Assembly |
|---|---|---|
| 0x00 | `200B009C` | `addi $t3, $zero, 0x009C` |
| 0x04 | `20080001` | `addi $t0, $zero, 1` |
| 0x08 | `AD680000` | `sw $t0, 0($t3)` |
| 0x0C | `20090090` | `addi $t1, $zero, 0x0090` |
| 0x10 | `200A0098` | `addi $t2, $zero, 0x0098` |
| 0x14 | `8D280000` | `lw $t0, 0($t1)` |
| 0x18 | `AD480000` | `sw $t0, 0($t2)` |
| 0x1C | `08000005` | `j loop` |

## Reflection

The assignment is intentionally hardware/software co-design: the PWM output is not wired directly to switches. Switch changes only affect `pwm_out` after the MIPS CPU fetches and executes the `lw`, `sw`, and `j` instructions from `memfile.dat`. This keeps the CPU, pipeline, hazard unit, MMIO interface, and PWM hardware all visible in one waveform.

