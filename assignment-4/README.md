# Class 10: Jump Instructions

> **Week 10 | Hanyang University ERICA Campus | Department of Robotics**  
> **Computer Architecture Course**

---

## 📚 Learning Objectives

After completing this class, you will be able to:

1. **Understand J-Type instruction format**: Encoding for direct jumps
2. **Implement `j` (Jump) instruction**: Unconditional jump to specified address
3. **Implement `jal` (Jump and Link) instruction**: Foundation for function calls
4. **Implement `jr` (Jump Register) instruction**: Return from functions
5. **Understand the complete function call and return flow**

---

## 🧠 Key Concepts

### MIPS Jump Instruction Family

| Instruction | Format | Function | Usage |
|-------------|--------|----------|-------|
| `j target` | J-Type | PC = {PC[31:28], target, 00} | Unconditional jump |
| `jal target` | J-Type | $ra = PC+4; PC = {PC[31:28], target, 00} | Function call |
| `jr $rs` | R-Type | PC = $rs | Function return |

### J-Type Instruction Format

```
  31    26 25                                    0
 ┌────────┬────────────────────────────────────────┐
 │ opcode │            target (26-bit)            │
 └────────┴────────────────────────────────────────┘
     6                     26
```

### Jump Address Calculation

```
  ┌──────────────┬───────────────────────────────────┬────┐
  │ PC+4[31:28]  │          target (26-bit)          │ 00 │
  └──────────────┴───────────────────────────────────┴────┘
       4-bit                   26-bit                 2-bit = 32-bit
```

**Why only 26-bit target address?**
- Lowest 2 bits are always 00 (4-byte aligned)
- Highest 4 bits come from PC+4 (usually jumping within same 256MB region)

---

## 📊 Function Call and Return

### Call Flow (`jal`)

```assembly
main:
    jal  func       # 1. Save PC+4 to $ra
                    # 2. Jump to func
    add  $t0, ...   # Continue execution after jal returns
    ...

func:
    ...             # Function body
    jr   $ra        # Return to address in $ra
```

**Dataflow**:
```
       jal             jr
  ┌───────────┐   ┌───────────┐
  │  PC + 4   │ → │   $ra     │ → new PC
  └───────────┘   └───────────┘
```

### Implementation in Pipeline

```verilog
// PC multiplexer
assign pc_next_F = (jr_D)      ? rd1_D :              // jr: jump from register
                   (jump_D)    ? jump_addr_D :        // j, jal
                   (pc_src_D)  ? pc_branch_D :        // beq, bne
                   pc_plus4_F;                        // Sequential execution

// Jump address calculation
assign jump_addr_D = {pc_plus4_D[31:28], instr_D[25:0], 2'b00};
```

---

## 💻 Code Walkthrough

### Main Decoder Extension

```verilog
module main_decoder (
    input  wire [5:0] opcode,
    // ... other outputs ...
    output reg        jump,      // j or jal
    output reg        link       // jal needs to save $ra
);
    always @(*) begin
        case (opcode)
            6'b000010: begin // j
                jump = 1; link = 0;
                reg_write = 0;
            end
            6'b000011: begin // jal
                jump = 1; link = 1;
                reg_write = 1;  // Need to write $ra
                reg_dst = 0;    // But destination is $ra, needs special handling
            end
            // ... other instructions ...
        endcase
    end
endmodule
```

### `jal` Instruction Write Back Handling

```verilog
// Destination register selection
// jal needs to write to $ra ($31)
assign write_reg_D = (link_D) ? 5'd31 : 
                     (reg_dst_D) ? instr_D[15:11] : instr_D[20:16];

// Write back data selection
// jal needs to save PC+4
assign write_data = (link_W) ? pc_plus4_W : 
                    (mem_to_reg_W) ? read_data_W : alu_result_W;
```

### `jr` Instruction Detection

```verilog
// jr is R-Type instruction, opcode = 0, funct = 001000
wire jr_D;
assign jr_D = (instr_D[31:26] == 6'b000000) && 
              (instr_D[5:0]   == 6'b001000);
```

---

## 🎯 Design Highlights

### Jump Pipeline Flush

Like branches, jumps need to flush incorrectly fetched instructions:

```verilog
// IF/ID flush logic
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        instr_D_reg <= 0;
    end else if (jump_D || jr_D || pc_src_D) begin
        // Jump or branch taken, flush next instruction
        instr_D_reg <= 32'b0;  // NOP
    end else if (!stall_D) begin
        instr_D_reg <= instr_F;
    end
end
```

### `jr` Data Hazard

```assembly
add  $t0, $t1, $t2   # Write to $t0
jr   $t0             # Immediately use $t0
```

Need to provide forwarding for `jr`, or stall and wait:

```verilog
// jr stall detection
wire jr_stall;
assign jr_stall = jr_D && (
    (reg_write_E && write_reg_E == instr_D[25:21]) ||
    (mem_to_reg_M && write_reg_M == instr_D[25:21])
);
```

---

## 📁 File Structure

```
class_10/
├── main_decoder.v          # Supports j, jal
├── hazard_unit.v           # Supports jr stall
├── datapath.v              # Complete jump logic ⭐
├── mips.v                  # CPU top level
└── memfile.dat             # Test program
```

---

## 🧪 Lab Exercise

### Step 1: Test `j` instruction
```
20080001   // 0x00: addi $t0, $zero, 1
08000004   // 0x04: j 0x10 (jump to 4th instruction)
20090002   // 0x08: addi $t1, $zero, 2 (skipped)
200A0003   // 0x0C: addi $t2, $zero, 3 (skipped)
200B0004   // 0x10: addi $t3, $zero, 4 (jump target)
```

### Step 2: Test `jal` and `jr`
```
20080005   // 0x00: addi $t0, $zero, 5
0C000004   // 0x04: jal 0x10 (call function)
200A0099   // 0x08: addi $t2, $zero, 0x99 (execute after return)
08000006   // 0x0C: j 0x18 (end)
01005020   // 0x10: add $t2, $t0, $zero (function body)
03E00008   // 0x14: jr $ra (return)
00000000   // 0x18: nop
```

### Step 3: Run simulation
```bash
cd class_10
make
```

### Step 4: Observe waveform
- Verify PC jumps to correct address after `j`
- Verify `$ra` is correctly written during `jal`
- Verify PC is set to `$ra` value during `jr`

---

## 🔍 Think Deeper

### Question 1: Recursive Calls

In recursive functions, `jal` repeatedly overwrites `$ra`. How to save return addresses?

> **Hint**: Stack! `addi $sp, $sp, -4; sw $ra, 0($sp)`

### Question 2: Jump Range Limitation

`j` instruction can only jump to addresses with same upper 4 bits as PC (within 256MB region). How to jump further?

### Question 3: Procedure Calling Convention

MIPS calling convention specifies `$a0-$a3` for arguments, `$v0-$v1` for return values. Why have these conventions?

---

## ✅ Checkpoint

Before moving to the next class, make sure you can answer:

- [ ] Which register does `jal` instruction write to?
- [ ] Where does the new PC value for `jr $ra` come from?
- [ ] Why is only 26 bits needed for jump address?

---

**Previous**: [Class 09 - Stall & Flush](../class_09/README.md)  
**Next**: [Class 11 - MMIO & PWM](../class_11/README.md)
