#
# The methods extending math::linearalgebra were taken from http://wiki.tcl.tk/778
#

package require math::linearalgebra

 # cancelrow --
 #     Return a matrix minus the specified row
 # Arguments:
 #     matrix     Matrix to work on
 #     row        to delete
 #
 # Result:
 #     Matrix result of the operation
 #
 proc ::math::linearalgebra::cancelrow { matrix row } {
     return [concat [lrange $matrix 0 $row-1] [lrange $matrix $row+1 end]]
 }

 # cancelrow --
 #     Return a matrix minus the specified column
 # Arguments:
 #     matrix     Matrix to work on
 #     col        to delete
 #
 # Result:
 #     Matrix result of the operation
 #
 proc ::math::linearalgebra::cancelcol { matrix col } {
     set result {}
     foreach r $matrix {
         lappend result [concat [lrange $r 0 $col-1] [lrange $r $col+1 end]]
     }
     return $result
 }

# cofactor --
 #     Compute the cofactor of the specified element
 # Arguments:
 #     matrix     Matrix to work on
 #     row        
 #     col        
 #
 # Result:
 #     The cofactor of element at a{row,col}
 #
 proc ::math::linearalgebra::cofactor { matrix row col } {
     set submatrix [cancelcol [cancelrow $matrix $row] $col]
     return [determinant $submatrix]
 }

# adjointMatrix --
#     The adjoint matrix is the transpose of the cofactor matrix
# Arguments:
#     matrix
#
# Result:
#     The adjoint matrix
#
proc ::math::linearalgebra::adjointMatrix {matrix} {
   return [transpose [cofactorMatrix $matrix]]
}

# determinant --
#     Compute the cofactor of the specified element
# Arguments:
#     matrix     Matrix to work on
#     row        
#     col        
#
# Result:
#     The cofactor of element at a{row,col}
#
proc ::math::linearalgebra::determinant { matrix } {
   set shape [shape $matrix]
   if { [lindex $shape 0] != [lindex $shape 1] } {
       return -code error "determinant only defined for a square matrix"
   }

   switch -exact -- [join $shape x] {
       1x1 {
           return [lindex [lindex $matrix 0] 0]
       }
       2x2 {
           lassign [getrow $matrix 0] a b
           lassign [getrow $matrix 1] c d
           return [expr {($a*$d)-($c*$b)}]
       }
       default {
           set det 0
           set sign 0
           set row_no 0
           foreach row $matrix {
               set sign [expr {($sign==1)?(-1):(1)}]
               set det [expr {
                   $det+$sign*[lindex $row 0]*[cofactor $matrix $row_no 0]
               }]
               incr row_no
           }
           return $det
       }
   }
}

# invert --
#     Perform the matrix inversion using the adjoint method
#     Note: probably the Gauss-Jordan elimination over an
#           augmented matrix is *much* faster.
# Arguments:
#     matrix     Matrix to work on
#
# Result:
#     The inverted matrix
#
proc ::math::linearalgebra::invert { matrix } {
   set shape [shape $matrix]

   set det [determinant $matrix]
   if { $det == 0 } {
       return -code error "cannot invert a singular matrix"
   }

   switch -exact -- [join $shape x] {
       2x2 {
          set temp [mkMatrix 2 2]
          setelem temp 0 0 [getelem $matrix 1 1]
          setelem temp 1 1 [getelem $matrix 0 0]
          setelem temp 0 1 [expr {-1*[getelem $matrix 0 1]}]
          setelem temp 1 0 [expr {-1*[getelem $matrix 1 0]}]
       }
       default {
          set temp [adjointMatrix $matrix]
       }
   }

   return [scale_mat [expr 1./$det] $temp]
}

#
# Interpolates a data set using the Gaus-Markov estimator.
#
# Example input for data set {(1, 3), (2, 5), (3, 7)}:
#   X = {{1 1 1} {1 2 3}}
#   Y = {3 5 7}
#

proc ::math::linearalgebra::interpolate {X Y} {
  set XT [transpose $X]
  return [matmul $Y [matmul $XT [invert [matmul $X $XT]]]]
}


