
#
# Exit with error code 200 if job is trying to release a mutex which it has not aquired.
# Exit with error code 201 if job is trying to release a mutex in non-nested order.
#

# allow to disable nested checking from the command line
set checkMutex warning
addCommandArg checkMutex "no warning | exit" "if this option is specified, then check if mutexes are nested properly. If they are not, then only show a warning, or show a warning and exit."

# register handlers for acuiring and releasing mutexes
addEventHandler jobAcquiredMutex "MutexCheck::jobAcquiredMutex"
addEventHandler jobReleasedMutex "MutexCheck::jobReleasedMutex"

namespace eval MutexCheck {
  set acquired {}

  proc jobAcquiredMutex {time job mutex} {
    if {$::checkMutex ne "no"} {
      variable acquired
      lappend acquired $job.$mutex
    }
  }
  
  proc jobReleasedMutex {time job mutex} {
    if {$::checkMutex ne "no"} {
      variable acquired
      set i [lsearch $acquired $job.$mutex]
      if {$i == -1} {
        puts "job '$job' trying to release mutex '$mutex' which it has not acquired before"
        if {$::checkMutex eq "exit"} { _exit 200 }
      }
      if {[regexp $job [lrange $acquired [expr $i + 1] end]]} {
        puts "wrong mutex nesting at time $time ('$job' trying to release '$mutex')"
        if {$::checkMutex eq "exit"} { _exit 201 }
      }
      set acquired [lreplace $acquired $i $i]
    }
  }
}
