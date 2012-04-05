
set simulationTime 0
set simulationPlay 0
set simulationStep 50

proc simulationStep {} {
  set plot [Plot set activePlot]
  $plot instvar maxTime
  if {$::simulationTime < $maxTime && $::simulationPlay} {
    event generate . <<TimeChanged>> -data $::simulationTime
    incr ::simulationTime
    after $::simulationStep simulationStep
  }
}

proc simulationPlay {} {
  set ::simulationPlay 1
  .controls.play config -image pause -command simulationPause
  set plot [Plot set activePlot]
  $plot disableTimeMarker
  simulationStep
}

proc simulationPause {} {
  set ::simulationPlay 0
  .controls.play config -image play -command simulationPlay
  set plot [Plot set activePlot]
  $plot enableTimeMarker
}

proc simulationStop {} {
  set ::simulationPlay 0
  set ::simulationTime 0
  .controls.play config -image play -command simulationPlay
  set plot [Plot set activePlot]
  event generate . <<TimeChanged>> -data $::simulationTime
  $plot enableTimeMarker
}

#place [frame .controls] -x 0 -y 0
#pack [button .controls.stop -image stop -command simulationStop] -side left
#pack [button .controls.play -image play -command simulationPlay]
