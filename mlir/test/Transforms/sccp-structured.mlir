// RUN: mlir-opt -allow-unregistered-dialect %s -pass-pipeline="func(sccp)" -split-input-file | FileCheck %s

/// Check that a constant is properly propagated when only one edge is taken.

// CHECK-LABEL: func @simple(
func @simple(%arg0 : i32) -> i32 {
  // CHECK: %[[CST:.*]] = constant 1 : i32
  // CHECK-NOT: loop.if
  // CHECK: return %[[CST]] : i32

  %cond = constant true
  %res = loop.if %cond -> (i32) {
    %1 = constant 1 : i32
    loop.yield %1 : i32
  } else {
    loop.yield %arg0 : i32
  }
  return %res : i32
}

/// Check that a constant is properly propagated when both edges produce the
/// same value.

// CHECK-LABEL: func @simple_both_same(
func @simple_both_same(%cond : i1) -> i32 {
  // CHECK: %[[CST:.*]] = constant 1 : i32
  // CHECK-NOT: loop.if
  // CHECK: return %[[CST]] : i32

  %res = loop.if %cond -> (i32) {
    %1 = constant 1 : i32
    loop.yield %1 : i32
  } else {
    %2 = constant 1 : i32
    loop.yield %2 : i32
  }
  return %res : i32
}

/// Check that the arguments go to overdefined if the branch cannot detect when
/// a specific successor is taken.

// CHECK-LABEL: func @overdefined_unknown_condition(
func @overdefined_unknown_condition(%cond : i1, %arg0 : i32) -> i32 {
  // CHECK: %[[RES:.*]] = loop.if
  // CHECK: return %[[RES]] : i32

  %res = loop.if %cond -> (i32) {
    %1 = constant 1 : i32
    loop.yield %1 : i32
  } else {
    loop.yield %arg0 : i32
  }
  return %res : i32
}

/// Check that the arguments go to overdefined if there are conflicting
/// constants.

// CHECK-LABEL: func @overdefined_different_constants(
func @overdefined_different_constants(%cond : i1) -> i32 {
  // CHECK: %[[RES:.*]] = loop.if
  // CHECK: return %[[RES]] : i32

  %res = loop.if %cond -> (i32) {
    %1 = constant 1 : i32
    loop.yield %1 : i32
  } else {
    %2 = constant 2 : i32
    loop.yield %2 : i32
  }
  return %res : i32
}

/// Check that arguments are properly merged across loop-like control flow.

// CHECK-LABEL: func @simple_loop(
func @simple_loop(%arg0 : index, %arg1 : index, %arg2 : index) -> i32 {
  // CHECK: %[[CST:.*]] = constant 0 : i32
  // CHECK-NOT: loop.for
  // CHECK: return %[[CST]] : i32

  %s0 = constant 0 : i32
  %result = loop.for %i0 = %arg0 to %arg1 step %arg2 iter_args(%si = %s0) -> (i32) {
    %sn = addi %si, %si : i32
    loop.yield %sn : i32
  }
  return %result : i32
}

/// Check that arguments go to overdefined when loop backedges produce a
/// conflicting value.

// CHECK-LABEL: func @loop_overdefined(
func @loop_overdefined(%arg0 : index, %arg1 : index, %arg2 : index) -> i32 {
  // CHECK: %[[RES:.*]] = loop.for
  // CHECK: return %[[RES]] : i32

  %s0 = constant 1 : i32
  %result = loop.for %i0 = %arg0 to %arg1 step %arg2 iter_args(%si = %s0) -> (i32) {
    %sn = addi %si, %si : i32
    loop.yield %sn : i32
  }
  return %result : i32
}

/// Test that we can properly propagate within inner control, and in situations
/// where the executable edges within the CFG are sensitive to the current state
/// of the analysis.

// CHECK-LABEL: func @loop_inner_control_flow(
func @loop_inner_control_flow(%arg0 : index, %arg1 : index, %arg2 : index) -> i32 {
  // CHECK: %[[CST:.*]] = constant 1 : i32
  // CHECK-NOT: loop.for
  // CHECK-NOT: loop.if
  // CHECK: return %[[CST]] : i32

  %cst_1 = constant 1 : i32
  %result = loop.for %i0 = %arg0 to %arg1 step %arg2 iter_args(%si = %cst_1) -> (i32) {
    %cst_20 = constant 20 : i32
    %cond = cmpi "ult", %si, %cst_20 : i32
    %inner_res = loop.if %cond -> (i32) {
      %1 = constant 1 : i32
      loop.yield %1 : i32
    } else {
      %si_inc = addi %si, %cst_1 : i32
      loop.yield %si_inc : i32
    }
    loop.yield %inner_res : i32
  }
  return %result : i32
}
