source util.tcl

# will all functions go to util.tcl
proc get_tile_size {} {
    set row_width [lindex [get_db [get_db rows] .rect.width] 0]
    set tile_size [expr $row_width * 5]
    return $tile_size
}
# get inst features 
proc get_inst_features { inst_obj } {
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

    # marker
    set markers [get_db [dbQuery -area $xl $yl $xh $yh -objType marker] .bbox]
    set markers_type [get_db [dbQuery -area $xl $yl $xh $yh -objType marker] .type]
    set markers_subtype [get_db [dbQuery -area $xl $yl $xh $yh -objType marker] .subtype]



    append record $inst_box,
    append record $inst_pins,
    append record $inst_nets,
    append record $insts_neigh,
    append record $markers,
    append record $markers_type,
    append record $markers_subtype
    return $record
}

# get tiles features (position features)
proc get_features { tile_xl tile_yl tile_xh tile_yh} {
    # puts "$tile_xl $tile_yl $tile_xh $tile_yh"
    #1- Region Density (Region Cell Area / Design Area)
    set design_area [get_db current_design .bbox.area]

    set record $tile_xl,$tile_yl,$tile_xh,$tile_yh,
    
    set insts [get_db [dbQuery -area $tile_xl $tile_yl $tile_xh $tile_yh -objType inst] .name]
    set pins [get_db [dbQuery -area $tile_xl $tile_yl $tile_xh $tile_yh -objType instTerm] .name]    
    set nets [get_db [dbQuery -area $tile_xl $tile_yl $tile_xh $tile_yh -objType net] .name]
    set rows [get_db [dbQuery -area $tile_xl $tile_yl $tile_xh $tile_yh -objType row] .name]
    set wires_box [get_db [dbQuery -area $tile_xl $tile_yl $tile_xh $tile_yh -objType wire] .rect]
    set wires_layer [get_db [dbQuery -area $tile_xl $tile_yl $tile_xh $tile_yh -objType wire] .layer]
    set pwires_box [get_db [dbQuery -area $tile_xl $tile_yl $tile_xh $tile_yh -objType pwire] .rect]
    set pwires_layer [get_db [dbQuery -area $tile_xl $tile_yl $tile_xh $tile_yh -objType pwire] .layer]
    #vias
    set vias_location [get_db [dbQuery -area $tile_xl $tile_yl $tile_xh $tile_yh -objType via] .location]
    set vias_bottom_box [get_db [dbQuery -area $tile_xl $tile_yl $tile_xh $tile_yh -objType via] .bottom_rects]
    set vias_cut_box [get_db [dbQuery -area $tile_xl $tile_yl $tile_xh $tile_yh -objType via] .cut_rects]
    set vias_top_box [get_db [dbQuery -area $tile_xl $tile_yl $tile_xh $tile_yh -objType via] .top_rects]
    set vias_type [get_db [dbQuery -area $tile_xl $tile_yl $tile_xh $tile_yh -objType via] .via_def]

    # marker
    set markers [get_db [dbQuery -area $tile_xl $tile_yl $tile_xh $tile_yh -objType marker] .bbox]
    set markers_type [get_db [dbQuery -area $tile_xl $tile_yl $tile_xh $tile_yh -objType marker] .type]
    set markers_subtype [get_db [dbQuery -area $tile_xl $tile_yl $tile_xh $tile_yh -objType marker] .subtype]

    set wl 0
    foreach wire_len [get_db [dbQuery -area $tile_xl $tile_yl $tile_xh $tile_yh -objType wire] .length] {        
        set wl [expr $wl+$wire_len]
    }

    # append to record
    append record $insts, 
    append record $pins, 
    append record $nets, 
    append record $rows, 
    append record $wires_box, 
    append record $wires_layer, 
    append record $pwires_box, 
    append record $pwires_layer,
    #vias
    append record $vias_location,
    append record $vias_bottom_box,
    append record $vias_cut_box,
    append record $vias_top_box, 
    append record $vias_type,

    # marker
    append record $markers,
    append record $markers_type,
    append record $markers_subtype,
    append record $wl
    return $record
}

proc run_analyze { dir_name iteration_name } {
    # 0- init header 
    # mkdir "$dir_name/analyze/"
    set file_name "$dir_name/analyze/$iteration_name.tiles.csv"
    
    set fp [open $file_name w+]
    set header "tile_xl,tile_yl,tile_xh,tile_yh,\
    insts,pins,nets,rows,wires_box,wires_layer,\
    pwires_box,pwires_layer,vias_location,vias_bottom_box,\
    vias_cut_box,vias_top_box,vias_type,markers,\
    markers_type,markers_subtype,wl,\
    tile_xl_bd,tile_yl_bd,tile_xh_bd,tile_yh_bd,\
    insts_bd,pins_bd,nets_bd,rows_bd,wires_box_bd,wires_layer_bd,\
    pwires_box_bd,pwires_layer_bd,vias_location_bd,vias_bottom_box_bd,\
    vias_cut_box_bd,vias_top_box_bd,vias_type_bd,markers_bd,\
    markers_type_bd,markers_subtype_bd,wl_bd"
    puts $fp $header
    
    # To get independent results from each tile 
    # I define epsilon == 0.1 to get only objects inside tile
    set epsilon 0.1
    # 1- tile size
    set tile_size [get_tile_size]
    # puts $tile_size
    # 2- die boundary
    set die_bd_x [get_db current_design .bbox.length]
    set die_bd_y [get_db current_design .bbox.width]
    # 3- generate tile grid 
    

    set i 0
    while { $i < $die_bd_x} {
        set j 0
        while { $j < $die_bd_y} {
            # puts "$i,$j"
            # 4- tile box
            # set tile_box "$i,$j,[expr $i + $tile_size -$epsilon],[expr $j + $tile_size - $epsilon]"
            set record [get_features $i $j [expr $i + $tile_size - $epsilon] [expr $j + $tile_size - $epsilon]]
            set record_bd [get_features $i $j [expr $i + $tile_size + $epsilon] [expr $j + $tile_size + $epsilon]]
            puts $fp "$record,$record_bd"
            set j [expr $j + $tile_size]
        } 
        #end j while loop
        

        set i [expr $i + $tile_size]
    }
    #end i while loop
    close $fp    
}
#end run_analyzer function


proc run_analyze_cell_tile_center { dir_name iteration_name } {
    # 0- init header 
    # mkdir "$dir_name/analyze/"
    set file_name "$dir_name/analyze/$iteration_name.tiles.csv"
    
    set fp [open $file_name w+]
    set header "inst_name,cell_type,location,orientation,\
    inst_box,inst_pins,inst_nets,insts_neigh,\
    markers,markers_type,markers_subtype,\
    tile_xl,tile_yl,tile_xh,tile_yh,\
    insts,pins,nets,rows,wires_box,wires_layer,\
    pwires_box,pwires_layer,vias_location,vias_bottom_box,\
    vias_cut_box,vias_top_box,vias_type,markers,\
    markers_type,markers_subtype,wl,\
    tile_xl_bd,tile_yl_bd,tile_xh_bd,tile_yh_bd,\
    insts_bd,pins_bd,nets_bd,rows_bd,wires_box_bd,wires_layer_bd,\
    pwires_box_bd,pwires_layer_bd,vias_location_bd,vias_bottom_box_bd,\
    vias_cut_box_bd,vias_top_box_bd,vias_type_bd,markers_bd,\
    markers_type_bd,markers_subtype_bd,wl_bd"
    puts $fp $header
    
    # To get independent results from each tile 
    # I define epsilon == 0.1 to get only objects inside tile
    set epsilon 0.1
    # 1- tile size
    set tile_size [get_tile_size]
    # puts $tile_size
    # 2- die boundary
    set die_bd_x [get_db current_design .bbox.length]
    set die_bd_y [get_db current_design .bbox.width]
    # 3- generate tile grid 
    
    foreach inst_obj [get_db insts] { 
        set xl [get_db $inst_obj .bbox.ll.x] 
        set yl [get_db $inst_obj .bbox.ll.y] 
        set xh [get_db $inst_obj .bbox.ur.x] 
        set yh [get_db $inst_obj .bbox.ur.y] 
        set x_center [expr ($xl + $xh)/2.0]
        set y_center [expr ($yl + $yh)/2.0]

        set tile_xl [expr $x_center - $tile_size + $epsilon]
        set tile_yl [expr $y_center - $tile_size + $epsilon]
        set tile_xh [expr $x_center + $tile_size - $epsilon]
        set tile_yh [expr $y_center + $tile_size - $epsilon]
        set tile_xl_bd [expr $x_center - $tile_size - $epsilon]
        set tile_yl_bd [expr $y_center - $tile_size - $epsilon]
        set tile_xh_bd [expr $x_center + $tile_size + $epsilon]
        set tile_yh_bd [expr $y_center + $tile_size + $epsilon]


        set inst_record [get_inst_features $inst_obj]
        set record [get_features $tile_xl $tile_yl $tile_xh $tile_yh]
        set record_bd [get_features $tile_xl_bd $tile_yl_bd $tile_xh_bd $tile_yh_bd]
        puts $fp "$inst_record,$record,$record_bd"
    }



    # set i 0
    # while { $i < $die_bd_x} {
    #     set j 0
    #     while { $j < $die_bd_y} {
    #         # puts "$i,$j"
    #         # 4- tile box
    #         # set tile_box "$i,$j,[expr $i + $tile_size -$epsilon],[expr $j + $tile_size - $epsilon]"
    #         set record [get_features $i $j [expr $i + $tile_size - $epsilon] [expr $j + $tile_size - $epsilon]]
    #         set record_bd [get_features $i $j [expr $i + $tile_size + $epsilon] [expr $j + $tile_size + $epsilon]]
    #         puts $fp "$record,$record_bd"
    #         set j [expr $j + $tile_size]
    #     } 
    #     #end j while loop
        

    #     set i [expr $i + $tile_size]
    # }
    #end i while loop
    close $fp    
}
#end run_analyzer_cell_tile_center function