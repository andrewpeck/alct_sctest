set shortname  "alct_sctest"
set top_name   "alct_sctest"
set myProject  "alct_sctest"
set prom_type  "XCF32P"

set myScript   "genproms.tcl"

#set folder [lindex [split [pwd] /] end]
#if { $folder != "tools" } {
#    puts "This script needs to be executed from tools directory"
#    return
#} else {
#    cd ../
#}

set bit_filename   ${top_name}.bit
set mcs_filename   ${top_name}.mcs
set cfi_filename   ${top_name}.cfi
set prm_filename   ${top_name}.prm
set svf_verify     ${top_name}_verify.svf
set svf_noverify   ${top_name}_noverify.svf
set impact_script  ${top_name}.impactscript
set version_file   alct_sctest.v
set project_dir    [pwd]

set  MAJOR_VERSION "XX"
set  MINOR_VERSION "XX"
set  RELEASE_VERSION "XX"

set  FPGA_TYPE "XXXXXXXX"

set  FPGA_MODEL "LX150T"

set  MONTHDAY "MMDD"
set  YEAR "YYYY"


set vhdl_hex "aaaaaaaaaaaaaaaaaaa"

# optohybrid version extracting
set filename ${version_file}

set fid [open $filename r]
while {[gets $fid line] != -1} {

    # monthday
    if { [ regexp -all -- "define MONTHDAY" $line] } {
        regexp {16\'h[0-9]*} $line str
        set MONTHDAY [string range ${str} 4 7]
        puts $MONTHDAY
    }

    # year
    if { [ regexp -all -- "define YEAR" $line] } {
        regexp {16\'h[0-9]*} $line str
        set YEAR [string range ${str} 4 7]
        puts $YEAR
    }

    #fpga type
    if { [ regexp -all -- "define SPARTAN6" $line] } {
        if { [regexp {^\s*`define} $line] } {
            set FPGA_TYPE "SPARTAN6"
            puts $FPGA_TYPE
        }
    }
    if { [ regexp -all -- "define VIRTEXE" $line] } {
        if { [regexp {^\s*`define} $line] } {
            set FPGA_TYPE "VIRTEXE"
            puts $FPGA_TYPE
        }
    }

    #fpga model
    if { [ regexp -all -- "define LX150" $line] } {
        if { [regexp {^\s*`define} $line] } {
            set FPGA_MODEL "LX150"
            puts $FPGA_MODEL
        }
    }
    if { [ regexp -all -- "define LX150T" $line] } {
        if { [regexp {^\s*`define} $line] } {
            set FPGA_MODEL "LX150T"
            puts $FPGA_MODEL
        }
    }
    if { [ regexp -all -- "define LX100" $line] } {
        if { [regexp {^\s*`define} $line] } {
            set FPGA_MODEL "LX100"
            puts $FPGA_MODEL
        }
    }

}
close $fid

#set datecode ${RELEASE_YEAR}${RELEASE_MONTH}${RELEASE_DAY}
#set releasecode ${MAJOR_VERSION}.${MINOR_VERSION}.${RELEASE_VERSION}.${RELEASE_HARDWARE}
#
#
#puts $datecode
#puts $releasecode
#
#puts "Generating PROM files for firmware version $datecode"
#
## put out a 'heartbeat' - so we know something's happening.
puts "\n$myScript: running ($myProject)...\n"
#
#################################################################################
## synthesis
#################################################################################
#
## put out a 'heartbeat' - so we know something's happening.
##puts "\n$myScript: running ($myProject)...\n"
##
##if { ! [ open_project ] } {
##    return false
##}
#
##set_process_props
##
## Remove the comment characters (#'s) to enable the following commands
##process run "Synthesize"
##process run "Translate"
##process run "Map"
##process run "Place & Route"
###
##set task "Implement Design"
##if { ! [run_task $task] } {
##    puts "$myScript: $task run failed, check run output for details."
##    project close
##    return
##}
##
##set task "Generate Programming File"
##if { ! [run_task $task] } {
##    puts "$myScript: $task run failed, check run output for details."
##    project close
##    return
##}
#
##puts [exec xst -intstyle ise -ifn ${top_name}.xst -ofn ${top_name}.syr]
##puts [exec ngdbuild -intstyle ise -dd _ngo -sd ../src/ip_cores -nt timestamp -uc ../src/gtx/gtx_attributes.ucf -uc ../src/ucf/vfat2.ucf -uc ../misc.ucf -uc ../src/ucf/memory.ucf -uc ../src/ucf/clocking.ucf -uc ../src/ucf/gtx.ucf -p xc6vlx130t-ff1156-1 ${top_name}.ngc ${top_name}.ngd]
##puts [exec map -intstyle ise -p xc6vlx130t-ff1156-1 -w -logic_opt off -ol high -t 1 -xt 0 -register_duplication off -r 4 -global_opt off -mt off -ir off -pr off -lc off -power off -o ${top_name}_map.ncd ${top_name}.ngd ${top_name}.pcf]
##puts [exec par -w -intstyle ise -ol high -mt off ${top_name}_map.ncd ${top_name}.ncd ${top_name}.pcf ]
##puts [exec trce -intstyle ise -v 3 -s 1 -n 3 -fastpaths -xml ${top_name}.twx ${top_name}.ncd -o ${top_name}.twr ${top_name}.pcf]
##puts [exec bitgen -intstyle ise -f ${top_name}.ut ${top_name}.ncd]
#
#
#################################################################################
#puts "Generating mcs file..."
#################################################################################

if {[catch {set f_id [open $impact_script w]} msg]} {
    puts "Can't create $impact_script"
    puts $msg
    return
}

puts "Opened impact script for writing..."

puts $f_id "setMode -pff"
puts $f_id "setMode -pff"
puts $f_id "addConfigDevice  -name \"${top_name}.mcs\" -path \"${project_dir}\""
puts $f_id "setSubmode -pffserial"
puts $f_id "setAttribute -configdevice -attr multibootBpiType -value \"\""
puts $f_id "addDesign -version 0 -name \"0\""
puts $f_id "setAttribute -configdevice -attr compressed -value \"FALSE\""
puts $f_id "setAttribute -configdevice -attr compressed -value \"FALSE\""
puts $f_id "setAttribute -configdevice -attr autoSize -value \"FALSE\""
puts $f_id "setAttribute -configdevice -attr fileFormat -value \"mcs\""
puts $f_id "setAttribute -configdevice -attr fillValue -value \"FF\""
puts $f_id "setAttribute -configdevice -attr swapBit -value \"FALSE\""
puts $f_id "setAttribute -configdevice -attr dir -value \"UP\""
puts $f_id "setAttribute -configdevice -attr multiboot -value \"FALSE\""
puts $f_id "setAttribute -configdevice -attr multiboot -value \"FALSE\""
puts $f_id "setAttribute -configdevice -attr spiSelected -value \"FALSE\""
puts $f_id "setAttribute -configdevice -attr spiSelected -value \"FALSE\""
puts $f_id "addPromDevice -p 1 -size 0 -name xcf32p"
if { [FPGA_MODEL != "LX100") } {
puts $f_id "addPromDevice -p 2 -size 0 -name xcf08p"
}
puts $f_id "setMode -pff"
puts $f_id "setMode -pff"
puts $f_id "setSubmode -pffserial"
puts $f_id "setMode -pff"
puts $f_id "addDeviceChain -index 0"
puts $f_id "setMode -pff"
puts $f_id "setMode -pff"
puts $f_id "setMode -pff"
puts $f_id "addDeviceChain -index 0"
puts $f_id "addDevice -p 1 -file \"${project_dir}/${top_name}.bit\""
puts $f_id "setMode -pff"
puts $f_id "setSubmode -pffserial"
puts $f_id "generate"
puts $f_id "setCurrentDesign -version 0"

#################################################################################
puts $f_id "quit"
#################################################################################

close $f_id

puts "Finished writing impact script..."

set impact_p [open "|impact -batch $impact_script" r]

# echo impact output here:
while {![eof $impact_p]} { gets $impact_p line ; puts $line }

puts "Finished Creating PROM Files"

## adapted from https://forums.xilinx.com/t5/Vivado-TCL-Community/Vivado-TCL-set-generics-based-on-date-git-hash/td-p/426838
#
## Current date, time, and seconds since epoch
## 0 = 4-digit year
## 1 = 2-digit year
## 2 = 2-digit month
## 3 = 2-digit day
## 4 = 2-digit hour
## 5 = 2-digit minute
## 6 = 2-digit second
## 7 = Epoch (seconds since 1970-01-01_00:00:00)
## Array index                                            0  1  2  3  4  5  6  7
##set datetime_arr [clock format [clock seconds] -format {%Y %y %m %d %H %M %S %s}]
#
## Get the datecode in the yyyy-mm-dd format
##set datecode [lindex $datetime_arr 0]-[lindex $datetime_arr 2]-[lindex $datetime_arr 3]
#
## Show this in the log
##puts DATECODE=$datecode
#
## Get the git hashtag for this project
##set curr_dir [pwd]
##set proj_dir [get_property DIRECTORY [current_project]]
##cd $proj_dir
##set git_hash [exec git log -1 --pretty='%h']
## Show this in the log
##puts HASHCODE=$git_hash
#
## Set the generics
##set_property generic "DATE_CODE=32'h$datecode HASH_CODE=32'h$git_hash" [current_fileset]
#
#
#set releasedir     release/${shortname}_${datecode}_${releasecode}
#
#if {![file isdirectory release]} {
#    file mkdir release
#}
#
#if {![file isdirectory $releasedir]} {
#    file mkdir $releasedir
#}
#
#
# file copy -force $mcs_filename   ${releasedir}/${shortname}-${datecode}-${releasecode}.mcs
# file copy -force $bit_filename   ${releasedir}/${shortname}-${datecode}-${releasecode}.bit
##file copy -force $svf_verify     ${releasedir}/${shortname}-${datecode}-${releasecode}_verify.svf
##file copy -force $svf_noverify   ${releasedir}/${shortname}-${datecode}-${releasecode}_noverify.svf
# file copy -force $prm_filename   ${releasedir}/${shortname}-${datecode}-${releasecode}.prm
# file copy -force $cfi_filename   ${releasedir}/${shortname}-${datecode}-${releasecode}.cfi
# file copy -force $cdc_filename   ${releasedir}/${shortname}-${datecode}-${releasecode}.cdc
# file copy -force $xml_filename   ${releasedir}/$xml_filename
