source util.tcl


proc get_wl_net { net } {
    set wl 0
    foreach wire_len [get_db [get_db nets $net] .wires.length] {        
        set wl [expr $wl+$wire_len]
    }
    return $wl
}

proc get_num_vias_net { net } {
    set num_vias 0
    foreach via [get_db [get_db nets $net] .vias] {        
        set num_vias [expr $num_vias+1]
    }
    return $num_vias
}

proc log_all_nets { file_name } {
    set fp [open "$file_name.csv" w+]
    set header "inst_name,net_name,wl,vias,wires_box"
    puts $fp $header
    foreach inst_obj [get_db insts] { 
        set inst_name [get_db $inst_obj .base_name] 
        # set record [log_net $inst_name]
        set nets [get_db [dbGet top.insts.name -p $inst_name] .pins.net.name]
        foreach net $nets {
            set wl [get_wl_net $net]
            set num_vias [get_num_vias_net $net]
            set wires [get_db [get_db nets $net] .wires.rect]
            puts $fp $inst_name,$net,$wl,$num_vias,$wires
        }
        
    }
    close $fp
}

proc log_wires { nets } {
    set total_wl 0
    set total_vias 0
    set wires_box 0

    foreach net $nets {
        set wl [get_wl_net $net]
        set num_vias [get_num_vias_net $net]
        set wires [get_db [get_db nets $net] .wires.rect]
        set total_wl [expr $total_wl + $wl]
        set total_vias [expr $total_vias + $num_vias]
        set wires_box "$wires_box $wires"
    }

    set record "$total_wl,$total_vias,$wires_box"
    return $record
}

# proc log_net { inst_name } {

#     # inst7030: net454 net455 net364 net25,{130.4 150.48}
#     # inst7222: net748 net12 net749 net82 net19,{{92.8 148.77}}
#     set nets [get_db [dbGet top.insts.name -p $inst_name] .pins.net.name]
#     foreach net $nets {
#         set wl [get_wl_net $net]
#         set num_vias [get_num_vias_net $net]
#         set wires [get_db [get_db nets $net] .wires.rect]
#         append record $net,$wl,$num_vias,$wires
#     }
#     return record
# }
proc tmp {} {

    set nets "net454 net455 net364 net25 net748 net12 net749 net82 net19"
    # editDelete -net {net454 net455 net364 net25 net748 net12 net749 net82 net19} 
    # setNanoRouteMode -quiet -routeSelectedNetOnly 1
    foreach net $nets {
        ::selectNet $net
    }
}

proc convert_orient2 { orient } {

    if { $orient == "r0" } {
        set $orient "R0"
    }
    if { $orient == "r90" } {
        set $orient "R90"
    }
    if { $orient == "r180" } {
        set $orient "R180"
    }
    if { $orient == "r270" } {
        set $orient "R270"
    }
    if { $orient == "mx" } {
        set $orient "MX"
    }
    if { $orient == "mx90" } {
        set $orient "MX90"
    }
    if { $orient == "my" } {
        set $orient "MY"
    }
    if { $orient == "my90" } {
        set $orient "MY90"
    }
    return $orient

}
proc route_init {inst_1 inst_2} {
    set nets_1 [get_db [dbGet top.insts.name -p $inst_1] .pins.net.name]
    set nets_2 [get_db [dbGet top.insts.name -p $inst_2] .pins.net.name]

    set nets "$nets_1 $nets_2"
    editDelete -net $nets
    setNanoRouteMode -quiet -routeSelectedNetOnly 1
    deselectAll
    foreach net $nets {
        # puts $net 
        ::selectNet $net
    }

    set wl_init [get_wl_cad]
    set vias_init [get_num_vias_cad]
    
    routeDesign > log.txt

}

proc check_swap {inst_1 inst_2} {
    set orient_1 [get_db [dbGet top.insts.name -p $inst_1] .orient]
    set orient_2 [get_db [dbGet top.insts.name -p $inst_2] .orient]
    set loc_1_x [get_db [dbGet top.insts.name -p $inst_1] .location.x]
    set loc_1_y [get_db [dbGet top.insts.name -p $inst_1] .location.y]
    set loc_2_x [get_db [dbGet top.insts.name -p $inst_2] .location.x]
    set loc_2_y [get_db [dbGet top.insts.name -p $inst_2] .location.y]

    set orient_1 [convert_orient2 $orient_1]
    set orient_2 [convert_orient $orient_2]

    placeInstance $inst_1 $loc_2_x $loc_2_y $orient_2
    placeInstance $inst_2 $loc_1_x $loc_1_y $orient_1
    
    set nets_1 [get_db [dbGet top.insts.name -p $inst_1] .pins.net.name]
    set nets_2 [get_db [dbGet top.insts.name -p $inst_2] .pins.net.name]

    set wl_init [get_wl_cad]
    set vias_init [get_num_vias_cad]

    set nets "$nets_1 $nets_2"
    editDelete -net $nets
    setNanoRouteMode -quiet -routeSelectedNetOnly 1
    foreach net $nets {
        # puts $net 
        ::selectNet $net
    }


    
    routeDesign > log.txt

    set wl [get_wl_cad]
    set vias [get_num_vias_cad]

    if { $wl > $wl_init || $vias > $vias_init } { 
        placeInstance $inst_1 $loc_1_x $loc_1_y $orient_1
        placeInstance $inst_2 $loc_2_x $loc_2_y $orient_2

        editDelete -net $nets
        setNanoRouteMode -quiet -routeSelectedNetOnly 1
        foreach net $nets {
            # puts $net 
            ::selectNet $net
        }
        routeDesign > log.txt

    } else {
        puts "new wl: $wl, vias: $vias, swap: ($inst_1, $inst_2)"
    }
    puts "old wl: $wl_init, old vias: $vias_init,new wl: $wl, vias: $vias"
}


proc check_swap_init {inst_1 inst_2} {
    route_init $inst_1 $inst_2

    set orient_1 [get_db [dbGet top.insts.name -p $inst_1] .orient]
    set orient_2 [get_db [dbGet top.insts.name -p $inst_2] .orient]
    set loc_1_x [get_db [dbGet top.insts.name -p $inst_1] .location.x]
    set loc_1_y [get_db [dbGet top.insts.name -p $inst_1] .location.y]
    set loc_2_x [get_db [dbGet top.insts.name -p $inst_2] .location.x]
    set loc_2_y [get_db [dbGet top.insts.name -p $inst_2] .location.y]

    set orient_1 [convert_orient2 $orient_1]
    set orient_2 [convert_orient $orient_2]

    placeInstance $inst_1 $loc_2_x $loc_2_y $orient_2
    placeInstance $inst_2 $loc_1_x $loc_1_y $orient_1
    
    set nets_1 [get_db [dbGet top.insts.name -p $inst_1] .pins.net.name]
    set nets_2 [get_db [dbGet top.insts.name -p $inst_2] .pins.net.name]

    set wl_init [get_wl_cad]
    set vias_init [get_num_vias_cad]

    set nets "$nets_1 $nets_2"

    set before_move_src_record [log_wires $nets_1]
    set before_move_tg_record [log_wires $nets_2]

    editDelete -net [get_db nets .name]
    # editDelete -net $nets
    # editDelete -net $nets
    setNanoRouteMode -quiet -routeSelectedNetOnly 1
    deselectAll
    foreach net $nets {
        # puts $net 
        ::selectNet $net
    }

    routeDesign > log.txt

    set after_move_src_record [log_wires $nets_1]
    set after_move_tg_record [log_wires $nets_2]

    set wl [get_wl_cad]
    set vias [get_num_vias_cad]

    # if { $wl > $wl_init && $vias > $vias_init } { }

    if { $wl < $wl_init && $vias < $vias_init } { 
        placeInstance $inst_1 $loc_1_x $loc_1_y $orient_1
        placeInstance $inst_2 $loc_2_x $loc_2_y $orient_2
        editDelete -net [get_db nets .name]
        deselectAll
        # editDelete -net $nets
        puts "Yup (WL+Via): old wl: $wl_init, old vias: $vias_init, new wl: $wl, vias: $vias, swap: ($inst_1, $inst_2)"
        # return "wl_via"
    } elseif { $wl < $wl_init } {
        placeInstance $inst_1 $loc_1_x $loc_1_y $orient_1
        placeInstance $inst_2 $loc_2_x $loc_2_y $orient_2
        editDelete -net [get_db nets .name]
        deselectAll
        # editDelete -net $nets
        puts "Yup (WL): old wl: $wl_init, old vias: $vias_init, new wl: $wl, vias: $vias, swap: ($inst_1, $inst_2)"
        # return "wl"
    } elseif { $vias < $vias_init } {
        placeInstance $inst_1 $loc_1_x $loc_1_y $orient_1
        placeInstance $inst_2 $loc_2_x $loc_2_y $orient_2
        editDelete -net [get_db nets .name]
        deselectAll
        # editDelete -net $nets
        puts "Yup (Via): old wl: $wl_init, old vias: $vias_init, new wl: $wl, vias: $vias, swap: ($inst_1, $inst_2)"
        # return "via"
    } else {
        placeInstance $inst_1 $loc_1_x $loc_1_y $orient_1
        placeInstance $inst_2 $loc_2_x $loc_2_y $orient_2

        editDelete -net [get_db nets .name]
        deselectAll
        # editDelete -net $nets
        puts "Nope: old wl: $wl_init, old vias: $vias_init, new wl: $wl, vias: $vias, swap: ($inst_1, $inst_2)"
        # return "no"
    }
    # editDelete -net [get_db nets .name]
    set record $nets_1,$nets_2,
    append record $before_move_src_record,$before_move_tg_record,
    append record $after_move_src_record,$after_move_tg_record 
    return  $record
    
}


proc apply_move {} {
    set orient_1 [get_db [dbGet top.insts.name -p inst7030] .orient]
    set orient_2 [get_db [dbGet top.insts.name -p inst7222] .orient]
    set loc_1 [get_db [dbGet top.insts.name -p inst7030] .location]
    set loc_2 [get_db [dbGet top.insts.name -p inst7222] .location]
    
    set_db [dbGet top.insts.name -p inst7030] .location $loc_1
    set_db [dbGet top.insts.name -p inst7222] .location $loc_2

    set_db [dbGet top.insts.name -p inst7030] .orient $orient_2
    set_db [dbGet top.insts.name -p inst7222] .orient $orient_1

    set nets "net454 net455 net364 net25 net748 net12 net749 net82 net19"
    editDelete -net {net454 net455 net364 net25 net748 net12 net749 net82 net19} 
    setNanoRouteMode -quiet -routeSelectedNetOnly 1
    foreach net $nets {
        ::selectNet $net
    }
    
    # ::selectNet net852
    # ::selectNet net65
    # ::selectNet net25   
    # ::selectNet net795 
    # ::selectNet net796
    # ::selectNet net1125
    # ::selectNet net25
    routeDesign 
}



proc swap_list_centroid {} {
    setMultiCpuUsage -localCpu 1
    # set inst_1_list {"inst3207" "inst3342" }
    # set inst_2_list {"inst3345" "inst3343" }
    set inst_1_list {"inst3207" "inst3342" "inst3280" "inst3012" "inst3136" "inst3342" "inst2820" "inst3080" "inst3136" "inst2949" "inst3280" "inst3136" "inst3207" "inst2949" "inst3012" "inst3136" "inst2759" "inst3280" "inst3277" "inst3342" "inst3207" "inst2949" "inst2759" "inst2820" "inst3342" "inst4228" "inst3207" "inst3894" "inst2759" "inst2820" "inst3347" "inst3136" "inst3012" "inst3342" }
    set inst_2_list {"inst3345" "inst3343" "inst3345" "inst3277" "inst3277" "inst4228" "inst3345" "inst3277" "inst3343" "inst3345" "inst3277" "inst4030" "inst3277" "inst3208" "inst3345" "inst3345" "inst3345" "inst3208" "inst3344" "inst4030" "inst3208" "inst3277" "inst3208" "inst3208" "inst3345" "inst4163" "inst3084" "inst3343" "inst3277" "inst3277" "inst4237" "inst4228" "inst3208" "inst3277" }

    set file_name "centroid"
    set fp [open "$file_name.csv" w+]
    set header "inst_src,inst_dst,nets_src,nets_dst,\
    before_wl_src,before_vias_src,before_wires_src,\
    before_wl_dst,before_vias_dst,before_wires_dst,\
    after_wl_src,after_vias_src,after_wires_src,\
    after_wl_dst,after_vias_dst,after_wires_dst"
    puts $fp $header

    # puts "[llength $inst_1_list]"
    set wl 0
    set via 0
    set wl_via 0
    
    for { set index 0 }  { $index < [llength $inst_1_list] }  { incr index } {
        set inst_1 "[lindex $inst_1_list  $index]"
        set inst_2 "[lindex $inst_2_list  $index]"
        # check_swap $inst_1 $inst_2
        set record [check_swap_init $inst_1 $inst_2]

        puts $fp $inst_1,$inst_2,$record
        # if {$sw == "wl_via"} {
        #     set wl_via [expr $wl_via + 1]
        # }
        # if {$sw == "via"} {
        #     set via [expr $via + 1]
        # }
        # if {$sw == "wl"} {
        #     set wl [expr $wl + 1]
        # }
    }
    # puts "wl_via: $wl_via, wl: $wl, via: $via"
    close $fp
}

proc swap_list_median {} {
    setMultiCpuUsage -localCpu 8
    set inst_1_list {"inst6531" "inst3092" "inst4030" "inst3136" "inst5506" "inst4228" "inst3080" "inst4241" "inst4030" "inst3343" "inst3277" "inst3894" "inst3278" "inst3034" "inst3208" "inst3092" "inst5020" "inst3034" "inst4030" "inst4030" "inst3092" "inst5020" "inst3084" "inst5020" "inst4228" "inst3343" "inst3343" "inst3277" "inst5020" "inst4030" "inst3208" "inst4030" "inst3136" "inst3084" "inst5272" "inst3277" "inst4030" "inst3343" "inst3034" "inst3034" "inst3343" "inst3034" "inst3277" "inst3277" "inst3342" "inst3277" "inst3136" "inst7222" "inst3343" "inst3034" "inst4228" "inst5020" "inst5272" "inst3277" "inst3084" "inst3277" "inst3081" "inst3342" "inst4237" "inst3277" "inst3208" "inst3136" "inst3080" "inst3080" "inst3034" "inst3277" "inst3136" "inst3342" "inst3034" "inst3034" "inst5020" }
    set inst_2_list {"inst7167" "inst3346" "inst2819" "inst3554" "inst3519" "inst4294" "inst3483" "inst3346" "inst3342" "inst3342" "inst2759" "inst3554" "inst3207" "inst3345" "inst2819" "inst3347" "inst3136" "inst3484" "inst3894" "inst3136" "inst3966" "inst3080" "inst3207" "inst3894" "inst3342" "inst3280" "inst3080" "inst2951" "inst3344" "inst3080" "inst3344" "inst3207" "inst2702" "inst3344" "inst7030" "inst3280" "inst3344" "inst3136" "inst4228" "inst3554" "inst2949" "inst3483" "inst3207" "inst3344" "inst3483" "inst2949" "inst3484" "inst7030" "inst2819" "inst3347" "inst3894" "inst3342" "inst6531" "inst2820" "inst2819" "inst2701" "inst3207" "inst3484" "inst3346" "inst2886" "inst3207" "inst3483" "inst3554" "inst3484" "inst3346" "inst2819" "inst4228" "inst3554" "inst3966" "inst3485" "inst3207" }

    # puts "[llength $inst_1_list]"
    set file_name "centroid_median"
    set fp [open "$file_name.csv" w+]
    set header "inst_src,inst_dst,nets_src,nets_dst,\
    before_wl_src,before_vias_src,before_wires_src,\
    before_wl_dst,before_vias_dst,before_wires_dst,\
    after_wl_src,after_vias_src,after_wires_src,\
    after_wl_dst,after_vias_dst,after_wires_dst"
    puts $fp $header

    set wl 0
    set via 0
    set wl_via 0


    for { set index 0 }  { $index < [llength $inst_1_list] }  { incr index } {
        set inst_1 "[lindex $inst_1_list  $index]"
        set inst_2 "[lindex $inst_2_list  $index]"
        # check_swap $inst_1 $inst_2
        set record [check_swap_init $inst_1 $inst_2]

        puts $fp $inst_1,$inst_2,$record

        # if {$sw == "wl_via"} {
        #     set wl_via [expr $wl_via + 1]
        # }
        # if {$sw == "via"} {
        #     set via [expr $via + 1]
        # }
        # if {$sw == "wl"} {
        #     set wl [expr $wl + 1]
        # }
    }

    # puts "wl_via: $wl_via, wl: $wl, via: $via"
    set record 
}


proc swap_list_brute_force {} {
    setMultiCpuUsage -localCpu 8
    set inst_1_list {"inst7238" "inst7222" "inst7173" "inst7167" "inst7030" "inst6691" "inst6534" "inst6531" "inst6129" "inst5975" "inst5907" "inst5823" "inst5506" "inst5504" "inst5424" "inst5272" "inst5255" "inst5166" "inst5091" "inst5086" "inst5020" "inst4518" "inst4356" "inst4294" "inst4241" "inst4237" "inst4228" "inst4163" "inst4030" "inst3966" "inst3894" "inst3554" "inst3519" "inst3485" "inst3484" "inst3483" "inst3347" "inst3346" "inst3345" "inst3344" "inst3343" "inst3342" "inst3280" "inst3278" "inst3277" "inst3208" "inst3207" "inst3206" "inst3136" "inst3092" "inst3084" "inst3081" "inst3080" "inst3051" "inst3034" "inst3012" "inst2951" "inst2949" "inst2886" "inst2882" "inst2823" "inst2820" "inst2819" "inst2759" "inst2702" "inst2701" }
    set inst_2_list {"inst7238" "inst7222" "inst7173" "inst7167" "inst7030" "inst6691" "inst6534" "inst6531" "inst6129" "inst5975" "inst5907" "inst5823" "inst5506" "inst5504" "inst5424" "inst5272" "inst5255" "inst5166" "inst5091" "inst5086" "inst5020" "inst4518" "inst4356" "inst4294" "inst4241" "inst4237" "inst4228" "inst4163" "inst4030" "inst3966" "inst3894" "inst3554" "inst3519" "inst3485" "inst3484" "inst3483" "inst3347" "inst3346" "inst3345" "inst3344" "inst3343" "inst3342" "inst3280" "inst3278" "inst3277" "inst3208" "inst3207" "inst3206" "inst3136" "inst3092" "inst3084" "inst3081" "inst3080" "inst3051" "inst3034" "inst3012" "inst2951" "inst2949" "inst2886" "inst2882" "inst2823" "inst2820" "inst2819" "inst2759" "inst2702" "inst2701" }

    # puts "[llength $inst_1_list]"
    set file_name "centroid_brute_force"
    set fp [open "$file_name.csv" w+]
    set header "inst_src,inst_dst,nets_src,nets_dst,\
    before_wl_src,before_vias_src,before_wires_src,\
    before_wl_dst,before_vias_dst,before_wires_dst,\
    after_wl_src,after_vias_src,after_wires_src,\
    after_wl_dst,after_vias_dst,after_wires_dst"
    puts $fp $header

    set wl 0
    set via 0
    set wl_via 0


    for { set i 0 }  { $i < [llength $inst_1_list] }  { incr i } {
        for { set j 0 }  { $j < [llength $inst_2_list] }  { incr j } { 
            if { $i != $j } {
                set inst_1 "[lindex $inst_1_list  $i]"
                set inst_2 "[lindex $inst_2_list  $j]"
                # check_swap $inst_1 $inst_2
                set record [check_swap_init $inst_1 $inst_2]

                puts $fp $inst_1,$inst_2,$record

                # if {$sw == "wl_via"} {
                #     set wl_via [expr $wl_via + 1]
                # }
                # if {$sw == "via"} {
                #     set via [expr $via + 1]
                # }
                # if {$sw == "wl"} {
                #     set wl [expr $wl + 1]
                # }
            }
        }
    }

    # puts "wl_via: $wl_via, wl: $wl, via: $via"
    close $fp
}


proc route_all {} {
    setMultiCpuUsage -localCpu 8 
    routeDesign
}
