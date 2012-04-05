
package ifneeded app-plot 1.0 "
  package require XOTcl
  namespace import ::xotcl::*
  package require common
  
  
  # load the default settings, embedded in the package
  loadSettings -file [list [file join $dir settings.txt]]
  
  source [list [file join $dir version.tcl]]
  source [list [file join $dir bitmaps.tcl]]
  source [list [file join $dir utils.tcl]]
  source [list [file join $dir Queue.xotcl]]
  source [list [file join $dir Plot.xotcl]]
  source [list [file join $dir Plot.tooltip.xotcl]]
  source [list [file join $dir Plot.draw.xotcl]]
  source [list [file join $dir Job.xotcl]]
  source [list [file join $dir Task.xotcl]]
  source [list [file join $dir Mutex.xotcl]]
  source [list [file join $dir Semaphore.xotcl]]
  source [list [file join $dir Server.xotcl]]
  source [list [file join $dir Analysis.xotcl]]
  source [list [file join $dir Multiprocessor.xotcl]]

  source [list [file join $dir controls.tcl]]
  source [list [file join $dir grasp.tcl]]

  package provide app-plot 1.0
"
