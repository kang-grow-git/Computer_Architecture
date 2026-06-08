# MIPS PWM Motor Controller

A 5-stage pipelined MIPS CPU controls an 8-bit PWM motor output through memory-mapped I/O.

## System Block Diagram

```text
+----------------+     lw/sw MMIO      +-------------------+     registers      +----------------+
| memfile.dat    | -> | MIPS pipeline  | -> | data_memory.v | -> | pwm_duty/en   | -> | pwm_controller |
| Option B code  |    | IF ID EX MEM WB|    | RAM + MMIO    |    |               |    | pwm_out        |
+----------------+    +----------------+    +-------------------+                 +----------------+
                                                ^
                                                |
                                           switches[7:0]
```

## MMIO Address Map

| Address | Name | Direction | Behavior |
|---|---|---|---|
| 0x0000+ | Normal RAM | Read/write | Existing word-addressed RAM behavior is preserved for non-MMIO addresses. |
| 0x0090 | Switches | Read-only | `lw` returns `{24'b0, switches}`. Writes are ignored. |
| 0x0098 | PWM duty | Write register | `sw` updates `pwm_duty[7:0]`. Reads return the current duty value for debug consistency. |
| 0x009C | PWM enable | Write register | `sw` updates `pwm_enable`. Reads return the current enable value for debug consistency. |

## Selected Motor Profile

Option B was selected: the CPU enables PWM once, then repeatedly reads `switches` from address `0x0090` and writes that value to PWM duty address `0x0098`.

## Build And Run

From a fresh clone or copied repository:

```powershell
cd C:\iverilog\verilog-main\verilog-main\pbl_assign
make clean
make
```

`make` compiles with Icarus Verilog and runs the simulation with `vvp`. The simulation writes `mips.vcd`.

## GTKWave

```powershell
make wave
```

Inspect these signals:

| Signal | Expected behavior |
|---|---|
| `switches[7:0]` | Testbench drives `00`, `40`, `80`, `C8`, `FF`, rapid changes, reset, then `00`/`FF`. |
| `pwm_duty[7:0]` | Follows the most recent switch value after the CPU polling loop executes `lw` then `sw`. |
| `pwm_enable` | Becomes `1` after software writes `1` to `0x009C`; returns to `0` during reset and re-enables after restart. |
| `pwm_out` | Pulse width increases as duty increases. It stays low when enable is `0` or duty is `0`. |
| `pc_out`, `alu_result`, `mem_write`, `mem_addr`, `write_data`, `read_data` | Show instruction execution and MMIO transactions. |

## File Layout

```text
pbl_assign/
  alu.v
  alu_decoder.v
  control_unit.v
  data_memory.v
  datapath.v
  hazard_unit.v
  instruction_memory.v
  main_decoder.v
  Makefile
  memfile.dat
  mips.v
  mips_tb.v
  pc.v
  pwm_controller.v
  reg_file.v
  docs/
    design_report.md
    test_report.md
```
