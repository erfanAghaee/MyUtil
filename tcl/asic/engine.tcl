source util.tcl
source get_db.tcl
source analyze.tcl

proc run_placer { input_bench input_setting} {
    set lef_adr "./../../benchmarks/$input_bench/$input_bench.input.lef"
    set def_adr "./../../benchmarks/$input_bench/$input_bench.input.def"
    puts "$input_bench, max_density: $input_setting"
    puts "start load benchmarks..."
    loadLefFile $lef_adr > log.txt
    loadDefFile $def_adr > log.txt
    puts "Done load benchmarks!"
    placeDesign > log.txt
    set name "./placement_cad/$input_bench.input.cadence.def"
    defOut -floorplan -netlist -routing $name
    # if {$input_setting != "0"} {
    #     setPlaceMode -place_global_max_density $input_setting
    #     placeDesign > log.txt
    #     set name "./placements/$input_bench.$input_setting.def"
    #     defOut -floorplan -netlist -routing $name
    # } else {
    #     set name "./placement_cad/$input_bench.$input_setting.def"
    #     defOut -floorplan -netlist -routing $name
    # }  
}
#end run_placer


proc run_router { input_bench input_placement_setting input_routing_setting} {
    set lef_adr "./../../benchmarks/$input_bench/$input_bench.input.lef"
    set def_adr "./placements/$input_bench.$input_placement_setting.def"
    puts "$input_bench, placement: $input_placement_setting, routing: $input_routing_setting"
    puts "start load benchmarks..."
    loadLefFile $lef_adr > log.txt
    loadDefFile $def_adr > log.txt
    puts "Done load benchmarks!"


    setNanoRouteMode -drouteStartIteration $input_routing_setting
    setNanoRouteMode -drouteEndIteration $input_routing_setting
    catch {routeDesign > log.txt}

    set name "./routings/$input_bench.$input_placement_setting.$input_routing_setting.def"
    defOut -floorplan -netlist -routing $name

}

proc run_router_intermediate_steps {dir_name bench_name placement_setting} {
    set fp [open "$dir_name/routing_itr.csv" w+]
    set header "name,iteration,markers_box,markers_type,marker_subtype"
    puts $fp $header

    set lef_adr "./../../benchmarks/$bench_name/$bench_name.input.lef"
    set def_adr "./placements/$bench_name.$placement_setting.def"
    puts "bench_name: $bench_name"
    puts "lef: $lef_adr"
    puts "def: $def_adr"
    puts "start load benchmarks..."
    loadLefFile $lef_adr > log.txt
    loadDefFile $def_adr > log.txt
    puts "Done load benchmarks!"
    set itr 0
    set violation_free 0
    set xl [get_db current_design .bbox.ll.x]
    set yl [get_db current_design .bbox.ll.y]
    set xh [get_db current_design .bbox.ur.x]
    set yh [get_db current_design .bbox.ur.y]
    while {$violation_free == 0} { 
        setNanoRouteMode -drouteStartIteration $itr
        setNanoRouteMode -drouteEndIteration $itr
        set iteration_name "$bench_name.$placement_setting.$itr"
        catch {routeDesign > "$dir_name/logs/log_$iteration_name.txt"}
        verify_drc -limit -1 -report "$dir_name/drc_rpt/$iteration_name.rpt" 
        run_analyze $dir_name $iteration_name
        log_insts $dir_name $iteration_name
        log_pins $dir_name $iteration_name
        log_nets $dir_name $iteration_name
        log_design $dir_name $iteration_name
        log_rows $dir_name $iteration_name
        log_layers $dir_name $iteration_name
        log_tracks $dir_name $iteration_name
        log_base_cells $dir_name $iteration_name

        
        # marker
        set markers [get_db [dbQuery -area $xl $yl $xh $yh -objType marker] .bbox]
        set markers_type [get_db [dbQuery -area $xl $yl $xh $yh -objType marker] .type]
        set markers_subtype [get_db [dbQuery -area $xl $yl $xh $yh -objType marker] .subtype]
        set name "$dir_name/def/$iteration_name.def"
        defOut -floorplan -netlist -routing $name > log.txt

        puts $fp $bench_name.$placement_setting,$itr,$markers,$markers_type,$markers_subtype

        if {$markers == ""} {
            set violation_free 1
            puts "Violation free iteration: $itr"
        } else {
            puts "Violation not free iteration: $itr"
        }

        set itr [expr $itr + 1]
    }

    close $fp
 

    
}

proc run_router_intermediate_steps_cell_center_tile {dir_name bench_name placement_setting} {
    set fp [open "$dir_name/routing_itr.csv" w+]
    set header "name,iteration,markers_box,markers_type,marker_subtype"
    puts $fp $header

    set lef_adr "./../../benchmarks/$bench_name/$bench_name.input.lef"
    set def_adr "./placements/$bench_name.$placement_setting.def"
    puts "bench_name: $bench_name"
    puts "lef: $lef_adr"
    puts "def: $def_adr"
    puts "start load benchmarks..."
    loadLefFile $lef_adr > log.txt
    loadDefFile $def_adr > log.txt
    puts "Done load benchmarks!"
    set itr 0
    set violation_free 0
    set xl [get_db current_design .bbox.ll.x]
    set yl [get_db current_design .bbox.ll.y]
    set xh [get_db current_design .bbox.ur.x]
    set yh [get_db current_design .bbox.ur.y]
    while {$violation_free == 0} { 
        setNanoRouteMode -drouteStartIteration $itr
        setNanoRouteMode -drouteEndIteration $itr
        set iteration_name "$bench_name.$placement_setting.$itr"
        catch {routeDesign > "$dir_name/logs/log_$iteration_name.txt"}
        verify_drc -limit -1 -report "$dir_name/drc_rpt/$iteration_name.rpt" 
        run_analyze_cell_tile_center $dir_name $iteration_name
        log_insts $dir_name $iteration_name
        log_pins $dir_name $iteration_name
        log_nets $dir_name $iteration_name
        log_design $dir_name $iteration_name
        log_rows $dir_name $iteration_name
        log_layers $dir_name $iteration_name
        log_tracks $dir_name $iteration_name
        log_base_cells $dir_name $iteration_name

        
        # marker
        set markers [get_db [dbQuery -area $xl $yl $xh $yh -objType marker] .bbox]
        set markers_type [get_db [dbQuery -area $xl $yl $xh $yh -objType marker] .type]
        set markers_subtype [get_db [dbQuery -area $xl $yl $xh $yh -objType marker] .subtype]
        set name "$dir_name/def/$iteration_name.def"
        defOut -floorplan -netlist -routing $name > log.txt

        puts $fp $bench_name.$placement_setting,$itr,$markers,$markers_type,$markers_subtype

        if {$markers == ""} {
            set violation_free 1
            puts "Violation free iteration: $itr"
        } else {
            puts "Violation not free iteration: $itr"
        }

        set itr [expr $itr + 1]
    }

    close $fp
 

    
}

