; RUN: llvm-as < %s | llvm-dis | grep byval
; RUN: verify-uselistorder %s -preserve-bc-use-list-order -num-shuffles=5

	%struct = type {  }

declare void @foo(...)

define void @bar() {
	call void (...)* @foo(%struct* byval null )
	ret void
}
