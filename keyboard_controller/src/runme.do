# (c) Aldec, Inc.
# All rights reserved.
#
# Last modified: $Date: 2014-06-10 15:36:19 +0200 (Tue, 10 Jun 2014) $
# $Revision: 326171 $

# set project working directory
cd $aldec/examples/coverage/coverage_database/keyboard_controller

# load procedures and variables
source $aldec/examples/commonscripts/procedures.do
source src/variables.do

# create project library and clear its contents
createWorklib keyboard_controller

# compile design source files
alog -coverage sb -coverage_options count src/adder_subtractor.v src/multiplier.v src/divider.v src/cordic.v \
  src/scan2symbol.v src/scan2ascii.v src/symbol2ascii.v src/spec_symb_detect.v src/input_buffer.v src/alu.v \
  src/calculation_controller.v src/vga_write.v src/keyboard_controller.v src/tb.v src/send_test.v

acom -coverage sb -coverage_options count src/ps_2_controller.vhd

# initialize and run simulation with Coverage Database engine enabled and first set of stimulus
asim -acdb -acdb_file acdb/tb_test1.acdb -cvgperinstance -g /TB/INPUT_FILENAME="src/test_inputs_1.tst" $topLevel
run -all
endsim

# generating coverage report from first database
acdb report -db acdb/tb_test1.acdb -html -o acdb/tb_test1.html

# initialize and run simulation with Coverage Database engine enabled and second set of stimulus
asim -acdb -acdb_file acdb/tb_test2.acdb -cvgperinstance -g /TB/INPUT_FILENAME="src/test_inputs_2.tst" $topLevel
run -all
endsim

# generating a coverage report from second databse
acdb report -db acdb/tb_test2.acdb -html -o acdb/tb_test2.html

# merging results and generating final report
acdb merge -o acdb/merged.acdb -i acdb/tb_test1.acdb -i acdb/tb_test2.acdb
acdb report -db acdb/merged.acdb -html -o acdb/merged.html

# open resulting coverage report
system.open acdb/merged.html
