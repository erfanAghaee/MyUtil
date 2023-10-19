proc log_insts { dir_name iteration_name} {
    set fp [open "$dir_name/analyze/$iteration_name.insts.csv" w+]

    # foreach_in_collection iCell [get_cells *] { 
    #    puts $fp "[get_property $iCell hierarchical_name]" 
    # }
    puts $fp "inst_name,cell_type,location,orientation,\
    inst_box,inst_pins,inst_nets,insts_neigh"

    foreach inst_obj [get_db insts] { 
        set inst_name [get_db $inst_obj .base_name] 
        set cell_name [get_db $inst_obj .base_cell.name] 
        set location [get_db $inst_obj .location] 
        set orient [get_db $inst_obj .orient] 

        set record $inst_name,$cell_name,$location,$orient,

        set inst_box [get_db $inst_obj .bbox] 
        set inst_pins [get_db $inst_obj .pins.name] 
        set inst_nets [get_db $inst_obj .pins.net.name] 
        set xl [get_db $inst_obj .bbox.ll.x] 
        set yl [get_db $inst_obj .bbox.ll.y] 
        set xh [get_db $inst_obj .bbox.ur.x] 
        set yh [get_db $inst_obj .bbox.ur.y] 
        set insts_neigh [get_db [dbQuery -area $xl $yl $xh $yh -objType inst] .name]




        append record $inst_box,
        append record $inst_pins,
        append record $inst_nets,
        append record $insts_neigh
        puts $fp $record
    }

    close $fp
}
#end log_insts


proc log_pins { dir_name iteration_name } {
    set fp [open "$dir_name/analyze/$iteration_name.pins.csv" w+]

    # foreach_in_collection iCell [get_cells *] { 
    #    puts $fp "[get_property $iCell hierarchical_name]" 
    # }
    puts $fp "name,box,layer"

    foreach pin_obj [get_db pins .base_pin] {
        set pin_box [get_db $pin_obj .physical_pins.layer_shapes.shapes.rect] 
        set pin_layer [get_db $pin_obj .physical_pins.layer_shapes.layer] 
        set pin_name [get_db $pin_obj .name] 
        puts $fp "$pin_name,$pin_box,$pin_layer"
    }

    close $fp
}
#end log_pins

proc log_nets { dir_name iteration_name } {
    set fp [open "$dir_name/analyze/$iteration_name.nets.csv" w+]

    # foreach_in_collection iCell [get_cells *] { 
    #    puts $fp "[get_property $iCell hierarchical_name]" 
    # }
    puts $fp "net_name,net_box,net_drivers,net_num_drivers,\
    net_loads,net_num_loads,net_is_power,net_is_gnd,\
    net_wires_box,net_wires_layer,net_pwires_box,net_pwires_layer,\
    net_vias_location,net_vias_bottom_box,net_vias_cut_box,\
    net_vias_top_box,net_vias_type,wl"

    foreach net_obj [get_db nets] { 
        set net_name [get_db $net_obj .base_name] 
        set net_box [get_db $net_obj .bbox] 
        set net_drivers [get_db $net_obj .drivers.name] 
        set net_num_drivers [get_db $net_obj .num_drivers] 
        set net_loads [get_db $net_obj .loads.name] 
        set net_num_loads [get_db $net_obj .num_loads] 
        set net_is_power [get_db $net_obj .is_power] 
        set net_is_gnd [get_db $net_obj .is_ground] 

        set net_wires_box [get_db $net_obj .wires.rect]
        set net_wires_layer [get_db $net_obj .wires.layer]
        set net_pwires_box [get_db $net_obj .patch_wires.rect]
        set net_pwires_layer [get_db $net_obj .patch_wires.layer]

        #vias
        set net_vias_location [get_db $net_obj .vias.location]
        set net_vias_bottom_box [get_db $net_obj .vias.bottom_rects]
        set net_vias_cut_box [get_db $net_obj .vias.cut_rects]
        set net_vias_top_box [get_db $net_obj .vias.top_rects]
        set net_vias_type [get_db $net_obj .vias.via_def]

        set record $net_name,
        append record $net_box, 
        append record $net_drivers,
        append record $net_num_drivers,
        append record $net_loads,
        append record $net_num_loads,
        append record $net_is_power,
        append record $net_is_gnd, 

        append record $net_wires_box,
        append record $net_wires_layer,
        append record $net_pwires_box, 
        append record $net_pwires_layer, 

        #vias
        append record $net_vias_location,
        append record $net_vias_bottom_box,
        append record $net_vias_cut_box,
        append record $net_vias_top_box,
        append record $net_vias_type,

        set wl 0
        foreach wire_len [get_db $net_obj .wires.length] {        
            set wl [expr $wl+$wire_len]
        }
        #   puts $wl
        append record $wl

        puts $fp $record
    }

    close $fp
}
#end log_nets


proc log_design { dir_name iteration_name } {
    set fp [open "$dir_name/analyze/$iteration_name.design.csv" w+]

    # foreach_in_collection iCell [get_cells *] { 
    #    puts $fp "[get_property $iCell hierarchical_name]" 
    # }
    puts $fp "name,die_xl,die_yl,die_xh,die_yh"

    set name [get_db current_design  .name]
    set die_xl [get_db current_design  .bbox.ll.x]
    set die_yl [get_db current_design  .bbox.ll.y]
    set die_xh [get_db current_design  .bbox.ur.x]
    set die_yh [get_db current_design  .bbox.ur.y]

    set record $name,
    append record $die_xl,
    append record $die_yl,
    append record $die_xh,
    append record $die_yh

    puts $fp $record
    

    close $fp
}
#end log_nets


proc log_rows { dir_name iteration_name } {
    set fp [open "$dir_name/analyze/$iteration_name.rows.csv" w+]

    # foreach_in_collection iCell [get_cells *] { 
    #    puts $fp "[get_property $iCell hierarchical_name]" 
    # }
    puts $fp "name,box,orient"

    foreach row_obj [get_db rows] {
        set name [get_db $row_obj  .name]
        set box [get_db $row_obj  .rect]
        set orient [get_db $row_obj  .orient]
        set record $name,
        append record $box,
        append record $orient
        
        puts $fp $record
    }

    close $fp
}
#end log_nets


proc log_layers { dir_name iteration_name } {
    set fp [open "$dir_name/analyze/$iteration_name.layers.csv" w+]

    # foreach_in_collection iCell [get_cells *] { 
    #    puts $fp "[get_property $iCell hierarchical_name]" 
    # }
    puts $fp "layer_name,layer_direction,layer_offset_x,\
    layer_offset_y,layer_pitch_x,layer_pitch_y,\
    layer_route_index,layer_cut_index,layer_type"

    foreach layer_obj [get_db layers] {
        set layer_name [get_db $layer_obj  .name]
        set layer_direction [get_db $layer_obj  .direction]
        set layer_offset_x [get_db $layer_obj  .offset_x]
        set layer_offset_y [get_db $layer_obj  .offset_y]
        set layer_pitch_x [get_db $layer_obj  .pitch_x]
        set layer_pitch_y [get_db $layer_obj  .pitch_y]
        set layer_route_index [get_db $layer_obj  .route_index]
        set layer_cut_index [get_db $layer_obj  .cut_index]
        set layer_type [get_db $layer_obj  .type]
        

        set record $layer_name,
        append record $layer_direction,
        append record $layer_offset_x,
        append record $layer_offset_y,
        append record $layer_pitch_x,
        append record $layer_pitch_y,
        append record $layer_route_index,
        append record $layer_cut_index,
        append record $layer_type

        
        puts $fp $record

    }

    set fp_sp [open "$dir_name/analyze/$iteration_name.sp_table.txt" w+]
    set layer_sp_table [get_db layers  .spacing_tables]
    puts $fp_sp $layer_sp_table




    

    close $fp
    close $fp_sp
}
#end log_layers


proc log_tracks { dir_name iteration_name } {
    set fp [open "$dir_name/analyze/$iteration_name.tracks.csv" w+]

    # foreach_in_collection iCell [get_cells *] { 
    #    puts $fp "[get_property $iCell hierarchical_name]" 
    # }
    puts $fp "direction,layers,num_tracks,start,step"

    set track_direction [get_db current_design .track_patterns.direction]
    set track_layers [get_db current_design .track_patterns.layers]
    set track_num_tracks [get_db current_design .track_patterns.num_tracks]
    set track_start [get_db current_design .track_patterns.start]
    set track_step [get_db current_design .track_patterns.step]
    
    

    set record $track_direction,
    append record $track_layers,
    append record $track_num_tracks,
    append record $track_start,
    append record $track_step
    
    puts $fp $record
    
    close $fp
}
#end log_tracks


proc log_base_cells {dir_name iteration_name} {
   set fp [open "$dir_name/analyze/$iteration_name.base_cell.csv" w+]

    # foreach_in_collection iCell [get_cells *] { 
    #    puts $fp "[get_property $iCell hierarchical_name]" 
    # }
    puts $fp "inst_name,base_cell,box"

    foreach inst_obj [get_db insts] { 
        set inst_name [get_db $inst_obj .name]
        set box [get_db $inst_obj .base_cell.bbox]
        set base_cell [get_db $inst_obj .base_cell.name]
        puts $fp "$inst_name,$base_cell,$box"
    }
    close $fp
}
#end log_base_cells