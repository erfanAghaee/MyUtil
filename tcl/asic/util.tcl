
proc get_inst_name {inst_obj} {
    set inst_name [get_db $inst_obj .base_name] 
    return $inst_name
}

proc get_cell_name {inst_obj} {
    set cell_name [get_db $inst_obj .base_cell.name] 
    return $cell_name
}

proc get_inst_location {inst_obj} {
    set location [get_db $inst_obj .location] 
    return $location
}

proc get_inst_xl {inst_obj} {
    set x [get_db $inst_obj .location.x]
    return $x
}

proc get_inst_yl {inst_obj} {
    set y [get_db $inst_obj .location.y]
    return $y
}

proc get_inst_xh {inst_obj} {
    set xh [get_db $inst_obj .bbox.ur.x]
    return $xh
}

proc get_inst_yh {inst_obj} {
    set yh [get_db $inst_obj .bbox.ur.y]
    return $yh
}

proc get_inst_width {inst_obj} {
    set width [get_db $inst_obj .bbox.width]
    return $width
}

proc get_inst_heigth {inst_obj} {
    set len [get_db $inst_obj .bbox.length]
    return $len
}

proc get_inst_orient {inst_obj} {
    set cur_orient [get_db $inst_obj .orient]
    return $cur_orient
}

proc get_wl {box_xl box_yl box_xh box_yh} {
    set nets_wl [get_db [dbQuery -objType net -area $box_xl $box_yl $box_xh $box_yh] .wires.length]
    # report_route
    set wl 0
    foreach wire_len $nets_wl {
        set wl [expr $wl+$wire_len]
    }
    return $wl
}

proc get_num_vias {box_xl box_yl box_xh box_yh} {
    set vias [get_db [dbQuery -objType net -area $box_xl $box_yl $box_xh $box_yh] .vias]
    set num_vias [llength $vias]
    return $num_vias
}

proc get_inst_neighrs {box_xl box_yl box_xh box_yh} {
    set inst_neighrs [get_db [dbQuery -objType inst -area $box_xl $box_yl $box_xh $box_yh] .base_cell.name]
    set inst_neighrs "{$inst_neighrs}"
    return $inst_neighrs
}

proc record_const_features {inst_obj} {
    set inst_name [get_inst_name $inst_obj]
    set record_const $inst_name,

    set cell_name [get_cell_name $inst_obj]
    append record_const $cell_name,

    set inst_loc [get_inst_location $inst_obj]
    append record_const $inst_loc,

    set xl [get_inst_xl $inst_obj]
    set yl [get_inst_yl $inst_obj]
    set xh [get_inst_xh $inst_obj]
    set yh [get_inst_yh $inst_obj]

    append record_const $xl,$yl,
    append record_const $xh,$yh,

    set inst_width [get_inst_width $inst_obj]
    set inst_heigth [get_inst_heigth $inst_obj]

    append record_const $inst_width,$inst_heigth,

    set inst_orient [get_inst_orient $inst_obj]

    append record_const $inst_orient,

    set insts_neigh [get_inst_neighrs $xl $yl $xh $yh]

    append record_const $insts_neigh,
    # append record_const $total_wl_init,$total_vias_init,
    set wl_old [get_wl $xl $yl $xh $yh]
    set num_vias_old [get_num_vias $xl $yl $xh $yh]
    append record_const $wl_old,$num_vias_old

    return $record_const

}


proc record_dynamic_features {inst_obj} {
    # inst and macro and placement density 
    set xl [get_inst_xl $inst_obj]
    set yl [get_inst_yl $inst_obj]
    set xh [get_inst_xh $inst_obj]
    set yh [get_inst_yh $inst_obj]

    set inst_orient [get_inst_orient $inst_obj]

    set record_dynamic $inst_orient,

    set wl [get_wl $xl $yl $xh $yh]
    set num_vias [get_num_vias $xl $yl $xh $yh]

    append record_dynamic $wl,$num_vias,
    
    set density [queryDensityInBox $xl $yl $xh $yh > log.txt]
    set fp [open "log.txt" ]
    set file_data [read $fp]
    close $fp      
    set density_stdinst_to_freespace [get_density_stdinst_to_freespace $file_data]
    set density_macroinst_to_freespace [get_density_macroinst_to_freespace $file_data]
    set density_placementobs_to_freespace [get_density_placementobs_to_freespace $file_data]

    append record_dynamic $density_stdinst_to_freespace,\
    $density_macroinst_to_freespace,$density_placementobs_to_freespace,

    # pin_density 
    set pin_density [queryPinDensity -area $xl $yl $xh $yh > log.txt]
    set fp [open "log.txt" ]
    set file_data [read $fp]
    close $fp  
    set density_pin [get_density_pin $file_data]

    append record_dynamic $density_pin,

    # globalDetailRoute $xl $yl $xh $yh > log.txt
    # set fp [open "log.txt" ]
    # set file_data [read $fp]
    # # puts $file_data
    # close $fp   
      


    verify_drc -area $xl $yl $xh $yh > log.txt
    set marker_type [dbGet [dbQuery -objType marker -area $xl $yl $xh $yh].type]
    set marker_subtype [dbGet [dbQuery -objType marker -area $xl $yl $xh $yh].subtype]
    set marker_box [dbGet [dbQuery -objType marker -area $xl $yl $xh $yh].box]

    append record_dynamic $marker_type,$marker_subtype,$marker_box
    


    return $record_dynamic
}




proc record_net_area_features {xl yl xh yh} {
    # inst and macro and placement density 

    set insts [get_db [dbQuery -area $xl $yl $xh $yh -objType inst] .name]
    set record_area "{$insts},"

    set nets [get_db [dbQuery -area $xl $yl $xh $yh -objType net] .name]
    append record_area "{$nets},"

    # set wires_begin_ext [get_db [dbQuery -area $xl $yl $xh $yh -objType wire] .begin_extension]
    # append record_area "{$wires_begin_ext},"

    # set wires_end_ext [get_db [dbQuery -area $xl $yl $xh $yh -objType wire] .end_extension]
    # append record_area "{$wires_end_ext},"

    set wires_direction [get_db [dbQuery -area $xl $yl $xh $yh -objType wire] .direction]
    append record_area "{$wires_direction},"


    set wires_layer [get_db [dbQuery -area $xl $yl $xh $yh -objType wire] .layer]
    append record_area "{$wires_layer},"

    set wires_length [get_db [dbQuery -area $xl $yl $xh $yh -objType wire] .length]
    append record_area "{$wires_length},"

    set wires_points [get_db [dbQuery -area $xl $yl $xh $yh -objType wire] .points]
    append record_area "{$wires_points},"

    set wires_rect [get_db [dbQuery -area $xl $yl $xh $yh -objType wire] .rect]
    append record_area "{$wires_rect},"

    set wires_width [get_db [dbQuery -area $xl $yl $xh $yh -objType wire] .width]
    append record_area "{$wires_rect},"

    # vias
    set vias_bottom_rects [get_db [dbQuery -area $xl $yl $xh $yh -objType via] .bottom_rects]
    append record_area "{$vias_bottom_rects},"

    set vias_cut_rects [get_db [dbQuery -area $xl $yl $xh $yh -objType via] .cut_rects]
    append record_area "{$vias_cut_rects},"

    set vias_location [get_db [dbQuery -area $xl $yl $xh $yh -objType via] .location]
    append record_area "{$vias_location},"

    set vias_net [get_db [dbQuery -area $xl $yl $xh $yh -objType via] .net]
    append record_area "{$vias_net},"

    set vias_top_rects [get_db [dbQuery -area $xl $yl $xh $yh -objType via] .top_rects]
    append record_area "{$vias_top_rects},"

    set vias_via_def [get_db [dbQuery -area $xl $yl $xh $yh -objType via] .via_def]
    append record_area "{$vias_via_def},"

    # row
    set row_name [get_db [dbQuery -area $xl $yl $xh $yh -objType row] .name]
    append record_area "{$row_name},"

    set row_num_x [get_db [dbQuery -area $xl $yl $xh $yh -objType row] .num_x]
    append record_area "{$row_num_x},"

    set row_num_y [get_db [dbQuery -area $xl $yl $xh $yh -objType row] .num_y]
    append record_area "{$row_num_y},"   

    set row_orient [get_db [dbQuery -area $xl $yl $xh $yh -objType row] .orient]
    append record_area "{$row_orient}," 

    set row_rect [get_db [dbQuery -area $xl $yl $xh $yh -objType row] .rect]
    append record_area "{$row_rect},"

    set row_step_x [get_db [dbQuery -area $xl $yl $xh $yh -objType row] .step_x]
    append record_area "{$row_step_x},"

    set row_step_y [get_db [dbQuery -area $xl $yl $xh $yh -objType row] .step_y]
    append record_area "{$row_step_y},"

    #pwire
    set pwires_layer [get_db [dbQuery -area $xl $yl $xh $yh -objType pwire] .layer]
    append record_area "{$pwires_layer},"

    set pwires_location [get_db [dbQuery -area $xl $yl $xh $yh -objType pwire] .location]
    append record_area "{$pwires_location},"

    set pwires_net [get_db [dbQuery -area $xl $yl $xh $yh -objType pwire] .net.name]
    append record_area "{$pwires_net},"

    set pwires_rect [get_db [dbQuery -area $xl $yl $xh $yh -objType pwire] .rect]
    append record_area "{$pwires_rect},"

    #pins
    set pins_base_name [get_db [dbQuery -area $xl $yl $xh $yh -objType instTerm] .base_name]
    append record_area "{$pins_base_name},"

    set pins_base_pin [get_db [dbQuery -area $xl $yl $xh $yh -objType instTerm] .base_pin]
    append record_area "{$pins_base_pin},"

    set pins_direction [get_db [dbQuery -area $xl $yl $xh $yh -objType instTerm] .direction]
    append record_area "{$pins_direction},"

    set pins_hnet [get_db [dbQuery -area $xl $yl $xh $yh -objType instTerm] .hnet]
    append record_area "{$pins_hnet},"

    set pins_inst [get_db [dbQuery -area $xl $yl $xh $yh -objType instTerm] .inst]
    append record_area "{$pins_inst},"

    set pins_layer [get_db [dbQuery -area $xl $yl $xh $yh -objType instTerm] .layer]
    append record_area "{$pins_layer},"

    set pins_location [get_db [dbQuery -area $xl $yl $xh $yh -objType instTerm] .location]
    append record_area "{$pins_location},"


    set pins_name [get_db [dbQuery -area $xl $yl $xh $yh -objType instTerm] .name]
    append record_area "{$pins_name},"
    

    set pins_bbox [get_db [dbQuery -area $xl $yl $xh $yh -objType instTerm] .base_pin.base_cell.bbox]
    append record_area "{$pins_bbox},"

    set pins_area [get_db [dbQuery -area $xl $yl $xh $yh -objType instTerm] .base_pin.base_cell.area]
    append record_area "{$pins_area},"

    set pins_memory [get_db [dbQuery -area $xl $yl $xh $yh -objType instTerm] .base_pin.base_cell.is_memory]
    append record_area "{$pins_memory},"

    set pins_macro [get_db [dbQuery -area $xl $yl $xh $yh -objType instTerm] .base_pin.base_cell.is_macro]
    append record_area "{$pins_macro}"

    
    return $record_area
}

proc get_wl_cad {} {
    set wl 0
    foreach wire_len [get_db nets .wires.length] {        
        set wl [expr $wl+$wire_len]
    }
    
    return $wl
}

proc get_num_vias_cad {} {
    set num_vias 0
    foreach via [get_db nets .vias] {        
        set num_vias [expr $num_vias+1]
    }
    return $num_vias
}

# Example:
# queryDensityInBox 180.2275 191.535 184.0005 189.799
# queryPinDensity 180.2275 191.535 184.0005 189.799
proc get_density_stdinst_to_freespace {text} {
   # area inst / freespace 
   set pattern {StdInstArea\/freeSpace\s\=\s\d+\.\d+}
   
   set matchTuples [regexp -all -inline $pattern $text]
   # puts [llength $matchTuples]
   # set numMatches [expr {[llength $matchTuples] / 2}]
   # puts $numMatches
   set res 0
   foreach x $matchTuples {
      set pattern2 {\d+\.\d+}
      # puts $x
      set matchTuples2 [regexp -all -inline $pattern2 $x]
      foreach y $matchTuples2 {
         set res $y
      }
      
   }

   return $res
}

proc get_density_macroinst_to_freespace {text} {
   # area inst / freespace 
   set pattern {macroInstArea\/totArea\s\=\s\d+\.\d+}
   
   set matchTuples [regexp -all -inline $pattern $text]
   # puts [llength $matchTuples]
   # set numMatches [expr {[llength $matchTuples] / 2}]
   # puts $numMatches
   set res 0
   foreach x $matchTuples {
      set pattern2 {\d+\.\d+}
      # puts $x
      set matchTuples2 [regexp -all -inline $pattern2 $x]
      foreach y $matchTuples2 {
         set res $y
      }
      
   }

   return $res
}

proc get_density_placementobs_to_freespace {text} {
   # area inst / freespace 
   set pattern {macroInstArea\/totArea\s\=\s\d+\.\d+}
   
   set matchTuples [regexp -all -inline $pattern $text]
   # puts [llength $matchTuples]
   # set numMatches [expr {[llength $matchTuples] / 2}]
   # puts $numMatches
   set res 0
   foreach x $matchTuples {
      set pattern2 {\d+\.\d+}
      # puts $x
      set matchTuples2 [regexp -all -inline $pattern2 $x]
      foreach y $matchTuples2 {
         set res $y
      }
      
   }

   return $res
}

proc get_density_pin {text} {
   # area inst / freespace 
   set pattern {Pin\sDensity\s\=\s\d+\.\d+}
   
   set matchTuples [regexp -all -inline $pattern $text]
   # puts [llength $matchTuples]
   # set numMatches [expr {[llength $matchTuples] / 2}]
   # puts $numMatches
   set res 0
   foreach x $matchTuples {
      set pattern2 {\d+\.\d+}
      # puts $x
      set matchTuples2 [regexp -all -inline $pattern2 $x]
      foreach y $matchTuples2 {
         set res $y
      }
      
   }

   return $res
}
