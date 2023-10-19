proc global_router { dir_name bench_name } {
    set lef_adr "./../../benchmarks/$bench_name/$bench_name.input.lef"
    set def_adr "./../../benchmarks/$bench_name/$bench_name.input.def"
    puts "bench_name: $bench_name"
    puts "lef: $lef_adr"
    puts "def: $def_adr"
    puts "start load benchmarks..."
    loadLefFile $lef_adr > log.txt
    loadDefFile $def_adr > log.txt
    puts "Done load benchmarks!"

    set name "$dir_name/$bench_name"
    routeDesign > log_guide.txt
    saveRouteGuide -rguide $name.guide
}

proc log_global_router { dir_name } {
    set name "$dir_name"
    saveRouteGuide -rguide $name.guide
}
