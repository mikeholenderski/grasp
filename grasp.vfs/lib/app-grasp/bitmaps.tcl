package require Tk

set bitmaps {
  play {
    #define stop_width 9
    #define stop_height 9
    static char stop_bits = {
        0x04, 0x00, 0x0c, 0x00, 0x1c, 0x00, 0x3c, 0x00, 0x7c, 0x00, 0x3c, 0x00, 0x1c, 0x00, 0x0c, 0x00, 0x04, 0x00
    }
  }

 pause {
    #define stop_width 9
    #define stop_height 9
    static char stop_bits = {
        0xc6, 0x00, 0xc6, 0x00, 0xc6, 0x00, 0xc6, 0x00, 0xc6, 0x00, 0xc6, 0x00, 0xc6, 0x00, 0xc6, 0x00, 0xc6, 0x00
    }
  }

  stop {
    #define stop_width 9
    #define stop_height 9
    static char stop_bits = {
        0x00, 0x00, 0xfe, 0x00, 0xfe, 0x00, 0xfe, 0x00, 0xfe, 0x00, 0xfe, 0x00, 0xfe, 0x00, 0xfe, 0x00, 0x00, 0x00
    }
  }

  minus {
    #define minus_width 9
    #define minus_height 9
    static char minus_bits = {
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xfe, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    }
  }

  plus {
    #define plus_width 9
    #define plus_height 9
    static char plus_bits = {
        0x00, 0x00, 0x10, 0x00, 0x10, 0x00, 0x10, 0x00, 0xfe, 0x00, 0x10, 0x00, 0x10, 0x00, 0x10, 0x00, 0x00, 0x00
    }
  }

  lines_up {
    #define up_width 8
    #define up_height 8
    static char up_bits = {
        0x88, 0x44, 0x22, 0x11, 0x88, 0x44, 0x22, 0x11
    }
  }

  lines_down {
    #define down_width 8
    #define down_height 8
    static char down_bits = {
        0x11, 0x22, 0x44, 0x88, 0x11, 0x22, 0x44, 0x88
    }
  }

  lines_horizontal {
    #define horizontal_width 4
    #define horizontal_height 4
    static char horizontal_bits = {
        0x0f, 0x00, 0x00, 0x00
    }
  }

  lines_vertical {
    #define vertical_width 4
    #define vertical_height 4
    static char vertical_bits = {
        0x01, 0x01, 0x01, 0x01
    }
  }
}


proc patternForKey {key} {
  # for custom stipple patterns the bitmap needs to be stored in a file
  # and the bitmap name must be the file name preceeded by @
  set pattern $key
  # check if standard pattern
  if {[lsearch {gray12 gray25 gray50 gray75} $pattern] > -1} {
    return $pattern
  }
  
  # if a custom pattern, then return the corresponding fiel name
  if {[llength $pattern]} {
    global $pattern
    return @[set $pattern]
  } else {
    return {}
  }
}

proc createBitmaps {} {

  set homeDir [file dirname [file dirname [file dirname [file dirname [info script]]]]]

  foreach {name data} $::bitmaps {

    set tmpdir [file join $homeDir tmp]
    switch $::tcl_platform(platform) {
        unix {
            catch { set tmpdir /tmp }  ;# or even $::env(TMPDIR), at times.
        }
        macintosh {
            catch { set tmpdir $::env(TRASH_FOLDER) } ;# a better place?
        }
        default {
            catch {set tmpdir $::env(TMP)}
            catch {set tmpdir $::env(TEMP)}
        }
    }
    set fileName [file join $tmpdir $name.bmp]
    if {![file exists $tmpdir]} { file mkdir $tmpdir }
    
        set fout [open $fileName w+]
        puts $fout $data
        close $fout
    
    if {[file exists $fileName]} {
        global $name
        set $name $fileName
        image create bitmap $name -file $fileName
    } else {
      set emsg "ERROR: cannot create '$name' bitmap"
      tk_messageBox -title Error -icon error -message $emgs
      exit
    }
  }
}
 
createBitmaps