iverilog -o tb_mod_2_n.vvp ./*.v 

vvp -n tb_mod_2_n.vvp

gtkwave tb_mod_2_n.vcd

pause

