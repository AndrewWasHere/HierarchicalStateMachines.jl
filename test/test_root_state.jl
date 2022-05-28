using Logging, Test, HSM

struct RootStateTestState <: HSM.AbstractHsmState
    state_info::HSM.HsmStateInfo

    RootStateTestState(parent_state) = new(HSM.HsmStateInfo(parent_state))
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
function root_state_state_machine()
    A = RootStateTestState(nothing)
    B = RootStateTestState(A)
    C = RootStateTestState(A)
    D = RootStateTestState(C)
    E = RootStateTestState(C)

    return A, B, C, D, E
end

@testset "root_state()" begin
    A, B, C, D, E = root_state_state_machine()

    @test HSM.root_state(A) == A
    @test HSM.root_state(B) == A
    @test HSM.root_state(C) == A
    @test HSM.root_state(D) == A
    @test HSM.root_state(E) == A
end