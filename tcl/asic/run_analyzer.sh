INVS=/CMC/tools/cadence/INNOVUS17.11.000_lnx86/bin/innovus
evalTcl="eval.tcl"
invsLog="log"

# inputDef="ispd19_test10_init.def ispd19_test10_place_init.def ispd19_test10_0.93.def"
# inputBenchmark="ispd18_test1 ispd18_test2 \
#  ispd18_test3 ispd18_test4 \
#  ispd18_test5 ispd18_test6 \
#  ispd18_test7 ispd18_test8 \
#  ispd18_test9 ispd18_test10 \
#  ispd19_test1 ispd19_test2 \
#  ispd19_test3 ispd19_test4 \
#  ispd19_test5 ispd19_test6 \
#  ispd19_test7 ispd19_test8 \
#  ispd19_test9 ispd19_test10"
# inputBenchmark="ispd18_test5 ispd18_test6 \
#  ispd18_test7 ispd18_test8 \
#  ispd18_test9 ispd18_test10 \
#  ispd19_test1 ispd19_test2 \
#  ispd19_test3 ispd19_test4 \
#  ispd19_test5 ispd19_test6 \
#  ispd19_test7 ispd19_test8 \
#  ispd19_test9 ispd19_test10"
inputBenchmark="ispd19_test1 ispd19_test2 \
 ispd19_test3 ispd19_test4 \
 ispd19_test5 ispd19_test6 \
 ispd19_test7 ispd19_test8 \
 ispd19_test9 ispd19_test10"

# inputBenchmark="ispd18_test7"

inputSettingPlacement="0 0.95 1"
inputSettingRouting="0 1 default"
# inputSettingPlacement="0"
# inputSettingRouting="0"
LEFAdr="./../../benchmarks"
DEFAdr="./routings"


for j in $inputBenchmark
do
    for i in $inputSettingPlacement
    do 
        for k in $inputSettingRouting
        do
            echo "-----------"
            dir_name="$j.$i.$k"

            lef_final_adr="$LEFAdr/$j/$j.input.lef"
            def_final_adr="$DEFAdr/$j.$i.$k.def"
            echo "$lef_final_adr"
            echo "$def_final_adr"

            mkdir "./logs/$dir_name"
            echo "setMultiCpuUsage -localCpu 7" >> $evalTcl
            echo "source analyze.tcl" >> $evalTcl
            echo "source load_benchmarks.tcl" >> $evalTcl
            echo "source get_db.tcl" >> $evalTcl
            echo "load_benchmarks $lef_final_adr $def_final_adr" >> $evalTcl
            echo "verify_drc -limit -1 > drc.txt" >> $evalTcl
            echo "run_analyze $dir_name" >> $evalTcl
            echo "log_insts $dir_name" >> $evalTcl
            echo "log_pins $dir_name" >> $evalTcl
            echo "log_nets $dir_name" >> $evalTcl
            echo "log_design $dir_name" >> $evalTcl
            echo "log_rows $dir_name" >> $evalTcl
            echo "log_layers $dir_name" >> $evalTcl
            echo "log_tracks $dir_name" >> $evalTcl
            echo "exit">> $evalTcl

            cmd="$INVS -init $evalTcl -log $invsLog.log -overwrite -nowin"
            echo $cmd
            # $cmd > log.txt
            $cmd

            rm -f $evalTcl
            rm -f "$invsLog.log"
            rm -f "$invsLog.logv"
            rm -f "$invsLog.cmd"
            rm -f "*.v"
            rm -f "*.rpt"
            echo "-----------"
        done
    done 
done


# rm -f `basename "$outputDef.v"
