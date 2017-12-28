global QSYS_SIMDIR
set tclfile C:/intelFPGA_pro/16.1/quartus/bin64/emif_0_example_design/sim/ed_sim/aldec/rivierapro_setup.tcl
set userlib ddr_test
set usertop top
set comsout "coms.do"
set elabsout "elabs.do"
set Aldec "Riviera"
if { [ string match "*Active-HDL*" [ vsim -version ] ] } {
	set Aldec "Active"
}
if { [ string match "Active" $Aldec ] } {
	scripterconf -tcl
}

proc ensure_lib { lib } { if ![file isdirectory $lib] { vlib $lib } }
proc del_lib { lib } { amap -del $lib }

#set scripting to tcl mode
proc set_tcl_mode { } {
	set Aldec "Riviera"
	if { [ string match "*Active-HDL*" [ vsim -version ] ] } {
		set Aldec "Active"
	}
	if { [ string match "Active" $Aldec ] } {
		scripterconf -tcl
	}
}

#tcl mode
alias stcl {
	set_tcl_mode
}

#set scripting to do mode
proc set_do_mode { } {
	set Aldec "Riviera"
	if { [ string match "*Active-HDL*" [ vsim -version ] ] } {
		set Aldec "Active"
	}
	if { [ string match "Active" $Aldec ] } {
		scripterconf -do
	}
}

#do mode
alias sdo {
	set_do_mode
}

#task	: replace_slashes \\\
#in		: path 
#out	: path with slashes ///
proc replace_slashes { path } {
	set fname_list [file split $path] 
	set fname2 [eval file join $fname_list] 
	return $fname2
}

#test : replace_slashes
alias trs {
	puts [replace_slashes $aldec]
}
#task : to check if work lib is top
#in : comline	- compilation line
#in : sustoplib	- suspected top lib
#in : verb		- verbosity
#out : 1 - if is top, 0 if not
proc top_iscompiled {comline sustoplib verb} {
	set ret 0
	set str ""
	set lcode [regexp -all -inline {\S+} $comline]
	if {
		( ([lindex $lcode [expr [llength $lcode] - 2]]=="-work") &&
		  ([lindex $lcode [expr [llength $lcode] - 1]]==$sustoplib)
		)
	} then {
		if {$verb==1} {
			puts "found a top level compilation line : $comline"
		}
		set ret 1
	}
	return $ret
}

proc replace_use_entity { files orig_libs verb } {
	
	global suffix
	
	set found [list ]

	foreach f $files {
		set fflag 0
		if {($verb==1)} {
			puts [format "start searching file %s for library use entity references" $f]
		}
		if { ([ file extension $f ] == ".vhd") } {
			if {($verb>=1)} {
				puts [format "file %s is VHDL file" $f]
			}
			##set path [genpath $f]
			set fp [open $f r]
			set file_data [read $fp]
			set ostr ""
			close $fp 
			set rl 0
			set rr 0
			set searchdata $file_data
			if {($verb==1)} {
				puts [format "length of search string is now %d " [string length $searchdata]]
			}
			set pattern {((?:^|[\r*\n]|\s*|\t*)use\sentity[\s\t]+)(\S+)([.])(\S+)([;])}
			while 1 {
				if { [regexp -nocase $pattern $searchdata value zero first dot second end]} {
					regexp -indices $pattern $searchdata location
					set ls [split $location]
					set start [lindex $ls 0]
					set last  [lindex $ls 1]
					if {($verb>=1)} {
						puts [format "VHDL library reference %s was found - location  %d %d" $first $start $last ]
					}
					if { $start !=0 } {
						set rr [ expr $rl + $start - 1 ]
						if {($verb>1)} {
							puts [format "appending original data from %d to %d" $rl $rr ]
						}
						append ostr [string range $file_data $rl $rr]
						set rl [expr $rl + $start ]
					}
					
					set searchdata [string range $searchdata  [expr $last + 1] [expr [string length $file_data]-1]]
					if {($verb==1)} {
						puts [format "length of search string is now %d " [string length $searchdata]]
					}
					if {$first in $orig_libs} {
						if {($verb>=1)} {
							puts [format "referenced library %s is in library list" $first ]
						}
						set lline [format "%s%s_%s%s%s%s" $zero $first $suffix $dot $second $end]
						append ostr $lline
						if { $fflag ==0 } {
							set fflag 1
						}
						
					} else {
						if {($verb>=1)} {
							puts [format "referenced library %s is not in library list" $first ]
						}
						append ostr $value
					}
					#set rr [expr $rr + $last - $start + 2 ]
					#set rl [expr $rl + $last - $start + 2 ]
					set rl [expr $rl + $last - $start + 1 ]
				} else {
					if {($verb==1)} {
						puts [format "finish searching file %s" $f]
					}
					if {($verb>=2)} {
						if { $fflag ==0 } {
							puts [format "no library was found in file %s" $f]
						} else {
							puts [format "libraries references found in file %s" $f]
						}
					}
					set rr [expr [string length $file_data ] -1]
					append ostr [string range $file_data $rl $rr]
					break
				}
			}
			set sFrom $f
			set sTo [format "%s.bak2" $f]
			if {[catch {file copy -force $sFrom $sTo} sError]} {
				FAIL "file copy failed: err:$sError to:$sTo"
			}
			set fp [open $f w]
			puts $fp $ostr
			close $fp
			
		} else {
			if {($verb==1)} {
				puts [format "file %s is not a VHDL file" $f]
			}
		}
		
		lappend $found $fflag
	}
	return $found
}


proc replace_libs_vhdl { files orig_libs verb } {
	
	global suffix
	
	set found [list ]

	foreach f $files {
		set fflag 0
		if {($verb==1)} {
			puts [format "start searching file %s" $f]
		}
		if { ([ file extension $f ] == ".vhd") } {
			if {($verb>=1)} {
				puts [format "file %s is VHDL file" $f]
			}
			##set path [genpath $f]
			set fp [open $f r]
			set file_data [read $fp]
			set ostr ""
			close $fp 
			set rl 0
			set rr 0
			set searchdata $file_data
			if {($verb==1)} {
				puts [format "length of search string is now %d " [string length $searchdata]]
			}
			set pattern {((?:^|\n|\s|\t)library[\s\t]+)(\S+)([;])}
			while 1 {
				if { [regexp -nocase $pattern $searchdata value zero first end]} {
					regexp -indices $pattern $searchdata location
					set ls [split $location]
					set start [lindex $ls 0]
					set last  [lindex $ls 1]
					if {($verb>=1)} {
						puts [format "VHDL library %s was found - location  %d %d" $first $start $last ]
					}
					if { $start !=0 } {
						set rr [ expr $rl + $start - 1 ]
						append ostr [string range $file_data $rl $rr]
						set rl [expr $rl + $start ]
					}
					
					set searchdata [string range $searchdata  [expr $last + 1] [expr [string length $file_data]-1]]
					if {($verb==1)} {
						puts [format "length of search string is now %d " [string length $searchdata]]
					}
					if {$first in $orig_libs} {
						if {($verb>=1)} {
							puts [format "library %s is in library list" $first ]
						}
						set lline [format "%s%s_%s%s" $zero $first $suffix $end]
						append ostr $lline
						if { $fflag ==0 } {
							set fflag 1
						}
						
					} else {
						if {($verb>=1)} {
							puts [format "library %s is not in library list" $first ]
						}
						append ostr $value
					}
					#set rr [expr $rr + $last - $start + 2 ]
					#set rl [expr $rl + $last - $start + 2 ]
					set rl [expr $rl + $last - $start + 1 ]
				} else {
					if {($verb==1)} {
						puts [format "finish searching file %s" $f]
					}
					if {($verb>=2)} {
						if { $fflag ==0 } {
							puts [format "no library was found in file %s" $f]
						} else {
							puts [format "libraries found in file %s" $f]
						}
					}
					set rr [expr [string length $file_data ] -1]
					append ostr [string range $file_data $rl $rr]
					break
				}
			}
			set sFrom $f
			set sTo [format "%s.bak" $f]
			if {[catch {file copy -force $sFrom $sTo} sError]} {
				FAIL "file copy failed: err:$sError to:$sTo"
			}
			set fp [open $f w]
			puts $fp $ostr
			close $fp
			
		} else {
			if {($verb==1)} {
				puts [format "file %s is not a VHDL file" $f]
			}
		}
		
		lappend $found $fflag
	}
	return $found
}


alias trlv  {
	set files [list ] 
	lappend files "stam.vhd"
	set orig_libs [list  look at me deselector_lib rsff_lib generator_lib counterb_lib mux0_lib muxb0_lib ]
	set replaced [replace_libs_vhdl $files $orig_libs 2 ]
	set replaced [replace_use_entity $files $orig_libs 2 ]
}

proc get_files { codelines verb } {
	set lfiles [list]
	set pattern {((?:[\w\$\/\.]*)(?:(?:[.]vhd)|(?:[.]v)|(?:[.]sv)))}
	foreach codeline $codelines {
		if { [regexp -nocase $pattern $codeline value first]} {
			if {$first ni $lfiles } {
				lappend lfiles $first
			}
		}
	}
	return $lfiles
}

proc get_libs { codelines verb } {
	set llibs [list]
	set pattern {.*[\s\t]+-work[\s\t]*([\w]*)[\s\t]*}
	foreach codeline $codelines {
		if { [regexp -nocase $pattern $codeline value first]} {
			if {$first ni $llibs } {
				lappend llibs $first
			}
		}
	}
	return $llibs
}


proc replace_vars { scode } {
	global QSYS_SIMDIR
	global USER_DEFINED_COMPILE_OPTIONS
	set scode [string map [list {$QSYS_SIMDIR} $QSYS_SIMDIR] $scode]
	set scode [string map [list {$USER_DEFINED_COMPILE_OPTIONS} $USER_DEFINED_COMPILE_OPTIONS] $scode]
	return $scode
}
		
proc replace_vhdl_librarirs_in_files { codelines verb } {
	set files [ get_files $codelines $verb]	
	set files [ replace_vars $files ]
	set libs [ get_libs $codelines $verb]
	if {$verb==1} {
		puts $files
		puts $libs
	}
	set replacedl [ replace_libs_vhdl $files $libs $verb ]
	set replacede [ replace_use_entity $files $libs $verb ]
	
	return $replacedl
}

proc add_sufix_compiled_lib { comline  } {
	global suffix
	if { ($suffix != "") } {
		set comline [ string trimright $comline " " ] 
		set newcomline [format "%s_%s" $comline $suffix]
	} else {
		set newcomline $comline
	}
	return $newcomline
}

#task	: replace old top with new userlib top (-work lib)
#in		: comline - compilation command line
#in		: top - script top level project
#in		: usr_lib - the user top library
#out	: new compilation line string
proc replace_compiled_lib {comline top user_lib verb} {
	set newcomline ""
	set str ""
	set lcode [regexp -all -inline {\S+} $comline]
	set last [expr [llength $lcode] - 1]
	if { [lindex $lcode $last]==$top } {
		for {set l 0} {$l < [expr [llength $lcode] - 1]} {incr l} {
			set str [concat $str [lindex $lcode $l]]
			set str [concat $str " "]
		} 
		set str [concat $str $user_lib]
		if {$verb==1} {
			puts "replaced work lib $top with userlib $str"
		}
		set newcomline $str
	} else {
		set newcomline $comline
	}
	return $newcomline
}
#read compilation commands from tcl ALTERA file
#input : tclfile : tcl file name
#input : devcom  : will get also all altera libraries compilation lines (alternative)
#input verb      : verbosity
#output : list of compilation commands taken from COM section.,replace user_lib 
proc read_com_line {tclfile_name user_lib devcom verb} {
	eval clear
	set lcomlines ""
	set comstart 0
	set devcomstart 0
	set num 0
	set ftclfile [open $tclfile_name]
	while {[gets $ftclfile line] != -1} {
		if {$devcom==1} {
			if {[regexp {^[\s]*alias dev_com} $line value]} {
				set devcomstart 1
				if {$verb>=1} {
					puts "found device compilation section"
				}
			}
			if {$devcomstart==1} {
				if {[regexp {\}} $line value]} {
					if {$verb>=1} {
						puts "end device compilation section"
					}
					set devcomstart 0
					break
				} else {
					set lcode [regexp -all -inline {\S+} $line]
					set opt0 [lindex $lcode 0]
					set opt1 [lindex $lcode 1]
					if {[regexp {^[^#]} $opt0]} { 
						if {
							(($opt0=="vlog") || ($opt0=="vcom")) || 
							(($opt0=="eval") && (($opt1=="vlog") || ($opt1=="vcom")))
						} then {
							set num [expr $num +1]
							lappend lcomlines $line
						}
					}
				}
			}
		}
		if {[regexp {^[\s]*alias com} $line value]} {
			set comstart 1 	
			if {$verb>=1} {
				puts "found compilation section"
			}
		}
		if {$comstart==1} {
			if {[regexp {\}} $line value]} {
				if {$verb>=1} {
					puts "end compilation section"
				}
				set comstart 0
				break
			} else { 
				set lcode [regexp -all -inline {\S+} $line]
				set opt0 [lindex $lcode 0]
				set opt1 [lindex $lcode 1]
				if {[regexp {^[^#]} $opt0]} { 
					if {
						(($opt0=="vlog") || ($opt0=="vcom")) || 
						(($opt0=="eval") && (($opt1=="vlog") || ($opt1=="vcom")))
					} then {
						set num [expr $num +1] 
						if {$user_lib != ""} {
							set top [read_top_level_name $tclfile_name 0]
							if {$verb==2} {
								puts "read_com_line: top $top"
							}
							if {[regexp {([\w\-\\\/]+).([\w\-\\\/]+)} $top value lib module]} {
									set top $lib
							}
							if {[top_iscompiled $line $top 0]==1} {
								set newline [replace_compiled_lib $line $top $user_lib 0]
								if {$verb==2} {
									puts "read_com_line: new comp line is $newline"
								}
								lappend lcomlines $newline
							} else {
								#set newline [add_sufix_compiled_lib $line ]
								lappend lcomlines $line
							}
						} else {
							lappend lcomlines $line
						} 
					}
				}
			}
		}
	}
	if {$verb>=1} {
		puts [format { %d compilation code line detected} $num]  
		puts $lcomlines
	}
	return $lcomlines
}

#read elab command from tclfile
#input      : tclfile - tcl file name
#input verb : verbosity
#output     : elaboration line command
proc read_elab_line { tcl_file verb } {
	set lcomlines ""
	set elabstart 0
	set num 0
	set ftclfile [open $tcl_file]
	while { [gets $ftclfile line] != -1} {
		if {[regexp {^alias elab\s\{.*} $line value] } {
			set elabstart 1
			if {$verb>=1} {
				puts "found elab section"
			}
		}
		if {$elabstart==1} {
			if {[regexp {\}} $line value]} {
				if {$verb>=1} {
					puts "end elab section"
				}
				set elabstart 0
				break
			} else {
				set lcode [regexp -all -inline {\S+} $line]
				set opt0 [lindex $lcode 0]
				set opt1 [lindex $lcode 1]
				if {[regexp {^[^#]} $opt0]} { 
					if {
						(($opt0=="vsim") ||
						($opt1=="vsim") && ($opt0=="eval"))
					} then {
						set num [expr $num +1]
						set lcomlines $line
					} 
				} 
			}
		}
	}  
	if { $num > 0 } {
		if {$verb>=1} {
			puts [format { %d elaboration command detected} $num]  
			puts $lcomlines
		}
	}
	return $lcomlines
}

#read simdir env from tclfile
#input		: tclfile - tcl file name
#input verb	: verbosity
#output		: simdir variable , remove the ""
proc read_sim_dir { tclfile verb } {
	set lcomlines ""
	set simdirstart 0
	set num 0
	set ftclfile [open $tclfile]
	set opt2 ""
	while {[gets $ftclfile line] != -1} {
		if {[regexp {^if\s\!\[info\sexists\sQSYS_SIMDIR\]\s\{} $line value]} {
			set simdirstart 1
			if {$verb>=1} {
				puts "found simdir section"
			}
		} else {
			if {$simdirstart==1} {
				if {[regexp {\}} $line value]} {
					if {$verb>=1} {
						puts "end simdir section"
					}
					set simdirstart 0
					break
				} else {
					set lcode [regexp -all -inline {\S+} $line]
					set opt0 [lindex $lcode 0]
					set opt1 [lindex $lcode 1]
					set opt2 [lindex $lcode 2]
					if {$verb>=2} {
						puts $opt0
						puts $opt1
						puts $opt2
					}
					if {[regexp {^[^#]} $opt0]} { 
						if { (($opt0=="set") && ($opt1=="QSYS_SIMDIR")) } {
							set num [expr $num +1] 
						}
					}
				}
			}
		}
	}
	if { $num > 0 } {
		if { $verb>=1 } {
			puts [format { %d simdir line detected : %s } $num $opt2 ]  
		}
	}
	
	if {[regexp {"([\w\-.\\\/\s]+)"} $opt2 value fopt2]} {
		if { $verb>=1 } {
			puts $fopt2
		}
		return $fopt2 
	} else {
		return $opt2
	}
}


#read simdir env from tclfile
#input   : tclfile - tcl file name
#input verb      : verbosity
#output  : simdir variable, remove the ""
proc read_top_level_name { tcl_file verb } {
	set lcomlines ""
	set tlstart 0
	set num 0
	set ftclfile [open $tcl_file]
	set opt2 ""
	while {[gets $ftclfile line] != -1} {
		if {[regexp {^if\s\!\[info\sexists\sTOP_LEVEL_NAME\]\s\{} $line value]} {
			set tlstart 1
			if {$verb>=1} {
				puts "found simdir section"
			}
		} else {
			if {$tlstart==1} {
				if {[regexp {\}} $line value]} {
					if {$verb>=1} {
						puts "end simdir section"
					}
					set tlstart 0
					break
				} else {
					set lcode [regexp -all -inline {\S+} $line]
					set opt0 [lindex $lcode 0]
					set opt1 [lindex $lcode 1]
					set opt2 [lindex $lcode 2]
					if {[regexp {^[^#]} $opt0]} { 
						if { (($opt0=="set") && ($opt1=="TOP_LEVEL_NAME")) } {
							set num [expr $num +1] 
						}
					}
				}
			}
		}
	}
	if { $num > 0 } {
		if {$verb>=1} {
			puts [format { %d TOP_LEVEL_NAME line detected %s } $num $opt2 ]  
		}
	}
	
	if {[regexp {"([\w\-.\\\/\s]+)"} $opt2 value fopt2]} {
		if { $verb>=1 } {
			puts $fopt2
		}
		return $fopt2 
	} else {
		return $opt2
	}
}

proc new_top_level_name { tcl_file user_lib user_top } {
	set top [read_top_level_name $tcl_file 0]
	if {(($user_lib != "") && ($user_top==""))} { 
		if {[regexp {([\w\-\\\/]+).([\w\-\\\/]+)} $top value lib module]} {
			return $user_lib.$module
		} else {
			return $user_lib.$top
		}
	} elseif {(($user_lib != "") && ($user_top!=""))} { 
			return $user_lib.$user_top
	} elseif {(($user_lib == "") && ($user_top!=""))} { 
		if {[regexp {([\w\-\\\/]+).([\w\-\\\/]+)} $top value lib module]} {
			return $lib.$user_top
		} else {
			return $user_top
		}
	} else {
		return $top
	}
}
#read copy file commands from tclfile
#input   : tclfile_name - tcl file name
#input   : verb - verbosity
#output  : copy files commands
proc read_copy_files { tclfile_name verb } {
	set lcplines ""
	set fcstart 0
	set num 0
	set ftclfile [open $tclfile_name]
	while {[gets $ftclfile line] != -1} {
		if {[regexp {^alias\sfile_copy\s\{} $line value]} {
			set fcstart 1
			if {$verb>=1} {
				puts "found file copy section"
			}
		} else {
			if {$fcstart==1} {
				if {[regexp {\}} $line value]} {
					if {$verb>=1} {
						puts "end file copy section"
					}
					set fcstart 0
					break
				} else {
					set lcode [regexp -all -inline {\S+} $line]
					set opt0  [lindex $lcode 0]
					set opt1  [lindex $lcode 1]
					set opt2  [lindex $lcode 2]
					if {[regexp {^[^#]} $opt0]} { 
						if {
							(($opt0=="file") && ($opt1=="copy") && ($opt2=="-force"))
						} then {
							set num [expr $num +1]
							lappend lcplines $line 
						} 
					}
				}
			}
		}
	}
	if { $num > 0 } {
		if {$verb>=1} {
			puts [format { %d compilation codes line detected } $num ]
		}
	}  
	return $lcplines
}

#read all libraries mapped by the tcl file
#input   : tclfile_name - tcl file name
#input   : verb - verbosity
#output  : libraries
proc read_libraries { tclfile_name verb } {
	set libraries ""
	set num 0
	set ftclfile [open $tclfile_name]
	while {[gets $ftclfile line] != -1} {
		set lcode [regexp -all -inline {\S+} $line]
		set opt0  [lindex $lcode 0]
		set opt1  [lindex $lcode 1]
		set opt2  [lindex $lcode 2]
		if {$verb>=2} {
			puts $opt0
			puts $opt1
			puts $opt2
		}
		if {[regexp {^[^#]} $opt0]} { 
			if {
				($opt0=="vmap")
			} then {
				set num [expr $num + 1]
				lappend libraries $opt1 
			} 
		} 
	} 
	if {$num>0} {
		if {$verb>=1} {
			puts [format { %d libraries detected } $num]  
			puts $libraries
		}
	} 
	return $libraries
}


proc find_local_libs_libs { verb } {
	set libs ""
	set fcfg [open ./../library.cfg]
	while {[gets $fcfg line] != -1} {
		if {[regexp {([\w\-. ]+)\s[=]\s[""]([.//]*)([\w\-. //]+).*[""].*} $line value first mid second]} {
			if {$verb==1} {
				puts "flll : found : $value : $first $mid $second"
			}
			set second [format {./../%s%s} $mid $second]
			if {$verb==1} {
				puts "flll : after change $second"
			}
			lappend libs $first $second
		}
	}
	return $libs
}

#find local project libs : lib libname
#input   : codeline - compilation lines
#input   : verb - verbosity
#output  : libraries needed to be add to compilation command 
proc find_local_libs { } {
	set libs ""
	set fcfg [open ./../library.cfg]
	while {[gets $fcfg line] != -1} {
		if {[regexp {([\w\-. ]+)\s[=]\s[""][.]([\w\-. //]+).*} $line value first second]} { 
			lappend libs $first
		}
	}  
	return $libs
}

proc find_global_libs_libs { aldec_path } {
	set aloc [format {%s/vlib} $aldec_path]
	set fcfg [open $aloc/library.cfg]	
	while {[gets $fcfg line] != -1} {
		if {[regexp {([\w\-. ]+)\s[=]\s[""][.]([\w\-. //]+).*} $line value first second]} { 
			if [string match {[/]*} $second] {
				if {[regexp {[//](.*)} $second value f]} {
					set second [format {%s/%s} $aloc $f]
				}
			}
			lappend libs $first $second
		}
	}
	return $libs
}

#find local project libs : lib libname
#input		: aldec_path - ldec path
#input		: verb - verbosity
#output		: libraries needed to be add to compilation command 
proc find_global_libs { aldec_path } {
	set aloc [format {%s/vlib} $aldec_path]
	set fcfg [open $aloc/library.cfg]
	while {[gets $fcfg line] != -1} {
		if {[regexp {([\w\-. ]+)\s[=]\s[""][.]([\w\-. //]+).*} $line value first second]} {
			lappend libs $first
		}
	}
	return $libs
}

#substruct lists content
proc listsub {a b} {
	set sub ""
	set match 0
	foreach i $a {
		foreach j $b {
			if {$i==$j} {
				set match 1
				break
			}
		}
		if {$match==1} {
			set match 0
		} else {
			lappend sub $i
		}
	}
	return $sub
}


 
#get needed libraries to generate in project from tclfile
#input   : tclfile
#output  : new libs to generate for project
proc newlibs { tcl_file aldec_path } {
	set libs ""
	set all_libs ""
	set llibs [find_local_libs]
	set glibs [find_global_libs $aldec_path ]
	set all_libs [concat $llibs $glibs]
	set mlibs [read_libraries $tcl_file 0]
	set libs [listsub $mlibs $all_libs ]
	return $libs
}

proc get_missing_modules { verb } {
	set missingmoduleslist ""
	set f [open tmp.txt]
	while {[gets $f line] != -1} {
		if {[regexp {(.*)(Undefined\smodule[:]\s)(.*) was used[.]} $line value first second third]} { 
			if {$verb == 1} {
				puts [format {gmm: %s %s %s} missing module: ${third}]
			}
			lappend missingmoduleslist $third
		}
	}
	close $f
	return $missingmoduleslist
}

proc is_open {chan} {expr {[catch {tell $chan}] == 0}}

#search for module inside libs - return lib name
proc find_modules { path missingmoduleslist libs verb  } {
	set retlist ""
	set num 0
	foreach {module} $missingmoduleslist {
		set modfound 0
		foreach {lib libdir} $libs {   
			set filelib [format {%s} $libdir]
			if {$verb == 1} {
				puts [format {fm: searching for %s in %s liberary %s } $module $filelib $lib]
			}
			#set savdir [pwd]
			#cd $path
			set flib [open $filelib]
			while {[gets $flib line] != -1} {
				set ptrn [format {*%s*} $module]
				if {[string match $ptrn $line]} { 
					if {$verb == 1} {
						puts [format {fm: module %s found in library %s} $module $lib]
						incr num 
					}
					lappend retlist $module
					set modfound 1
					break
				}
			}
			if {[is_open $flib]} {
				close $flib
			}
			#cd $savdir
			if { $modfound == 1 } {
				break
			} 
		}
	}
	if {$verb == 1} {
		puts "fm: exit with path $path : number of modules found $num"
	}
	return $retlist
}

#search for module inside libs - return lib name
proc find_libs_containing_modules { path missingmoduleslist libs verb  } {
	set retlist ""
	set num 0
	foreach {module} $missingmoduleslist {
		set libfound 0
		foreach {lib libdir} $libs {   
			set filelib [format {%s} $libdir]
			if {$verb == 1} {
				puts [format {flcm: searching for %s in %s liberary %s } $module $filelib $lib]
			}
			#set savdir [pwd]
			#cd $path
			set flib [open $filelib]
			while {[gets $flib line] != -1} {
				set ptrn [format {*%s*} $module]
				if {[string match $ptrn $line]} { 
					if {[lsearch $retlist $lib]==-1} {
						if {$verb == 1} {
							puts [format {flcm: module %s found in library %s} $module $lib]
							incr num 
						}
						lappend retlist $lib
					}
					set libfound 1
					break
				}
			}
			if {[is_open $flib]} {
				close $flib
			}
			#cd $savdir
			if { $libfound == 1 } {
				break
			} 
		}
	}
	if {$verb == 1} {
		puts "flcm: exit with path $path : number of modules found $num"
	}
	return $retlist
}

#read all libraries mapped by the tcl file
#input   : codeline - compilation lines
#input   : verb - verbosity
#output  : libraries needed to be add to compilation command 
proc check_find_missing_lib {codeline aldec_path tcl_file alteralibs verb} {  
	set USER_DEFINED_COMPILE_OPTIONS ""
	set QSYS_SIMDIR [find_qsys_simdir $tcl_file $verb]
	set retlist ""
	set libs ""
	set llibs ""
	set glibs ""
	set llibs [find_local_libs_libs 0]
	#find global libs : lib libname
	if {$alteralibs==1} {
		set glibs [find_global_libs_libs $aldec_path ]
	}
	#set libs [concat $llibs $glibs]
	### try compile ...
	set codedump [format {%s > tmp.txt} $codeline]
	eval $codedump
	### find missing modules
	set missingmoduleslist [get_missing_modules $verb]
	if {$missingmoduleslist != ""} {
		set path [format {%s/vlib} $aldec_path]
		set gl [find_libs_containing_modules $path $missingmoduleslist $glibs $verb]
		set m [find_modules $path $missingmoduleslist $glibs $verb]
		#remove found modules
		set missingmoduleslist [listsub $missingmoduleslist $m]
		if {$missingmoduleslist !=""} {
			set ll [find_libs_containing_modules ./.. $missingmoduleslist $llibs $verb]
			set retlist [concat $ll $gl]
		} else {
			set retlist $gl
		}
		
	} else {
		if {$verb==1} {
			puts "cfml : not missing modules found exiting..."
		}
	}
	#search for module inside libs - return lib name
	return $retlist
} 	 

#read lib to compilation code
#input   : code - compilation command
#input   : libs - libs to add to compilation line
#output  : modified command line with additional libraries. 
proc addlibs { libs code verb} { 
	set vadlib ""
	set ocom ""
	foreach {l} $libs {
		set vadlib [format {%s -l %s } $vadlib $l]
	} 
	if {$verb==1} {
		puts [format {addlibs : you need to add %s} $vadlib]
	}
	set lcode [regexp -all -inline {\S+} $code]
	set opt0 [lindex $lcode 0]
	set opt1 [lindex $lcode 1]
	if {
		(([regexp {^[^#]} $opt0]) && 
		(($opt0=="vlog") || (($opt0=="eval") && ($opt1=="vlog"))))
	} then  { 
		foreach {opt} $lcode {
			if { $ocom !="" } {
				set ocom [format {%s %s} $ocom $opt]
			} else {
				set ocom $opt
			}
			if {
				($opt=="vlog")
			} then {
				set ocom [format {%s %s} $ocom $vadlib]
			}
		}
	} elseif {
		(([regexp {^[^#]} $opt0]) && 
		(($opt0=="vcom") || (($opt0=="eval") && ($opt1=="vcom"))))
	} then {
		set ocom $code
	}
	return $ocom
}

#read lib to compilation code
#input   : elabcode - elab command line
#output  : libraries list used in elab command. 
proc get_libs_vsim_com { elabcode verb} {
	set libs ""
	set next_is_lib 0
	set lcode [regexp -all -inline {\S+} $elabcode]
	for {set i 0} {$i < [llength $lcode]} {incr i} {
		set code [lindex $lcode $i]
		if {$verb==1} {
			puts "DBG:code $code"
		}
		if {($code=="-L")} {
			set next_is_lib 1
		} else {
			if { $next_is_lib==1 } {
				set next_is_lib 0
				lappend libs $code
			}
		}
    }
	return $libs
}

#add alll elab libraries to simulation gui option
#input   : elabcode - elab command line
#output  :  
proc gui_add_elab_libs { libs verb } {
	set l [llength $libs]
	if { $l > 0 } {
		set ocom "designverlibrarysim -L "
		for {set i 0} {$i < [llength $libs]} {incr i} {
			set code [lindex $libs $i] 
			set ocom [format {%s %s} $ocom $code]
		}
		eval $ocom
	} else {
		if {$verb==1} {
			puts "gael : no libs to add"
		}
	}
}


proc get_libs_from_elab_cmd { elabcmd } {
	set elab_libs [list]
	set next_is_lib 0
	set lcode [regexp -all -inline {\S+} $elab_cmd]
	for {set l 1} {$l < [expr [llength $lcode] - 1]} {incr l} {
		if { [lindex $lcode $l] == "-L" } {
			set next_is_lib 1
		} else {
			if {$next_is_lib==1} {
				lappend elab_libs [lindex $lcode $l]
			}
			set next_is_lib 0
		}
	}
	return $elab_libs;
}


proc add_sufix_lib  {str libs } {
	global suffix
	set next_is_lib 0
	set lcode [regexp -all -inline {\S+} $str]
	for {set l 0} {$l < [expr [llength $lcode] ]} {incr l} {
		if { [lindex $lcode $l] == "-L" } {
			set next_is_lib 1
			append ostr [lindex $lcode $l]
			append ostr " "
		} else {
			if { $next_is_lib==1} {
				if { [lindex $lcode $l] in  $libs} {
					append ostr [format "%s_%s" [lindex $lcode $l] $suffix ]  
					append ostr " "
				} else {
					append ostr [lindex $lcode $l]
					append ostr " "
				}
			} else {
				append ostr [lindex $lcode $l]
				append ostr " "
			}
			set next_is_lib 0
		}
	}
	return $ostr
}

proc elab_user { tcl_file user_lib user_top verb } { 
	#set TOP_LEVEL_NAME [new_top_level_name $tcl_file $user_lib $user_top]
	#set ELAB_OPTIONS ""
	global suffix
	global tclfile
	global userlib
	global aldec
	#set ccodes [read_com_line $tclfile $userlib 0 0]
	#set libs get_libs [ $ccodes ]
	set aldec_path [replace_slashes $aldec]
	set libs [ newlibs $tclfile $aldec_path ]
	
	if {$verb > 1} {
		puts [format "libs to add suffix to : %s " $libs]
	}
	
	set elab_cmd [read_elab_line $tcl_file 0]
	#set elab_libs get_libs_from_elab_cmd [$elab_cmd ]
	
	if {$verb>=1} {
		puts "elab_user : read elab command : "
		puts $elab_cmd
	}
	if {$elab_cmd != ""} {
		if {$user_lib != ""} {
			set lcode [regexp -all -inline {\S+} $elab_cmd]
			if {[lindex $lcode 0]=="eval"} {
				set str [format {%s} [lindex $lcode 1]]
				for {set l 2} {$l < [expr [llength $lcode] - 1]} {incr l} {
					set str [format {%s %s} $str [lindex $lcode $l]]
					if {$verb > 2} { puts $str }
				}
			} else {
				set str [format {%s} [lindex $lcode 0]]
				if {$verb > 2} { puts $str }
				for {set l 1} {$l < [expr [llength $lcode] - 1]} {incr l} {
					set str [format {%s %s} $str [lindex $lcode $l]]
					if {$verb > 2} { puts $str }
				}
			}
			
			if {$verb > 1} {
				puts [format "str to add suffix to : %s " $str]
			}
			
			set str [ add_sufix_lib  $str $libs ]
			
			set str [format {%s %s} $str "-L"]
			if {$verb > 2} { puts $str }
			set str [format {%s %s} $str $user_lib]
			if {$verb > 2} {	puts $str }
			set str [format {%s %s} $str [lindex $lcode [expr [llength $lcode] - 1]]]
			if {$verb > 2} {	puts $str } 
			if {$verb>=1} {
				puts "elab_user : elabcode with userlib :"
				puts $str
			}
			return $str
		} else {
			return $elab_cmd
		}
	}
}
#generate new QSYSSIMDIR
#input   : simdir 
#input   : tclfile_path - where tcl file is located
#input   : ahdldir - active-HDL dir
#output  : new QSYSSIMDIR
proc compose_new_simdir { simdir tclfile_path ahdldir } {
	cd $tclfile_path
	cd $simdir
	set saveddir [pwd]
	cd $ahdldir
	return $saveddir
}

#get path of tcl file
#input   : simdir 
#input   : tcl_file - ALTERA tcl file
#output  : path
proc get_path { tcl_file } {
	return [file dirname $tcl_file ]
}

#get simdir
#input		: get tclfile from arguments
#output		: QSYSSIMDIR
proc find_qsys_simdir { tcl_file verb } {
	set simdir [ read_sim_dir $tcl_file 0 ]
	set simdir_path [ get_path $tcl_file ]
	set savedir [pwd]
	if {$verb >= 1} {
		puts "find_qsys_simdir : simulation dir is $simdir"
		puts "find_qsys_simdir : simulation path is $simdir_path"
		puts "find_qsys_simdir : current working folder is $savedir"
	}
	set abs_sim_dir [ compose_new_simdir $simdir $simdir_path $savedir ]
	if {$verb >= 1} {
		puts "find_qsys_simdir : new simdir is $abs_sim_dir"
	}
	return $abs_sim_dir
}

#get path of tcl file
#input   : str - command line
#input   : newsimdir - new sim dir to replace old one
#output  : mofied coomand line
proc replace_simdir { str newsimdir } {
	return [string map {$QSYS_SIMDIR} $newsimdir $str]
}

#


#
proc add_sufix { libs } {
	global suffix
	set llibs [list]
	foreach lib $libs {
		if { $suffix != ""} {
			set lib [ string trimright $lib " "]
			lappend llibs [format "%s_%s" $lib $suffix]
		} else {
			lappend llibs $lib
		}
	}
	return $llibs
}


#test : is top compiled
alias tti {
	set sustoplib yyy
	set comline {vlog my.v -work xxx}
	if { [expr [top_iscompiled $comline $sustoplib 1]]==1} {
		puts "tti : $sustoplib is top"
	} else {
		puts "tti : $sustoplib is not top"
	}
	set comline {vlog my.v -work yyy}
	if { [top_iscompiled $comline $sustoplib 1]==1} {
		puts "tti : $sustoplib is top "
	} else {
		puts "tti : $sustoplib is not top"
	}
	unset sustoplib
	unset comline
}

#test replace_compiled_lib
alias trcl { 
	global userlib
	set comline {vlog my.v -work xxx}
	set top xxx
	set new_line [replace_compiled_lib $comline $top $userlib 1]
	puts "trcl : new compiled line is : $new_line"
	unset new_line
	unset comline
}
#test : read compilation lines
alias trcln {		
	global tclfile
	global userlib
	set lcoms [read_com_line $tclfile $userlib 0 2]
	for  {set i 0 } {$i < [llength $lcoms]} {incr i} { 
		puts "trcln : [lindex $lcoms $i]"
	}
	unset lcoms
}

#test read_elab_line
alias trel {
	puts [read_elab_line  $tclfile 1]
}

#test get elab libs 
alias tgtl {
	set l [get_libs_vsim_com "vsim -L x -L y" 1]
	for {set i 0} {$i < [llength $l]} {incr i} {
		set code [lindex $l $i]
		puts "tgtl : $code"
	}
	unset l
}

#test : read_sim_dir var
alias trsimd {	  
	global tclfile
	puts [read_sim_dir $tclfile 1 ]
}


#test : read_top_level_name
alias trdtl {	   
	global tclfile
	puts [read_top_level_name $tclfile 1 ]
}

#test : get_path
alias tgp {		  
	global tclfile
	puts [get_path $tclfile ]
}

#test : get simdir
alias tchfqs {		 
	global tclfile
	puts [find_qsys_simdir $tclfile 2]
}

#test :
alias tntln { 
	global tclfile
	puts [new_top_level_name $tclfile $userlib $usertop]
}

#test : sublists
alias tlsub {
	#need x z
	set mlibs {x y z w}
	set all_libs {a b c d e y w}
	set libs [listsub $mlibs $all_libs ]
	for {set l 0} {$l < [llength $libs]} {incr l} {
		puts [lindex $libs $l]
	}
}

#test read_copy_files
alias tccpl {
	set copy_lines [ read_copy_files $tclfile 1 ]
	for  {set i 0 } {$i < [llength $copy_lines]} {incr i} { 
		puts [lindex $copy_lines $i]
	}
	unset copy_lines
}

#test find_local_libs
alias tllibs {
	set libs [find_local_libs]
	for {set l 0} {$l < [llength $libs]} {incr l} {
		puts [lindex $libs $l]
	}
}

#test find_local_libs_libs
alias tglll {
	set aldec_path [replace_slashes $aldec]
	set libs [find_global_libs_libs $aldec_path]
	foreach {l lf} $libs {
		puts $l 
		puts $lf
	}
}

#test find_local_libs_libs
alias tflll {
	set libs [find_local_libs_libs 1]
	foreach {l lf} $libs {
		puts "tflll : $l $lf"
	}
}
#test find globla libs
alias tfgl {
	set aldec_path [replace_slashes $aldec]
	set libs [find_global_libs $aldec_path ]
	for {set l 0} {$l < [llength $libs]} {incr l} {
		puts [lindex $libs $l]
	}
}

#test : mapped libs
alias tmplibs {
	set libs [read_libraries $tclfile 2]
	for {set l 0} {$l < [llength $libs]} {incr l} {
		puts "tmplibs : [lindex $libs $l]"
	}
}

#test : get libs to generate - return none when all generated already
alias tgl {
	set aldec_path [replace_slashes $aldec]
	set generate_libs [ newlibs $tclfile $aldec_path ]
	for {set l 0} {$l < [llength $generate_libs]} {incr l} {
		puts "tgl: [lindex $generate_libs $l]"
	}
}

#test : missing modules
alias tm {
	set missingmoduleslist [get_missing_modules 1]
	for {set l 0} {$l < [llength $missingmoduleslist]} {incr l} {
		puts "tm: [lindex $missingmoduleslist $l]"
	}
}

#test libs containg the missing modules
alias tflcm { 
	global tclfile
	set aldec_path [replace_slashes $aldec] 
	set libs {altera_lnsim_ver C:/Aldec/Active-HDL-10.4-x64/vlib/intel/verilog/altera_lnsim_ver/altera_lnsim_ver.lib altera_mf_ver C:/Aldec/Active-HDL-10.4-x64/vlib/intel/verilog/altera_mf_ver/altera_mf_ver.lib altera_ver C:/Aldec/Active-HDL-10.4-x64/vlib/intel/verilog/altera_ver/altera_ver.lib arriaiigz_hssi_ver C:/Aldec/Active-HDL-10.4-x64/vlib/intel/verilog/arriaiigz_hssi_ver/arriaiigz_hssi_ver.lib arriaiigz_pcie_hip_ver C:/Aldec/Active-HDL-10.4-x64/vlib/intel/verilog/arriaiigz_pcie_hip_ver/arriaiigz_pcie_hip_ver.lib arriaiigz_ver C:/Aldec/Active-HDL-10.4-x64/vlib/intel/verilog/arriaiigz_ver/arriaiigz_ver.lib arriaii_hssi_ver C:/Aldec/Active-HDL-10.4-x64/vlib/intel/verilog/arriaii_hssi_ver/arriaii_hssi_ver.lib arriaii_pcie_hip_ver C:/Aldec/Active-HDL-10.4-x64/vlib/intel/verilog/arriaii_pcie_hip_ver/arriaii_pcie_hip_ver.lib arriaii_ver C:/Aldec/Active-HDL-10.4-x64/vlib/intel/verilog/arriaii_ver/arriaii_ver.lib arriavgz_hssi_ver C:/Aldec/Active-HDL-10.4-x64/vlib/intel/verilog/arriavgz_hssi_ver/arriavgz_hssi_ver.lib arriavgz_pcie_hip_ver C:/Aldec/Active-HDL-10.4-x64/vlib/intel/verilog/arriavgz_pcie_hip_ver/arriavgz_pcie_hip_ver.lib arriavgz_ver C:/Aldec/Active-HDL-10.4-x64/vlib/intel/verilog/arriavgz_ver/arriavgz_ver.lib arriav_hssi_ver C:/Aldec/Active-HDL-10.4-x64/vlib/intel/verilog/arriav_hssi_ver/arriav_hssi_ver.lib arriav_pcie_hip_ver C:/Aldec/Active-HDL-10.4-x64/vlib/intel/verilog/arriav_pcie_hip_ver/arriav_pcie_hip_ver.lib arriav_ver C:/Aldec/Active-HDL-10.4-x64/vlib/intel/verilog/arriav_ver/arriav_ver.lib cycloneive_ver C:/Aldec/Active-HDL-10.4-x64/vlib/intel/verilog/cycloneive_ver/cycloneive_ver.lib cycloneiv_hssi_ver C:/Aldec/Active-HDL-10.4-x64/vlib/intel/verilog/cycloneiv_hssi_ver/cycloneiv_hssi_ver.lib cycloneiv_pcie_hip_ver C:/Aldec/Active-HDL-10.4-x64/vlib/intel/verilog/cycloneiv_pcie_hip_ver/cycloneiv_pcie_hip_ver.lib cycloneiv_ver C:/Aldec/Active-HDL-10.4-x64/vlib/intel/verilog/cycloneiv_ver/cycloneiv_ver.lib cyclonev_hssi_ver C:/Aldec/Active-HDL-10.4-x64/vlib/intel/verilog/cyclonev_hssi_ver/cyclonev_hssi_ver.lib cyclonev_pcie_hip_ver C:/Aldec/Active-HDL-10.4-x64/vlib/intel/verilog/cyclonev_pcie_hip_ver/cyclonev_pcie_hip_ver.lib cyclonev_ver C:/Aldec/Active-HDL-10.4-x64/vlib/intel/verilog/cyclonev_ver/cyclonev_ver.lib fiftyfivenm_ver C:/Aldec/Active-HDL-10.4-x64/vlib/intel/verilog/fiftyfivenm_ver/fiftyfivenm_ver.lib lpm_ver C:/Aldec/Active-HDL-10.4-x64/vlib/intel/verilog/lpm_ver/lpm_ver.lib maxii_ver C:/Aldec/Active-HDL-10.4-x64/vlib/intel/verilog/maxII_ver/maxII_ver.lib maxv_ver C:/Aldec/Active-HDL-10.4-x64/vlib/intel/verilog/maxv_ver/maxv_ver.lib sgate_ver C:/Aldec/Active-HDL-10.4-x64/vlib/intel/verilog/sgate_ver/sgate_ver.lib stratixiv_hssi_ver C:/Aldec/Active-HDL-10.4-x64/vlib/intel/verilog/stratixiv_hssi_ver/stratixiv_hssi_ver.lib stratixiv_pcie_hip_ver C:/Aldec/Active-HDL-10.4-x64/vlib/intel/verilog/stratixiv_pcie_hip_ver/stratixiv_pcie_hip_ver.lib stratixiv_ver C:/Aldec/Active-HDL-10.4-x64/vlib/intel/verilog/stratixiv_ver/stratixiv_ver.lib stratixv_hssi_ver C:/Aldec/Active-HDL-10.4-x64/vlib/intel/verilog/stratixv_hssi_ver/stratixv_hssi_ver.lib stratixv_pcie_hip_ver C:/Aldec/Active-HDL-10.4-x64/vlib/intel/verilog/stratixv_pcie_hip_ver/stratixv_pcie_hip_ver.lib stratixv_ver C:/Aldec/Active-HDL-10.4-x64/vlib/intel/verilog/stratixv_ver/stratixv_ver.lib twentynm_hip_ver C:/Aldec/Active-HDL-10.4-x64/vlib/intel/verilog/twentynm_hip_ver/twentynm_hip_ver.lib twentynm_hssi_ver C:/Aldec/Active-HDL-10.4-x64/vlib/intel/verilog/twentynm_hssi_ver/twentynm_hssi_ver.lib twentynm_ver C:/Aldec/Active-HDL-10.4-x64/vlib/intel/verilog/twentynm_ver/twentynm_ver.lib altera C:/Aldec/Active-HDL-10.4-x64/vlib/intel/vhdl/altera/altera.lib altera_lnsim C:/Aldec/Active-HDL-10.4-x64/vlib/intel/vhdl/altera_lnsim/altera_lnsim.lib altera_mf C:/Aldec/Active-HDL-10.4-x64/vlib/intel/vhdl/altera_mf/altera_mf.lib arriaii C:/Aldec/Active-HDL-10.4-x64/vlib/intel/vhdl/arriaii/arriaii.lib arriaiigz C:/Aldec/Active-HDL-10.4-x64/vlib/intel/vhdl/arriaiigz/arriaiigz.lib arriaiigz_hssi C:/Aldec/Active-HDL-10.4-x64/vlib/intel/vhdl/arriaiigz_hssi/arriaiigz_hssi.lib arriaiigz_pcie_hip C:/Aldec/Active-HDL-10.4-x64/vlib/intel/vhdl/arriaiigz_pcie_hip/arriaiigz_pcie_hip.lib arriaii_hssi C:/Aldec/Active-HDL-10.4-x64/vlib/intel/vhdl/arriaii_hssi/arriaii_hssi.lib arriaii_pcie_hip C:/Aldec/Active-HDL-10.4-x64/vlib/intel/vhdl/arriaii_pcie_hip/arriaii_pcie_hip.lib arriav C:/Aldec/Active-HDL-10.4-x64/vlib/intel/vhdl/arriav/arriav.lib arriavgz C:/Aldec/Active-HDL-10.4-x64/vlib/intel/vhdl/arriavgz/arriavgz.lib arriavgz_hssi C:/Aldec/Active-HDL-10.4-x64/vlib/intel/vhdl/arriavgz_hssi/arriavgz_hssi.lib arriavgz_pcie_hip C:/Aldec/Active-HDL-10.4-x64/vlib/intel/vhdl/arriavgz_pcie_hip/arriavgz_pcie_hip.lib cycloneiv C:/Aldec/Active-HDL-10.4-x64/vlib/intel/vhdl/cycloneiv/cycloneiv.lib cycloneive C:/Aldec/Active-HDL-10.4-x64/vlib/intel/vhdl/cycloneive/cycloneive.lib cycloneiv_hssi C:/Aldec/Active-HDL-10.4-x64/vlib/intel/vhdl/cycloneiv_hssi/cycloneiv_hssi.lib cycloneiv_pcie_hip C:/Aldec/Active-HDL-10.4-x64/vlib/intel/vhdl/cycloneiv_pcie_hip/cycloneiv_pcie_hip.lib cyclonev C:/Aldec/Active-HDL-10.4-x64/vlib/intel/vhdl/cyclonev/cyclonev.lib fiftyfivenm C:/Aldec/Active-HDL-10.4-x64/vlib/intel/vhdl/fiftyfivenm/fiftyfivenm.lib lpm C:/Aldec/Active-HDL-10.4-x64/vlib/intel/vhdl/lpm/lpm.lib maxii C:/Aldec/Active-HDL-10.4-x64/vlib/intel/vhdl/maxII/maxII.lib maxv C:/Aldec/Active-HDL-10.4-x64/vlib/intel/vhdl/maxv/maxv.lib sgate C:/Aldec/Active-HDL-10.4-x64/vlib/intel/vhdl/sgate/sgate.lib stratixiv C:/Aldec/Active-HDL-10.4-x64/vlib/intel/vhdl/stratixiv/stratixiv.lib stratixiv_hssi C:/Aldec/Active-HDL-10.4-x64/vlib/intel/vhdl/stratixiv_hssi/stratixiv_hssi.lib stratixiv_pcie_hip C:/Aldec/Active-HDL-10.4-x64/vlib/intel/vhdl/stratixiv_pcie_hip/stratixiv_pcie_hip.lib stratixv C:/Aldec/Active-HDL-10.4-x64/vlib/intel/vhdl/stratixv/stratixv.lib stratixv_hssi C:/Aldec/Active-HDL-10.4-x64/vlib/intel/vhdl/stratixv_hssi/stratixv_hssi.lib stratixv_pcie_hip C:/Aldec/Active-HDL-10.4-x64/vlib/intel/vhdl/stratixv_pcie_hip/stratixv_pcie_hip.lib twentynm C:/Aldec/Active-HDL-10.4-x64/vlib/intel/vhdl/twentynm/twentynm.lib twentynm_hip C:/Aldec/Active-HDL-10.4-x64/vlib/intel/vhdl/twentynm_hip/twentynm_hip.lib twentynm_hssi C:/Aldec/Active-HDL-10.4-x64/vlib/intel/vhdl/twentynm_hssi/twentynm_hssi.lib}
	set missingmoduleslist {twentynm_io_aux}
	set path [format {%s/vlib} $aldec_path]
	set glibs [find_libs_containing_modules $path $missingmoduleslist $libs 1]
	for {set l 0} {$l < [llength $glibs]} {incr l} {
		puts "tflcm:glib [lindex $glibs $l]"
	}
	set libs {ddr_test ./../ddr_test/ddr_test/ddr_test.LIB work ./../src/work/work.lib altera_merlin_slave_translator_161 ./../src/altera_merlin_slave_translator_161/altera_merlin_slave_translator_161.lib altera_merlin_master_translator_161 ./../src/altera_merlin_master_translator_161/altera_merlin_master_translator_161.lib altera_reset_controller_161 ./../src/altera_reset_controller_161/altera_reset_controller_161.lib altera_mm_interconnect_161 ./../src/altera_mm_interconnect_161/altera_mm_interconnect_161.lib altera_avalon_onchip_memory2_161 ./../src/altera_avalon_onchip_memory2_161/altera_avalon_onchip_memory2_161.lib altera_avalon_mm_bridge_161 ./../src/altera_avalon_mm_bridge_161/altera_avalon_mm_bridge_161.lib altera_emif_cal_slave_nf_161 ./../src/altera_emif_cal_slave_nf_161/altera_emif_cal_slave_nf_161.lib altera_emif_arch_nf_161 ./../src/altera_emif_arch_nf_161/altera_emif_arch_nf_161.lib altera_emif_161 ./../src/altera_emif_161/altera_emif_161.lib ed_sim_emif_0 ./../src/ed_sim_emif_0/ed_sim_emif_0.lib altera_avalon_reset_source_161 ./../src/altera_avalon_reset_source_161/altera_avalon_reset_source_161.lib ed_sim_global_reset_n_source ./../src/ed_sim_global_reset_n_source/ed_sim_global_reset_n_source.lib ed_sim_global_reset_n_splitter ./../src/ed_sim_global_reset_n_splitter/ed_sim_global_reset_n_splitter.lib altera_emif_mem_model_core_ddr3_161 ./../src/altera_emif_mem_model_core_ddr3_161/altera_emif_mem_model_core_ddr3_161.lib altera_emif_mem_model_161 ./../src/altera_emif_mem_model_161/altera_emif_mem_model_161.lib ed_sim_mem ./../src/ed_sim_mem/ed_sim_mem.lib altera_avalon_clock_source_161 ./../src/altera_avalon_clock_source_161/altera_avalon_clock_source_161.lib ed_sim_pll_ref_clk_source ./../src/ed_sim_pll_ref_clk_source/ed_sim_pll_ref_clk_source.lib ed_sim_rzq_splitter ./../src/ed_sim_rzq_splitter/ed_sim_rzq_splitter.lib altera_emif_sim_checker_161 ./../src/altera_emif_sim_checker_161/altera_emif_sim_checker_161.lib ed_sim_sim_checker ./../src/ed_sim_sim_checker/ed_sim_sim_checker.lib altera_emif_tg_avl_161 ./../src/altera_emif_tg_avl_161/altera_emif_tg_avl_161.lib ed_sim_tg ./../src/ed_sim_tg/ed_sim_tg.lib ed_sim ./../src/ed_sim/ed_sim.lib}
	set missingmoduleslist { altera_emif_avl_tg_driver_simple altera_emif_avl_tg_driver }
	set llibs [find_libs_containing_modules ./../ $missingmoduleslist $libs 1]
	for {set l 0} {$l < [llength $llibs]} {incr l} {
		puts "tflcm:llib [lindex $llibs $l]"
	}
}

#test check_find_missing_lib
alias tcfml {  
	global tclfile
	global QSYS_SIMDIR 
	global USER_DEFINED_COMPILE_OPTIONS
	set c {eval vlog "C:/intelFPGA_pro/16.1/quartus/bin64/emif_0_example_design/sim/ed_sim/../ip/ed_sim/ed_sim_emif_0/altera_emif_arch_nf_161/sim/ed_sim_emif_0_altera_emif_arch_nf_161_tli532y_io_aux.sv" -work altera_emif_arch_nf_161}
	set aldec_path [replace_slashes $aldec]
	set lst [check_find_missing_lib $c $aldec_path $tclfile 1 0]
	for {set l 0} {$l < [llength $lst]} {incr l} {
		puts "tcfml:g [lindex $lst $l]"
	}
	set c {eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/../ip/ed_sim/ed_sim_tg/altera_emif_tg_avl_161/sim/altera_emif_avl_tg_top.sv"                                              -work altera_emif_tg_avl_161}
	set lst [check_find_missing_lib $c $aldec_path $tclfile 1 0]
	for {set l 0} {$l < [llength $lst]} {incr l} {
		puts "tcfml:l [lindex $lst $l]"
	}
	unset c
}

alias tal {
	puts "tal : [addlibs { x y } { eval  vlog  $USER_DEFINED_COMPILE_OPTIONS      "$QSYS_SIMDIR/../ip/ed_sim/ed_sim_tg/altera_emif_tg_avl_161/sim/altera_emif_avl_tg_top.sv"                                              -work altera_emif_tg_avl_161 } 1]"
}
#task :
#report if running from Active-Hdl or Riviera
#report scripting mode
#report ALDEC path
#report script path
#report userlib name
#report current QSYS_SIMDIR variable name
#report current TOP_LEVEL_NAME variable name
alias inf {	
	global tclfile
	global userlib
	clear
	set TOP_LEVEL_NAME [new_top_level_name $tclfile $userlib $usertop]
	if {$Aldec=="Active"} {
		puts "runing from active-HDL"
	} else {
		puts "runing from Riviera"
	}
	puts "active hdl path is                     : [replace_slashes $aldec]"
	puts "using INTEL Qsys script    (\$tclfile) : $tclfile"
	puts "QSYS_SIMDIR is                         : $QSYS_SIMDIR" 
    puts "TOP_LEVEL_NAME is                      : $TOP_LEVEL_NAME"
	puts "user top work lib          (\$userlib) : $userlib"
	puts "user top module is         (\$usertop) : $usertop"
	puts "library suffix                         : $suffix"
	puts "USER_DEFINED_COMPILE_OPTIONS           : $USER_DEFINED_COMPILE_OPTIONS"
    puts "USER_DEFINED_ELAB_OPTIONS              : $USER_DEFINED_ELAB_OPTIONS"
    puts "ELAB_OPTIONS                           : $ELAB_OPTIONS"
}

#tasks :
#set tcl scripting mode
#copy files
#generate libraries
alias init {  
	global QSYS_SIMDIR
	global tclfile
	#set_tcl_mode
	set copy_files [read_copy_files $tclfile 0]
	#run copy files
	for  {set i 0} {$i < [llength $copy_files]} {incr i} {
		set code [lindex $copy_files $i]
		eval $code
	}
	#generate libs 
	set aldec_path [replace_slashes $aldec]
	set generate_libs [ newlibs $tclfile $aldec_path ]
	set generate_libs [ add_sufix $generate_libs ]
	for {set l 0} {$l < [llength $generate_libs]} {incr l} {
		set code [lindex $generate_libs $l]
		vlib $code
	}
	unset copy_files
	unset aldec_path
	unset generate_libs
}

alias trpv {	
	global QSYS_SIMDIR 
	global USER_DEFINED_COMPILE_OPTIONS
	global tclfile
	global userlib
	global suffix
	
	#reed compilation lines
	set ccodes [read_com_line $tclfile $userlib 0 0]
	#replace libraries for different suffix
	if { $suffix != "" } {
		set replaced [replace_vhdl_librarirs_in_files  $ccodes 2 ]
		puts $replaced
		set ccodes [ add_suffix_ccode_to_worklib $ccodes ]
		puts $ccodes
	}
}


proc add_suffix_ccode_to_worklib { ccodes } {
	global userlib
	global suffix
	set rcodes [list]
	set pattern {(.*[\s\t]+-work[\s\t]*)([\w]*)[\s\t]*}
	for {set j 0} {$j < [llength $ccodes]} {incr j} { 
		set ccode [lindex $ccodes $j]
		if { [regexp -nocase $pattern $ccode value first second] } {
			if { $second != $userlib } {
				set second [ add_sufix_compiled_lib $second ]
			}
			set ccode [format "%s%s" $first $second] 
		}
		lappend rcodes $ccode
	}
	return $rcodes
}

#compile with libs
alias com {	
	global QSYS_SIMDIR 
	global USER_DEFINED_COMPILE_OPTIONS
	global tclfile
	global userlib
	global suffix
	
	set ofilename $comsout
	#reed compilation lines
	set ccodes [read_com_line $tclfile $userlib 0 0]
	#replace libraries for different suffix
	if { $suffix != "" } {
		set replaced [replace_vhdl_librarirs_in_files  $ccodes 0 ]
		set ccodes [ add_suffix_ccode_to_worklib $ccodes ]
	}
	#-work tllib
	set fileId [open $ofilename "w"]
	close $fileId
	set aldec_path [replace_slashes $aldec]
	for {set j 0} {$j < [llength $ccodes]} {incr j} { 
		set ccode [lindex $ccodes $j]
		set libs [check_find_missing_lib $ccode $aldec_path $tclfile 1 0] 
		set scode [addlibs  $libs $ccode 0] 
		eval $scode
		set scode [string map [list {$QSYS_SIMDIR} $QSYS_SIMDIR] $scode]
		set scode [string map [list {$USER_DEFINED_COMPILE_OPTIONS} $USER_DEFINED_COMPILE_OPTIONS] $scode]
		set fileId [open $ofilename "a"]
		puts -nonewline $fileId $scode
		puts $fileId \r\n
		close $fileId
		
	}
	unset ofilename
	unset ccodes
	unset fileId
	unset ccode
	unset aldec_path
}


#run script elab command
alias elab {  
	global TOP_LEVEL_NAME
	global ELAB_OPTIONS
	global tclfile
	global userlib
	#set TOP_LEVEL_NAME [new_top_level_name $tclfile $userlib $usertop]
	set out [elab_user $tclfile $userlib $usertop 2]
	eval $out
	set ofilename $elabsout
	set out [string map [list {$TOP_LEVEL_NAME} $TOP_LEVEL_NAME] $out]
	set out [string map [list {$ELAB_OPTIONS} $ELAB_OPTIONS] $out]
	set fileId [open $ofilename "w"]
	puts -nonewline $fileId $out
	close $fileId
}

#add Verilog simulation libraries to aldec settings in gui 
alias gui_sim_libs {
	global tclfile
	set str [read_elab_line $tclfile 0]
	set libs [get_libs_vsim_com  $str 0]
	gui_add_elab_libs $libs 0
	unset str
	unset libs
}

alias init_vars {
	global QSYS_SIMDIR
	global TOP_LEVEL_NAME
	global USER_DEFINED_COMPILE_OPTIONS
	global USER_DEFINED_ELAB_OPTIONS
	global ELAB_OPTIONS
	set QSYS_SIMDIR [find_qsys_simdir $tclfile 0]
	set TOP_LEVEL_NAME [new_top_level_name $tclfile $userlib $usertop]
	set USER_DEFINED_COMPILE_OPTIONS ""
	set USER_DEFINED_ELAB_OPTIONS ""
	set ELAB_OPTIONS ""	
}
#init

alias h {
	clear
	puts "com				- compile command with verilog libs (generatets the file comps.do)"
	puts "elab				- run elab command (generatets the file elabs.do)"
	puts "gui_sim_libs		- add elaboration libraries to simulation settings in Active-HDL gui."
	puts "inf				- info"
	puts "sdo				- put scripting to do mode"
	puts "stcl				- put scripting to tcl mode"
	puts "init_vars			- initialised QSYS variables"
	puts "init				- generated libs and copy files"
	puts "h					- help  (autoexecuted)"
}	 
h
