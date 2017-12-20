DESCRIPTION:
	This sample design shows basic ACDB coverage analysis features.
	The design is implemented using both SystemVerilog and VHDL languages.

	The design under test is a control unit that processes keyboard signals and
	generates corresponding ASCII codes.

	The project also shows basic coverage statistics operations: i.e. enabling
	coverage collecting, saving coverage statistics into database, merging
	coverage data from multiple databases into a single one and generating
	coverage report directly from an .acdb file.

SIMULATION:
	Simulation of the design can be performed by executing the "runme.do" macro.
	The macro represents a complete scenario of ACDB usage:
	- compile the design source files with debugging information enabled
	  (required for Code Coverage data sampling);
	- compile testbench files;
	- initialize the first simulation session with coverage database engine enabled,
	  load stimulus from "test_inputs_1.tst" file, ACDB file - "acdb/tb_test1.acdb";
	  with with coverage database enabled
	- generate report "acdb/tb_test1.html" from the first database created;
	- initialize the second simulation session with coverage database engine enabled,
	  load stimulus from "test_inputs_2.tst" file, ACDB file - "acdb/tb_test2.acdb";
	  with with coverage database enabled
	- generate report "acdb/tb_test2.html" from the second database created;
	- merge "acdb/tb_test1.acdb" and "acdb/tb_test2.acdb" databases into
	  "acdb/merged.acdb";
	- generate resulting report "acdb/merged.html".

	As it can be seen from the resulting report cumulative coverage percent
	is greater than corresponding values from individual reports.

	Merged coverage results displayed in the report look as if they were
	collected in a single simulation.

LANGUAGE:
	SystemVerilog, VHDL

___________________________
(c) Aldec, Inc.
All rights reserved.

Last modified: $Date: 2014-08-05 15:29:10 +0200 (Tue, 05 Aug 2014) $
$Revision: 333186 $
