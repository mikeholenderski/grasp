#
# 
#

proc max {a b} {
  if {$a < $b} {
    return $b
  } else {
    return $a
  }
}
proc min {a b} {
  if {$a < $b} {
    return $a
  } else {
    return $b
  }
}


#
# round off a float to m decimals, where m is the number of zeros in n
#

proc roundOff {x {n 1000}} { expr round($x*$n)/$n.0 }

#
# round off a float to n decimals 
#

proc roundOff {x {n 3}} { format %.${n}f $x }

#
# Multi line comments
#

proc %%% {comment %%%} {
  if {[set %%%] ne "%%%"} { error "missing end of comment %%%" }
}

#
# set the value of target to the value of source (if source exists)
# or to a default value (if source does not exist)
#

proc setDefault {target source default} {  
  if {[eval uplevel {info exists $source} ]} {
    eval uplevel {set $target [eval uplevel {set $source}]}
  } else {
    eval uplevel {set $target $default}
  } 
}

#
# set target to value, if not already set
#

proc trySet {target value} {
  eval uplevel {setDefault $target $target $value}
}

proc checkArgs {submitted allowed} {
  foreach {key value} $submitted {
    if {[lsearch $allowed $key] == -1} {
      error "unknown option $key"
    }
  }
}

proc removeArgs {all obsolete} {
  foreach arg $obsolete {
    regsub (-*$arg\ \[^\ \]+) $all {} all
  }

  return $all
}

proc parseArgs {submitted allowed {strict -strict}} {
  foreach {key value} $submitted {
    # strip leading "-"
    while {[string match [string index $key 0] "-"]} {
      set key [string range $key 1 end]
    }
    # check if arg is allowed
    if {[lsearch $allowed $key] > -1} {
      uplevel [list set $key $value]
    } else {
      switch -- $strict {
        -strict { error "unknown option '-$key'" }
        -notstrict {}
        default { error "unknown argument '$strict'" }
      }
    }
  }
}

proc printHelpOptions {options args} {
  set keyWidth 20
  set spaceWidth 3
  set descriptionWidth 57
  
  # stretch the width to fit the terminal, if possible
  catch {
    foreach {x y} [exec stty size] break
    set descriptionWidth [expr $y - $keyWidth - $spaceWidth]
    if {$descriptionWidth < 0} { set descriptionWidth $keyWidth }
  }
  
  parseArgs $args {keyWidth spaceWidth descriptionWidth}
  
  foreach {key description} $options {
    # print the key
    puts -nonewline $key
    
    if {[string length $key] > $keyWidth} {
      # break line if key is too long
      puts " :"
      for {set i 0} {$i < $keyWidth + $spaceWidth} {incr i} {
        puts -nonewline " "
      }
    } else {
      # pad the key with spaces otherwise
      for {set i [string length $key]} {$i < $keyWidth} {incr i} {
        puts -nonewline " "
      }
      puts -nonewline " : "
    }
    
    # print the description
    while {[llength $description]} {
      if {[string length $description] <= $descriptionWidth} {
        set end $descriptionWidth
      } else {
        set end [expr [string wordstart $description $descriptionWidth] - 1]
      }
      set line [string range $description 0 $end]
      set description [string replace $description 0 $end]
      puts [string trim $line]
      for {set i 0} {$i < $keyWidth + $spaceWidth} {incr i} {
        puts -nonewline " "
      }
    }
    puts ""
  }
}

#
# parse command line arguments into the Settings global variable
#
# Optional:
# -variable name : name of the array where to store the values, otherwise set in the parent scope

proc parseArgv {allowed args} {
  global argv
  
  set startIndex 0
  set stopIndex end
  set strict strict
  
  parseArgs $args {startIndex stopIndex variable strict}
  
  # allowed commandline options
  set default {log settings debug}
  
  parseArgs [lrange $argv $startIndex $stopIndex] [concat $allowed $default] -$strict

  foreach option $allowed {
    if {[info exists $option]} {
      if {[info exists variable]} {
        uplevel "set ${variable}($option) [set $option]"
      } else {
        uplevel "set $option [set $option]"
      }
    }
  }
}

set LOG 1

# get the log file name
if {[info exists argv]} {
  foreach {key value} $argv {
    if {$key=="-log"} {
      set Settings(logFileName) $value
    }
  }
}

proc log {message args} {
  global Settings LOG
  
  set trace 0
  
  parseArgs $args {file trace}
  
  if {[info exists Settings(logTime)] && $Settings(logTime)} {
    # add the time  to the message
    set message "[clock format [clock seconds] -format "%Y.%m.%d %H:%M:%S"] $message"
  }
  # add trace, if enabled
  if {$trace} {
    global errorInfo
    catch {error ""}
    append message "$errorInfo"
  }
  
  if {[info exists file]} {
    set logChannel [open $file a+]
    puts $logChannel $message
    close $logChannel  
    
  } elseif {[info exists Settings(logFileName)] && $LOG} {
    if {[llength $Settings(logFileName)]} {
      # open and close log file on each log message, to make sure it is written if something breaks
      set logChannel [open $Settings(logFileName) a+]
      puts $logChannel $message
      close $logChannel
    } else {
      error::warning "Settings(logFileName)=''"
    }
  } elseif {$LOG} {
    puts $message
  }
}

proc enableLog {} {
  global LOG  
  set LOG 1
}

proc disableLog {} {
  global LOG
  set LOG 0
}

proc enableDebug {} {
  global Settings 
  set Settings(debug) 1
}

proc disableDebug {} {
  global Settings
  set Settings(debug) 0
}

proc debug {message} {
  global Settings
  
  if {[info exists Settings(debug)] && $Settings(debug)} {
    log $message
  }
}

proc darray {arrayName} {
  global Settings
  
  if {[info exists Settings(debug)] && $Settings(debug)} {
    uplevel parray $arrayName
  }
}

#
# Load the settings from a file. Each line in the file is either:
# - a pair of key and value, separated by a space
# - starts with a # sign, in which case it is ignored
#
# Options:
# -overwrite 1 | 0 : overwrite settings from the file with command line 
#                    arguments (default: 1)
# -variable name   : name of the variable (in the scope of the caller) where 
#                    to store the settings (default: Settings)
# -file name       : name of the file contiaing the settings (default: settings.txt)
#

proc loadSettings {args} {
  # default settings
  set variable ::Settings
  set file {settings.txt}
  # overwrite with command line arguments
  set overwrite 0
  set silent 0

  parseArgs $args {overwrite variable file silent}
  
  if {$overwrite} {
    global argv
    
    foreach {key value} $argv {
      # strip leading "-"
      if {[string match [string index $key 0] "-"]} {
        set key [string range $key 1 end]
      }
      array set commandlineArgs "$key $value"
    }
  }
  
  # overwrite the settings fiel itself with command line argumetn, if any
  if {[info exists commandlineArgs(settings)]} {
    set file $commandlineArgs(settings)
  }

  if {[file exists $file]} {
    set settings [read [open $file r]]
  } else {
    if {!$silent} { puts "trying to load settings from '$file', but it does not exist" }
    return
  }
  
  # remove comments
  set settings [regsub -all -lineanchor -- {^#.*?\n} $settings ""]

  # load into the global variable
  uplevel [list array set $variable $settings]

  # overwrite with command line arguments
  if {$overwrite} {
    array set s $settings
    foreach {key value} [array get commandlineArgs] {
      if {[info exists s($key)]} {
        log "overwriting ${variable}(${key}) with $value"
        uplevel "set ${variable}(${key}) $value"
      }
    }
  }
}


#
# Print a help message if -h was passed as the first commandline argument.
#

proc printHelpMessage {message} {
  global argv
  
  if {[string match [lindex $argv 0] -h]} {
    puts $message
    exit
  }
}

#
# Schedule a task. Must specify -period or -nextCommand
# 
# Optional arguments:
# -period seconds : length of the period (in seconds)
# -nextCommand command : a function which will return the next ABSOLUTE time (in seconds).
#

proc schedule {task args} {
  global scheduledTasks
  
  set execute 0
  set id unknown
  parseArgs $args {nextCommand period execute id}
  
  if {[info exists nextCommand]} {
    set now [clock seconds]
    set next [eval $nextCommand]

    set afterID [after [expr 1000*($next - $now)] [list schedule $task -id $id -nextCommand $nextCommand -execute 1]]
    
    log "scheduled '$task' (id=$afterID) after [expr ($next - $now)/60] minutes"
  
  } elseif {[info exists period]} {
    set afterID [after [expr 1000*$period] [list schedule $task -id $id -period $period -execute 1]]    
  } else {
    ::error::fatal "Must specifiy nextCommand or period."
  }
  
  if {$id=="unknown"} {
    # append surrent task id to the list of unkown tasks
    lappend scheduledTasks($id) $afterID
  } else {
    set scheduledTasks($id) $afterID
  }
  
  # possibly execute the task
  if {$execute} {
    eval $task  
  }
  
  return $id
}

proc unschedule {args} {
  global scheduledTasks

  parseArgs $args {all id}
  
  if {[info exists all]} {
    # stop all tasks in the scheduledTasks queue
    foreach {x tasks} [array get scheduledTasks] {
      foreach task $tasks {
        after cancel $task
        log "unscheduled $task"
      }
    }
    array unset scheduledTasks
    
  } elseif {[info exists id]} {
    foreach {x tasks} [array get scheduledTasks $id] {
      foreach task $tasks {
        after cancel $task
        log "unscheduled $task"
      }
    }    
    array unset scheduledTasks $id
  }
}

#
# Start a pertiodic task. Keep repeating until the stopAction called.
#
# action : script which is to be executed. Note that starting the same script repeatedly will only
#          change the period and phasing (i.e. it will not start a concurrent instance of the same 
#          action).
#
# Optional:
# -period : period length in seconds, if 0 then do nothing (default: 0)
#

proc startAction {action args} {
  global stop#$action
  if {[info exists stop#$action]} {
    unset stop#$action
  } else {
    set period 0
    
    parseArgs $args {period}
 
    global running#$action
    set running#$action 1
    
    if {$period > 0} {
      debug "setup to execute '$action' after $period seconds"
      after [expr $period * 1000] "startAction [list $action] $args"
    }    
    
    eval $action
  }
}

#
# Stop a periodic task, which was previousely started with startAction.
#
# action : script which was started with startAction
#
# Optional:
#  -seconds ...
#

proc stopAction {action args} {
  # make sure that the action to be stopped is indeed running
  global running#$action
  if {[info exists running#$action]} {
    unset running#$action
  } else {
    ::error::fatal "action \"$action\" is not running"
  }
  
  set seconds 0
  set hours 0
  set minutes 0
  set time relative
  
  parseArgs $args {time seconds minutes hours}
  
  global $action
  
  switch -- $time {
    now {
      set $action 1
      return
    }
    absolute {
      set delay [expr ($seconds + $minutes*60 + $hours*60*60 - [clock seconds])]
    }
    relative {
      set delay [expr ($seconds + $minutes*60 + $hours*60*60)]
    }
    default {
      puts "unknown time: $time"
      return 
    }
  }
  
  if {$delay >= 0} {
    puts "stopping after $delay seconds"
    after [expr $delay*1000] "set [list stop#$action] 1"
  } else {
    set $action 1
  }
}

#
# Check if an object belongs to a class (XOTcl)
#

proc checkClass {object class} {
  if {![llength $object]} {
    error "empty object, when testing for $class"
  }
  if {![llength $class]} {
    error "empty class, when testing object $object"
  }

  if {![llength [$class info instances $object]]} {
    if {[lsearch [[$object class] info heritage] [$class] ] == -1} {
      error "'$object' is not an instance of $class"
    }
  }
  
  return
}