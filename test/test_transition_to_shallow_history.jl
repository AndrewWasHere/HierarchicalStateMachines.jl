"""
State machine for these tests:

@startuml
state TestShallowHistoryMachine {
    state TestShallowHistoryStartState
    state TestShallowHistoryL1State {
        state TestShallowHistoryL2State {
            state TestShallowHistoryL3State
        }
    }
}
@enduml
"""

using Logging, Test
import HierarchicalStateMachines as HSM
include("state_transition_test_utils.jl")

@transition_tests_state TestShallowHistoryMachine
@transition_tests_state TestShallowHistoryStartState
@transition_tests_state TestShallowHistoryL1State
@transition_tests_state TestShallowHistoryL2State
@transition_tests_state TestShallowHistoryL3State

function build_shallow_history_machine()
    machine = TestShallowHistoryMachine(nothing)
    start_state = TestShallowHistoryStartState(machine)
    l1_state = TestShallowHistoryL1State(machine)
    l2_state = TestShallowHistoryL2State(l1_state)
    l3_state = TestShallowHistoryL3State(l2_state)

    HSM.transition_to_state!(machine, start_state)

    return machine, start_state, l1_state, l2_state, l3_state
end

#
# Shallow history transition to a state that has not been entered before is the
# transitioned-to state.
#
@testset "transition_to_shallow_history!() -- start -shallow-> l1 => l1" begin
    machine, start_state, l1_state, l2_state, l3_state = build_shallow_history_machine()
    HSM.transition_to_shallow_history!(machine, l1_state)
    @test HSM.active_state(machine) == l1_state
end

#
# Shallow history transition to a state whose substate's child has been entered 
# before is the substate.
#
@testset "transition_to_shallow_history!() -- start -> l3 -> start -shallow-> l1 => l2" begin
    machine, start_state, l1_state, l2_state, l3_state = build_shallow_history_machine()
    HSM.transition_to_state!(machine, l3_state)
    HSM.transition_to_state!(machine, start_state)
    HSM.transition_to_shallow_history!(machine, l1_state)
    @test HSM.active_state(machine) == l2_state
end
