if {[file exists work]} {
    vdel -lib work -all
}
vlib work
vmap work work

vlog defines.v 
vlog ALU.v RegisterFile.v InstructionMemory.v DataMemory.v ControlUnit.v
vlog ForwardingUnit.v IF_ID_Reg.v ID_EX_Reg.v EX_MEM_Reg.v MEM_WB_Reg.v
vlog PC_Unit.v CCR_Unit.v HazardUnit.v 
vlog Processor_Top.v Processor_TB.v

# Load Simulation
vsim -voptargs="+acc" Processor_TB

# Add Waves
add wave -noupdate -divider "System"
add wave -noupdate /Processor_TB/clk
add wave -noupdate /Processor_TB/rst
add wave -noupdate /Processor_TB/reset_signal
add wave -noupdate /Processor_TB/intr_signal
add wave -noupdate -radix hex -label "PC" /Processor_TB/uut/pc
# This line should work now:
add wave -noupdate -ascii -label "Opcode" /Processor_TB/id_op_name

add wave -noupdate -divider "Registers"
add wave -noupdate -radix hex -label "R0 (Acc)" {/Processor_TB/uut/rf/registers[0]}
add wave -noupdate -radix hex -label "R1 (In)"  {/Processor_TB/uut/rf/registers[1]}
add wave -noupdate -radix hex -label "R2 (ISR)" {/Processor_TB/uut/rf/registers[2]}
add wave -noupdate -radix hex -label "R3 (SP)"  {/Processor_TB/uut/rf/registers[3]}

add wave -noupdate -divider "Control"
add wave -noupdate -radix binary -label "Flags (VCNZ)" /Processor_TB/uut/current_flags
add wave -noupdate -label "Branch Taken" /Processor_TB/uut/branch_taken
add wave -noupdate -radix hex -label "In Port" /Processor_TB/in_port
add wave -noupdate -radix hex -label "Out Port" /Processor_TB/out_port

run -all