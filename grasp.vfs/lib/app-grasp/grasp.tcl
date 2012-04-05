# print the version number
switch $::tcl_platform(platform) {
  windows {}
  default {
    puts "Welcome to Grasp (version $::grasp_version)"
  }
}

# set the home directory to the directory containing the executable
set homeDir [file dirname [file dirname [file dirname [file dirname [info script]]]]]
set pluginsDir $homeDir/plugins

# defaults
set postscript ""
set plugins ""
set legend_items {taskActive taskHoldingMutex taskPreempted taskArrived taskDeadline}
set ignore ""
set ignore_missing 1
set ignore_api 0
set legend none
set exit 0
set viewCollapsed 0
set viewPreemptionLines 1
set viewMessages 1
set settings ""
set defaultSettings [file join $homeDir settings.txt]
set help ""
set commandArgs {h help}

addTraceFormat auto autoTraceFormat
addTraceFormat grasp ""
set format auto

# load Tk
package require Tk 

# hide the main window. All plots will be drawn in a separate window
wm withdraw .

# load plugins from the plugins directory (if any)
if {[file exists $pluginsDir]} {
  foreach plugin [glob -directory $pluginsDir *tcl] {
    source $plugin
  }
}

addCommandArg settings "file" "file name of the settings file to override the default visualisation settings, such as colors and dimensions of tasks."
addCommandArg format [join [array names traceFormats] " | "] "input trace format. The auto format tries to deduce the format from the file extension."
addCommandArg postscript "file" "if this option is specified, then the plot will be written to the postscript file with the given file name"
addCommandArg plugins "'path path ...'" "file name of the tcl script, which is going to perform analysis on the trace"
addCommandArg ignore "list" "list of strings 'string string ...' to be ignored. All tasks and servers with an id containing any these strings will not be shown."
addCommandArg ignore_missing "bool" "boolean (i.e. 0 or 1) specifying whether to ignore unimplemented Plot events."
addCommandArg legend "side" "where to print a legend. Has to be either 'none', 'right' or 'bottom'."
addCommandArg legend_items "list" "list of strings 'string string ...' specifying the legend items to print in the legend. The proper legend items are: [join $legend_items ", "]."
addCommandArg ignore_api "bool" "boolean (i.e. 0 or 1) specifying whether to enable the 'ignore' command in the trace files (if 0 then the 'ignore' command has no effect)."
addCommandArg exit "bool" "boolean (i.e. 0 or 1) specifying whether to quit grasp after it has plotted the trace. This option can be useful if grasp is used in batch processing of many traces."

# check the input arguments
if {[lindex $argv 0] eq "--h" || [lindex $argv 0] eq "--help"} {
  puts "\nusage: grasp ?options? <trace file>"
  puts "\noptions:"
  printHelpOptions $help
  _exit
  return
}

# check options, if any
if {[llength $argv] > 1} {
  if {[catch {parseArgs [lrange $argv 0 end-1] $commandArgs} err]} {
    puts $err
    _exit
    return
  }
}

# check again, if the -h option was specified inside as an option (after the filename)
if {[info exists h]} {
  puts "\nusage: $argv0 ?options? <trace file>"
  puts "\noptions:"
  printHelpOptions $help
  _exit
  return
}

# laod the settings (overwriting defaults)
if {[llength $settings]} {
  loadSettings -file $settings
} else {
  loadSettings -file $defaultSettings -silent 1
}

# setup the default font
set fontFamily "-family [list [font configure TkDefaultFont -family]]"
if {[llength $::Settings(font.family)]} {
  set fontFamily "-family $::Settings(font.family)"
}
set fontSize "-size [font configure TkDefaultFont -size]"
if {[llength $::Settings(font.size)]} {
  set fontSize "-size $::Settings(font.size)"
}

eval font configure TkDefaultFont $fontFamily $fontSize
eval font create TkDefaultFontBold $fontFamily $fontSize -weight bold

# ignore those tasks to be ignored
if {[info exists ignore]} {
  Plot set ignore $ignore
}

# check if 'ignore' should be ignored
set ::Settings(ignore_api) $ignore_api

# ignore unimplemented events
Plot set ignoreMissing $ignore_missing

# load plugins from the command line (if any)
if {[llength $plugins]} {
  foreach plugin $plugins {
    source $plugin
  }
}

# load default settings for plots
set ::Settings(plot::legend) $legend
set ::Settings(plot::legendItems) $legend_items

# setup collapsed toggle in the view menu, to correspond to the Settings
set viewCollapsed [string match $::Settings(plot.tasks) "collapsed"]
 
# open the trace
if {[llength $::argv]} {
  openTrace [lindex $::argv end]
} else {
  openTrace ""
}

# dump the main plot to a postscript file
if {[llength $postscript]} {
  # check how many plots we have
  set plots [getAllInstancesOf Plot] 
  if {[llength $plots] == 1} {
    # if there is only one plot, then print it to the supplied name
    [lindex $plots 0] writeToFile $postscript
  } else {
    set prefix [file root $postscript]
    set postfix [file extension $postscript]
    foreach plot $plots {
      $plot writeToFile "$prefix [$plot title]$postfix"
    }
  }
}

# check if we should exit immediately, used for generating postscript from command line
if {$exit} {
  exit 0
}

