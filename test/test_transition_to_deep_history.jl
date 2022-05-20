"""
State machine for these tests:

@startuml
state TestDeepHistoryMachine {
    state TestDeepHistoryStartState
    state TestDeepHistoryL1State {
        state TestDeepHistoryL2State {
            state TestDeepHistoryL3State
        }
    }
}
@enduml
"""

using Logging, Test, HSM
include("state_transition_test_utils.jl")

@transition_tests_state TestDeepHistoryMachine
@transition_tests_state TestDeepHistoryStartState
@transition_tests_state TestDeepHistoryL1State
@transition_tests_state TestDeepHistoryL2State
@transition_tests_state TestDeepHistoryL3State

function build_deep_history_machine()
    machine = TestDeepHistoryMachine(nothing)
    start_state = TestDeepHistoryStartState(machine)
    l1_state = TestDeepHistoryL1State(machine)
    l2_state = TestDeepHistoryL2State(l1_state)
    l3_state = TestDeepHistoryL3State(l2_state)

    HSM.transition_to_state!(machine, start_state)

    return machine, start_state, l1_state, l2_state, l3_state
end

#
# Deep history transition to a state that has not been entered before is the
# transitioned-to state.
#
@testset "transition_to_deep_history!() -- start -deep-> l1 => l1" begin
    machine, start_state, l1_state, l2_state, l3_state = build_deep_history_machine()
    HSM.transition_to_deep_history!(machine, l1_state)
    @test HSM.active_state(machine) == l1_state
end

#
# Deep history transition to a state whose substate's child has been entered 
# before is the substate.
#
@testset "transition_to_deep_history!() -- start -> l3 -> start -deep-> l1 => l3" begin
    machine, start_state, l1_state, l2_state, l3_state = build_deep_history_machine()
    HSM.transition_to_state!(machine, l3_state)
    HSM.transition_to_state!(machine, start_state)
    HSM.transition_to_deep_history!(machine, l1_state)
    @test HSM.active_state(machine) == l3_state
end
