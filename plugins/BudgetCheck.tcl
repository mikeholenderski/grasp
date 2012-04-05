
#
# Exit with error code 100 if the budget of a server was exceeded
#

# allow to disable budget checking from the command line
set checkBudget warning
addCommandArg checkBudget "no | warning | exit" "if this option is specified, then verify that servers never exceed their budgets. When a server exceeds its budget than only show a warning, or show a warning and exit."

# register handlers for server events
addEventHandler serverReplenished "BudgetCheck::check"
addEventHandler serverResumed "BudgetCheck::check"
addEventHandler serverPreempted "BudgetCheck::check"
addEventHandler serverDepleted "BudgetCheck::check"

namespace eval BudgetCheck {
  proc check {time server args} {
    if {$::checkBudget ne "no"} {
      if {[$server budget] < 0} {
        puts "server '$server' exceeded its budget at time $time"
        if {$::checkBudget eq "exit"} { _exit 100 }
      }
    }
  }
}
