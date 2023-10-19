# pass the list of insts that you want to apply leglizer
refinePlace -inst {inst1 inst2}

# global and detailed routing 
catch {routeDesign > "routing_log.txt"}
verify_drc -limit -1 -report "drc.rpt" 
set $name def_name.def
defOut -floorplan -netlist -routing $name > log.txt