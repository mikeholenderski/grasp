
package ifneeded common 1.0 "
  source [list [file join $dir common.tcl]]
  source [list [file join $dir error.tcl]]
  source [list [file join $dir com.tcl]]
  source [list [file join $dir gnuplot.tcl]]
  package provide common 1.0
"

package ifneeded common_email 1.0 "
  source [list [file join $dir common.tcl]]
  source [list [file join $dir error.tcl]]
  source [list [file join $dir com.tcl]]
  source [list [file join $dir gnuplot.tcl]]
  source [list [file join $dir email.tcl]]
  package provide common_noemail 1.0
"
