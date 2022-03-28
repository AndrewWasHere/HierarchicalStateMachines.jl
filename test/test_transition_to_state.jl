"""
State machine for these tests:

@startuml
state TransitionTestsMachine {
    state TransitionTestsStateStart as Start {}
    state TransitionTestsStateDest as Dest {}
}
state TransitionTestsStateUnreachable as Unreachable {}
@enduml
"""

using Logging, Test, HSM
include("state_transition_test_utils.jl")

@transition_tests_state TransitionTestsMachine
TransitionTestsMachine(parent_state) = TransitionTestsMachine(parent_state, nothing)

@transition_tests_state TransitionTestsStateStart
TransitionTestsStateStart(parent_state) = TransitionTestsStateStart(parent_state, nothing)

@transition_tests_state TransitionTestsStateDest
TransitionTestsStateDest(parent_state) = TransitionTestsStateDest(parent_state, nothing)

@transition_tests_state TransitionTestsStateUnreachable
TransitionTestsStateUnreachable(parent_state) = TransitionTestsStateUnreachable(parent_state, nothing)

function build_state_machine()
    machine = TransitionTestsMachine(nothing)
    start_state = TransitionTestsStateStart(machine)
    dest_state = TransitionTestsStateDest(machine)
    unreachable_state = TransitionTestsStateUnreachable(nothing)

    HSM.transition_to_state!(machine, start_state)

    return machine, start_state, dest_state, unreachable_state
end

#
# Transition from Start to Dest should succeed.
#
@testset "transition_to_state!() -- Target state in state machine" begin
    machine, start_state, dest_state, unreachable_state = build_state_machine()
    HSM.transition_to_state!(machine, dest_state)
    @test HSM.active_state(machine) == dest_state
end

#
# Transition from Start to Unreachable should fail.
#
@testset "transition_to_state!() -- Target state not in state machine" begin
    machine, start_state, dest_state, unreachable_state = build_state_machine()
    @test_throws HSM.HsmStateTransitionError HSM.transition_to_state!(machine, unreachable_state)
    @test HSM.active_state(machine) == start_state
end