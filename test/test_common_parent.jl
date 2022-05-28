using Logging, Test, HSM

struct CommonParentState <: HSM.AbstractHsmState
    state_info::HSM.HsmStateInfo

    CommonParentState(parent_state) = new(HSM.HsmStateInfo(parent_state))
end

"""
    basic_state_machine()

Builds and returns the following state machine:

```plantuml
@startuml
state A {
    state B
    state C {
        state D
        state E
    }
}
@enduml
```
"""
function common_parent_state_machine()
    A = CommonParentState(nothing)
    B = CommonParentState(A)
    C = CommonParentState(A)
    D = CommonParentState(C)
    E = CommonParentState(C)

    return A, B, C, D, E
end

@testset "common_parent()" begin
    A, B, C, D, E = common_parent_state_machine()

    # Common parent of A and any other state is A.
    @test HSM.common_parent(A, B) == A
    @test HSM.common_parent(D, A) == A

    # Common parent of B and any other state is A.
    @test HSM.common_parent(B, C) == A
    @test HSM.common_parent(D, B) == A

    # Common parent of C and its substates is C.
    @test HSM.common_parent(C, D) == C
    @test HSM.common_parent(E, C) == C

    # Common parent of D and E is C.
    @test HSM.common_parent(D, E) == C
end