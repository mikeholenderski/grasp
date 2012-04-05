proc makeGnuplotScript2dHistogram {series xlabel ylabel psFileName args} {
  set title ""
  set legend right
  set color gray
  # can be 'Times-Roman' or 'Helvetica'
  set font Times-Roman
  set fontsize 20
  
  parseArgs $args {title legend color}

  # create the gnuplot script
  set gnuplotScript {    
    set ylabel "$ylabel"
    set xlabel "$xlabel"
    set yrange [0:*]
    set output '$psFileName'
    
    set style data histogram
    set style histogram clustered
    set style fill solid 1.0 border -1
  }
  
  append gnuplotScript "set terminal postscript eps enhanced color solid \"$font\" $fontsize\n"

  if {[llength $title]} { append gnuplotScript "set title $title\n" }

  switch $legend {
    right {}
    left { append gnuplotScript "set key left reverse Left\n" }
    none { append gnuplotScript "set key off\n" }
  }

  set postfix 1
  foreach {seriesTitle data} $series {
    set dataFileName $psFileName.$postfix.data

    # avoid collisions in case several data files are used
    incr postfix

    # write plot data to a file
    set channel [open $dataFileName w+]
    foreach {x y} $data {
      puts $channel "$x $y"
    }
    close $channel

    # add the data file to the gnuplot script
    lappend plotCommands "'$dataFileName' using 2:xtic(1) title \"$seriesTitle\" lc rgb \"$color\""
  }
  
  append gnuplotScript "plot [join $plotCommands ,]\n"
  
  return $gnuplotScript
}

proc makeGnuplotScript2dLine {series xlabel ylabel psFileName args} {
  set title ""
  set legend right
  set color 1
  set sort 0
  # can be 'Times-Roman' or 'Helvetica'
  set font Times-Roman
  set fontsize 20
  
  parseArgs $args {title legend color}

  # create the gnuplot script
  set gnuplotScript {    
    set ylabel "$ylabel"
    set xlabel "$xlabel"
    set yrange [0:*]
    set output '$psFileName'
    
    set style data lines
  }
  
  if {$color} {
    append gnuplotScript "set terminal postscript eps enhanced \"$font\" $fontsize color\n"  
  } else {
    append gnuplotScript "set terminal postscript eps enhanced \"$font\" $fontsize\n"
  }
  
  if {[llength $title]} { append gnuplotScript "set title $title\n" }

  switch $legend {
    right {}
    left { append gnuplotScript "set key left reverse Left\n" }
    none { append gnuplotScript "set key off\n" }
  }

  set postfix 1
  foreach {seriesTitle data} $series {
    set dataFileName $psFileName.$postfix.data

    # avoid collisions in case several data files are used
    incr postfix

    # sort the data according to x
    if {$sort} {
      set dataPairs {}
      foreach {x y} $data {
        lappend dataPairs [list $x $y]
      } 
      set data [lsort -integer -index 0 $dataPairs]
    }
    
    # write plot data to a file
    set channel [open $dataFileName w+]
    foreach {x y} $data {
      puts $channel "$x $y"
    }
    close $channel

    # add the data file to the gnuplot script
    lappend plotCommands "'$dataFileName' title \"$seriesTitle\"" 
  }
  
  append gnuplotScript "plot [join $plotCommands ,]\n"
  
  return $gnuplotScript
}

proc makeGnuplotScript2dBar {series xlabel ylabel psFileName args} {
  set title ""
  set color gray
  # can be 'Times-Roman' or 'Helvetica'
  set font Times-Roman
  set fontsize 20
  
  parseArgs $args {title legend color}

  # create the gnuplot script
  set gnuplotScript {    
    set ylabel "$ylabel"
    set xlabel "$xlabel"
    set yrange [0:*]
    set output '$psFileName'
    
    set style data lines
  }
  
  append gnuplotScript "set terminal postscript eps enhanced \"$font\" $fontsize\n"

  if {[llength $title]} { append gnuplotScript "set title $title\n" }

  set postfix 1
  foreach {seriesTitle data} $series {
    set dataFileName $psFileName.$postfix.data

    # avoid collisions in case several data files are used
    incr postfix

    # write plot data to a file
    set channel [open $dataFileName w+]
    foreach {x y} $data {
      puts $channel "$x $y"
    }
    close $channel

    # add the data file to the gnuplot script
    lappend plotCommands "'$dataFileName' with impulse linewidth 5 title \"$seriesTitle\"" 
  }
  
  append gnuplotScript "plot [join $plotCommands ,]\n"
  
  return $gnuplotScript
}

proc makeGnuplotScript3d {series xlabel ylabel zlabel psFileName args} {
  # create the gnuplot script
  set gnuplotScript {
    set terminal postscript eps enhanced "Times-Roman" 20
    
    set ylabel "$ylabel"
    set xlabel "$xlabel"
    set zlabel "$zlabel" rotate by 90
    set zrange [0:*]
    set xyplane at 0
    set style data lines
    set output '$psFileName'
  }

  set gridSize [expr $::stopIndex - $::startIndex + 1]
  append gnuplotScript "    set dgrid3d $gridSize, $gridSize\n"

  set postfix 1
  foreach {title data} $series {
    set dataFileName $psFileName.$postfix.data
    
    # avoid collisions in case several data files are used
    incr postfix

    # write plot data to a file
    set channel [open $dataFileName w+]
    foreach {x y z} $data {
      puts $channel "$x $y $z"
    }    
    close $channel

    # add the data file to the gnuplot script
    lappend plotCommands "'$dataFileName' title \"$title\"" 
  }
  
  append gnuplotScript "splot [join $plotCommands ","]\n"
  
  return $gnuplotScript
}


proc makeGnuplot {pdfFileName series kind args} {
  set removeData 1
  set removeScript 1
  set removePs 1
  set removePdf 0
  set xlabel "?"
  set ylabel "?"
  set zlabel "?"
  set title ""
  set legend right
  
  parseArgs $args {removeData removeScript removePs removePdf xlabel ylabel zlabel title legend}
  
  set scriptFileName $pdfFileName.script
  set psFileName $pdfFileName.ps

  switch -- $kind {
    3d {
      set gnuplotScript [makeGnuplotScript3d $series $xlabel $ylabel $zlabel $psFileName]
    }
    2dLine {
      set gnuplotScript [makeGnuplotScript2dLine $series $xlabel $ylabel $psFileName]
    }
    2dHistogram {
      set gnuplotScript [makeGnuplotScript2dHistogram $series $xlabel $ylabel $psFileName -legend $legend -title $title]    
    }
    2dBar {
      set gnuplotScript [makeGnuplotScript2dBar $series $xlabel $ylabel $psFileName]    
    }
    default {
      error "unknown kind $kind"
    }
  }

  switch $legend {
    right {}
    left { append gnuplotScript "set key left reverse Left\n" }
    none { append gnuplotScript "set key off\n" }
  }
  
  # write teh gnuplot script to a file
  set channel [open $scriptFileName w+]
  set line [subst -nocommands $gnuplotScript]
  regsub -all -- @@@ $line \$ line
  puts $channel $line
  close $channel
  
  # run gnuplot
  if {[catch {exec gnuplot $scriptFileName} err]} {
    puts $err
  }
  
  # convert the ps to a pdf
  switch $::tcl_platform(os) {
    "Darwin" {
      exec pstopdf $psFileName
    }
    "Linux" {
      exec ps2pdf $psFileName
    }
  }

  # cleanup
  if {$removeData} { 
    foreach dataFileName [glob $psFileName.*.data] {
      exec rm $dataFileName
    }
  }
  if {$removeScript} { exec rm $scriptFileName }
  if {$removePs} { exec rm $psFileName }
  if {$removePdf} { exec rm [file root $psFileName].pdf }
}

proc processFile {fileName args} {
  puts "processing $fileName"
  
  set printStats 0
  set printGnuplot 1
  set title ?
  set removeData 1
  set removeScript 1
  set removePs 1
  set removePdf 0
  
  parseArgs $args {printStats printGnuplot title removeData removeScript removePs removePdf}
  
  # collect all the profile data
  catch {unset ::profile}
  set channel [open $fileName r]    
  while {![eof $channel]} {
    set line [gets $channel]
    if {[regexp {^profile.*} $line]} {
      eval $line
    }
  }
  close $channel

  set stats {}
  set grandTotal 0
  
  # plot the data
  foreach {key values} [array get ::profile] {
    set data ""
    set total 0
    set max [lindex $values 0]
    set min [lindex $values 0]
    for {set i 0} {$i < [llength $values]} {incr i} {
      set value [lindex $values $i]
      append data " $i $value"
      set total [expr $total + $value]
      if {$max < $value} { set max $value }
      if {$min > $value} { set min $value }
    }
    
    # output some statistics
    lappend stats $key $total $max $min
    set grandTotal [expr $grandTotal + $total]
  }
  
  if {$printStats} {
    set channel [open $fileName.stats.txt w+]
    foreach {key total max min} $stats {
      puts $channel "$key: total=$total, max=$max, min=$min""
    }
    puts $channel "grand total: $grandTotal"
    close $channel
  }
  
  return $stats
}

proc processFiles {dir startServers stopServers startTasks stopTasks} {
  # process all the files
  foreach fileName [glob -dir $dir *] {
    if {[regexp {.+\.([[:digit:]]+)\.([[:digit:]]+)\.([[:digit:]]+)\.log} "$fileName" _ T numServers numTasksPerServer]} {
      set stats [processFile $fileName -printGnuplot 0]
      foreach {key total max min} $stats {
        lappend Stats($dir.$key) $numServers $numTasksPerServer $total $max $min
      }
    }
  }
  
  # accumulate the stats in global arrays with . notation for accessing the metrics
  foreach {key stats} [array get Stats] {
    foreach {servers tasks total max min} $stats {
      if {[info exists ::$key.total.$servers.$tasks]} {
        error "::$key.total.$servers.$tasks already exists"
      }
      if {[info exists ::$key.max.$servers.$tasks]} {
        error "::$key.max.$servers.$tasks already exists"
      }
      if {[info exists ::$key.min.$servers.$tasks]} {
        error "::$key.min.$servers.$tasks already exists"
      }
      
      set ::$key.total.$servers.$tasks $total 
      set ::$key.max.$servers.$tasks $max
      set ::$key.min.$servers.$tasks $min
    }
  }

  # compute grand total  
  for {set i $startTasks} {$i <= $stopTasks} {incr i} {
    for {set j $startServers} {$j <= $stopServers} {incr j} {
       # compute total instructions
       set ::$dir.grand.$j.$i [expr [set ::$dir.scheduler.total.$j.$i] + [set ::$dir.tick.total.$j.$i]]
       # compute percentages (i.e. utilization)
       set app [set ::$dir.app.total.$j.$i]
       set ::$dir.percent.$j.$i [expr double([set ::$dir.scheduler.total.$j.$i] + [set ::$dir.tick.total.$j.$i])/$app*100]
       set ::$dir.scheduler.percent.$j.$i [expr double([set ::$dir.scheduler.total.$j.$i])/$app*100]
       set ::$dir.tick.percent.$j.$i [expr double([set ::$dir.tick.total.$j.$i])/$app*100]
    }
  }  
}

proc generate3dPlotDirs {dir1 dir2 measure zlabel title1 title2 startServers stopServers startTasks stopTasks} {
  set data1 ""
  for {set i $startTasks} {$i <= $stopTasks} {incr i} {
    for {set j $startServers} {$j <= $stopServers} {incr j} {
      append data1 " $j $i [set ::$dir1.$measure.$j.$i]"
    }
  }

  set data2 ""
  for {set i $startTasks} {$i <= $stopTasks} {incr i} {
    for {set j $startServers} {$j <= $stopServers} {incr j} {
      append data2 " $j $i [set ::$dir2.$measure.$j.$i]"
    }
  }
  
  makeGnuplot $measure [list "$title1" $data1 "$title2" $data2] 3d \
    -xlabel $::labelServers -ylabel $::labelTasks -zlabel $zlabel -legend left
}

proc generate3dPlotMeasures {dir measure1 measure2 zlabel title1 title2 startServers stopServers startTasks stopTasks} {
  set data1 ""
  for {set i $startTasks} {$i <= $stopTasks} {incr i} {
    for {set j $startServers} {$j <= $stopServers} {incr j} {
    append data1 " $j $i [set ::$dir.$measure1.$j.$i]"
  }
  }

  set data2 ""
  for {set i $startTasks} {$i <= $stopTasks} {incr i} {
    for {set j $startServers} {$j <= $stopServers} {incr j} {
    append data2 " $j $i [set ::$dir.$measure2.$j.$i]"
  }
  }
  
  makeGnuplot $dir.$measure1.$measure2 [list "$title1" $data1 "$title2" $data2] 3d \
    -xlabel $::labelServers -ylabel $::labelTasks -zlabel $zlabel -legend left
}
