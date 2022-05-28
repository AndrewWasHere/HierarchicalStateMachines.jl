using Logging, Test, HSM

struct ActiveStateTestState <: HSM.AbstractHsmState
    state_info::HSM.HsmStateInfo

    ActiveStateTestState(parent_state) = new(HSM.HsmStateInfo(parent_state))
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
function active_state_test_state_machine()
    A = ActiveStateTestState(nothing)
    B = ActiveStateTestState(A)
    C = ActiveStateTestState(A)
    D = ActiveStateTestState(C)
    E = ActiveStateTestState(C)

    return A, B, C, D, E
end

@testset "active_state()" begin
    A, B, C, D, E = active_state_test_state_machine()
    HSM.transition_to_state!(A, B)

    @test HSM.active_state(A) == B
    @test HSM.active_state(B) == B
    @test HSM.active_state(C) == B
    @test HSM.active_state(D) == B
    @test HSM.active_state(E) == B
end