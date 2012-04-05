#
# Print a warning message.
#

proc warning {message} { puts $message }

#
# manage the command line arguments
#

proc addCommandArg {arg syntax help} {
  lappend ::commandArgs $arg
  set default [set ::$arg]
  if {[string is double $default] && [llength $default]} {
    append help " (Default $default)"
  } else {
    append help " (Default '$default')"
  }
  lappend ::help "--$arg $syntax" $help
}

#
# Add and remove an event handler for Grasp Player events
#

proc addHandler {event script} {
  bind . <<$event>> "+$script"
}

proc removeHandler {event pattern} {
  set event <<$event>>
  set allHandlers [bind . $event]
  set handlers {}
  foreach handler [split $allHandlers \n] {
    if {![regexp $pattern $handler]} {
      lappend handlers $handler
    }
  }
  bind . $event [join $handlers \n]
}

array set eventHandlers {}

proc addEventHandler {event command} {
  array set ::eventHandlers [list $event $command]
}

#
# Trace preprocessor has the following signature: proc x {inFileName} { ... return $outFileName }
# 
#

array set traceFormats {}

proc addTraceFormat {format command} {
  array set ::traceFormats [list $format $command]
}

#
# Auto trace format selects the format based on the extension, or grasp otherwise
#

proc autoTraceFormat {fileName} {
  set traceFileName $fileName
  set format [string trimleft [file extension $fileName] "."]
  
  if {[info exists ::traceFormats($format)]} {
    set preprocessor $::traceFormats($format)
    if {[llength $preprocessor]} {
      set traceFileName [$preprocessor $fileName]
    }
  }
  
  return $traceFileName
}

#
# Add a trace preprocessor to the global list of preprocessors
#

set preprocessors {}

proc addPreprocessor {f} {
  lappend ::preprocessors $f
}

#
# View menu commands
#

proc toggleCollapsed {} {
  if {!$::viewCollapsed} {
    set ::Settings(plot.tasks) "expanded"
    set ::viewCollapsed 0
  } else {
    set ::Settings(plot.tasks) "collapsed"
    set ::viewCollapsed 1
  }

  # reload the trace
  openTrace $::traceFileName
}

proc togglePreemptionLines {} {
  if {!$::viewPreemptionLines} {
    foreach plot [Plot info instances -closure] {
      [$plot c] itemconfig preemptionline -state hidden
    }
    set $::viewPreemptionLines 0
  } else {
    foreach plot [Plot info instances -closure] {
      [$plot c] itemconfig preemptionline -state normal
    }
    set $::viewPreemptionLines 1
  }
}

proc toggleMessages {} {
  if {!$::viewMessages} {
    foreach plot [Plot info instances -closure] {
      [$plot c] itemconfig message -state hidden 
    }
    set $::viewMessages 0
  } else {
    foreach plot [Plot info instances -closure] {
      [$plot c] itemconfig message -state normal 
    }
    set $::viewMessages 1
  }
}

proc showAbout {} {
  tk_messageBox -title About \
    -message "Grasp" \
    -detail "Version $::grasp_version\n\nBy Mike Holenderski\nContact mike@holenderski.com"
}

set menus {}

# setup the menu
proc createMenu {} {
  Analysis createMenu

  set windows .
  foreach plot [RealtimePlot info instances -closure] {
    # each plot id has the shape "::window.plot". We want to strip the trailing .plot, and leading ::
    set w .[string trimleft [string range $plot 0 end-5] ":"]
    lappend windows $w
  }
  
  foreach w $windows {
    if {$w eq "."} { set W "" } else { set W $w }

    menu $W.menu
    $w config -menu $W.menu
    
    menu $W.menu.file -tearoff 0
    $W.menu add cascade -label File -menu $W.menu.file
    $W.menu.file add command -label "Open ..." -command {openTrace ""}
    $W.menu.file add command -label "Print to file ..." -command {$selectedPlot writeToFile ""}
    if {$::tcl_platform(os) ne "Darwin"} {
      $W.menu.file add command -label "Exit" -command exit
    }
    
    menu $W.menu.view -tearoff 0
    $W.menu add cascade -label View -menu $W.menu.view
    $W.menu.view add checkbutton -label "Collapsed" -command "toggleCollapsed" -variable viewCollapsed
    $W.menu.view add checkbutton -label "Preemption lines" -command "togglePreemptionLines" -variable viewPreemptionLines
    $W.menu.view add checkbutton -label "Messages" -command "toggleMessages" -variable viewMessages
    
    
    menu $W.menu.tools -tearoff 0
    $W.menu add cascade -label Tools -menu $W.menu.tools

    menu $W.menu.windows -tearoff 0
    $W.menu add cascade -label Windows -menu $W.menu.windows
    $W.menu.windows add command -label "Tile vertically" -command "tileWindowsVertically"
    $W.menu.windows add command -label "Tile horizontally" -command "tileWindowsHorizontally"
    $W.menu.windows add separator

    menu $W.menu.help -tearoff 0
    $W.menu add cascade -label Help -menu $W.menu.help
    $W.menu.help add command -label "About" -command "showAbout"
    
    set menu $W.menu
    foreach command $::menus {
      eval $command
    }
  }
}

#
# Window manager
#

proc addWindow {w title} {
  set menu {
    \$menu.windows add checkbutton -label "$title" -command "toggleWindow $w" -variable ::$w.visible
  }
  lappend ::menus [subst $menu]
  
  set ::$w.visible 1
  
  lappend ::windows $w

  wm protocol $w WM_DELETE_WINDOW "toggleWindow $w"
}

proc toggleWindow {w} {
  if {[winfo viewable $w]} {
    wm withdraw $w
    set ::$w.visible 0
  } else {
    wm deiconify $w
    set ::$w.visible 1
    raise $w
  }
  
  # on windows/linux, if none of the grasp windows is visible, then exit
  if {$::tcl_platform(os) ne "Darwin"} {
    set visible 0
    foreach window $::windows {
      if {[set ::$window.visible]} {
        set visible 1
        break
      }
    }
    
    if {!$visible} { exit }
  }
}

proc tileWindowsVertically {} {
  set offset 22
  set width [expr [winfo screenwidth .] / [llength $::windows]]
  set height [expr [winfo screenheight .] - 2*$offset]

  for {set i 0} {$i < [llength $::windows]} {incr i} {
    wm geometry [lindex $::windows $i] ${width}x${height}+[expr $i*$width]+$offset
  }
}

proc tileWindowsHorizontally {} {
  set offset 22
  set width [winfo screenwidth .]
  set height [expr ([winfo screenheight .] - (1+[llength $::windows])*$offset) / [llength $::windows]]

  for {set i 0} {$i < [llength $::windows]} {incr i} {
    wm geometry [lindex $::windows $i] ${width}x${height}+0+[expr $offset + $i*($offset+$height)]
  }
}

#
# Reset Grasp, making it ready to load a new trace.
#

proc resetGrasp {} {
  # destroy all the plots
  if {[info exists ::windows]} {
    foreach w $::windows { destroy $w }
  }
  set ::windows {}
  update
  
  # destroy the menu in the main window, since it is hidden and not included above
  catch { destroy .menu }
  unset ::menus
  
  Plot reset
  event generate . <<PlotReset>>
  update
  
  set ::maxTime 0
}

#
# Open a new trace
#

proc openTrace {fileName} {
  
  resetGrasp

  # check if should show the open file dilogue (no arguments)
  global traceFileName
  if {[llength $fileName]} {
    set traceFileName $fileName
  } else {
    # get the file name via a dialogue
    set traceFileName [tk_getOpenFile -title "Choose a trace file ..." -initialdir $::homeDir]
  }
  
  # check the trace file (first argument)
  if {![file exists $traceFileName]} {
    puts "file '$traceFileName' does not exist"
    _exit
    return
  }
  
  # do some preprocessing, if requested
  if {![llength [array get ::traceFormats $::format]]} {
    puts "unknown trace format '$::format'"
    _exit
    return
  }
  
  set preprocessor $::traceFormats($::format)
  if {[llength $preprocessor]} {
    set traceFileName [$preprocessor $traceFileName]
    set ::format grasp
  }
  
  # load the plot. Note that to allow preprocessing, we cannot simply source the trace
  set channel [open $traceFileName r]
  set trace [read $channel]
  close $channel
  
  foreach preprocessor $::preprocessors {
    set trace [$preprocessor $trace]
  }
  
  eval $trace
  
  # finish up
  update
  event generate . <<TraceFinished>>
  update
  event generate . <<TraceLoaded>>
  
  createMenu
  update
}

#
# In case we are using windows, redirect all puts to stdout to a window
#

if {$tcl_platform(os) eq "Windows NT"} {
  # we will overwrite the puts command to print to a new window, and so rename original for
  # priting to files
  rename puts putsOld
  
  proc createPutsWindow {w} {
    toplevel $w -bg white
    wm title $w "Info"
    wm protocol $w WM_DELETE_WINDOW "doexit $w"
    
    text $w.text -font TkFixedFont -relief flat \
      -yscrollcommand "$w.vscroll set"

    button $w.ok -text "OK" -command "doexit $w"

    # create scroll bars
    scrollbar $w.vscroll -orient vertical -command "$w.text yview"
    
    # allign these in a grid
    grid $w.text -in $w -padx 30 -pady 1 -row 0 -column 0 -rowspan 1 -columnspan 1 -sticky news
    grid $w.vscroll -in $w -padx 1 -pady 1 -row 0 -column 1 -rowspan 1 -columnspan 1 -sticky news
    grid $w.ok  -pady 10
    grid rowconfig $w 0 -weight 1 -minsize 0
    grid columnconfig $w 0 -weight 1 -minsize 0
    
    update
  }
  
  # redefine puts
  proc puts {args} {
    if {[llength $args] == 1 || ([llength $args] == 2 && [lindex $args 0] eq "-nonewline")} {
      # check if created the ouput window
      if {![winfo exists .puts]} { createPutsWindow .puts}

      # write to the window
      if {[llength $args] == 1} {
        .puts.text insert end "[join $args]\n"
      } else {
        .puts.text insert end [lindex $args 1]
      }
    
    } else {
      eval putsOld $args
    }
  }
  
  set needToExit 0
  proc doexit {w} {
    if {$::needToExit} {
      exit
    } else {
      destroy $w
    }
  }
  
  proc _exit {args} { set ::needToExit 1 }
} else {
  proc _exit {args} {
    if {[llength $args]} {
      exit $args
    } else {
      exit
    }
  }
}

#
# The global maxTime variable keeps track of the largest event time.
#

set maxTime 0

proc updateMaxTime {time} {
  if {$::maxTime < $time} {
    set ::maxTime $time
  }
}
