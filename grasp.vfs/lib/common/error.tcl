# set default settings. Make sure not to overwrite if already set (e.g. if already loaded)
trySet Settings(emailWarning) 0

namespace eval ::error {
  proc wrongArguments {expected {option ""}} {
    switch -- $option {
      option_plus {
        set option "option ?arg arg ...?"
      }
      "" {}
      default {
        set option " $option"
      }
    }
  
    set message "wrong # args: should be \"$expected$option\""
    error $message $message
  }
  
  proc warning {message args} {
    global Settings
    
    # set defaults
    set email $Settings(emailWarning)
  
    parseArgs $args {email}
  
    global argv0
    log "$argv0: WARNING $message"
    
    if {$email} {
      email mike@holenderski.com {Error} $message
    }
  }
  
  proc fatal {message args} {
    set email 1
    
    parseArgs $args {email}
    
    error "FATAL $message" "FATAL: $message"

    if {$email} {
      email mike@holenderski.com {Error} $message
    }
  }
  
  proc return {message} {
    uplevel error::fatal $message
  }
}
