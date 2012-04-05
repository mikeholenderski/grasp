package require smtp
package require mime  

# some defaults
set Settings(emailSupport) 1

#
# Send an email.
#

proc email {to subject body} {
  global Settings

  # make sure to call only if email support, otherwise will stall on some internal vwait
  if {$Settings(emailSupport)} {
    set token [mime::initialize -canonical text/plain -string $body]
    mime::setheader $token Subject $subject
    # -header "From mike@stack.nl"
    if {[catch {
      smtp::sendmessage $token -recipients $to -servers mailhost.tue.nl 
    }]} {
      ::error::warning "could not email '$subject' to $to"
    }
    
    mime::finalize $token
  }
}
