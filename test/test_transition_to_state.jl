"""
State machine for these tests:

@startuml
state TransitionTestsMachine {
    state Start
    state Dest

    Start : entry / set entered
    Start : exit / set exited
    Dest : entry / set entered
    Dest : exit / set exited
}
state Unreachable

TransitionTestsMachine : entry / set entered
TransitionTestsMachine : exit / set exited
Unreachable : entry / set entered
Unreachable : exit / set exited
@enduml
"""

using Logging, Test
import HierarchicalStateMachines as HSM
include("state_transition_test_utils.jl")

@transition_tests_state TransitionTestsMachine
@transition_tests_state TransitionTestsStateStart
@transition_tests_state TransitionTestsStateDest
@transition_tests_state TransitionTestsStateUnreachable

function HSM.on_entry!(state::TransitionTestsMachine)
    state.entered = true
end

function HSM.on_exit!(state::TransitionTestsMachine)
    state.exited = true
end

function HSM.on_entry!(state::TransitionTestsStateStart)
    state.entered = true
end

function HSM.on_exit!(state::TransitionTestsStateStart)
    state.exited = true
end

function HSM.on_entry!(state::TransitionTestsStateDest)
    state.entered = true
end

function HSM.on_exit!(state::TransitionTestsStateDest)
    state.exited = true
end

function HSM.on_entry!(state::TransitionTestsStateUnreachable)
    state.entered = true
end

function HSM.on_exit!(state::TransitionTestsStateUnreachable)
    state.exited = true
end

function build_state_machine()
    machine = TransitionTestsMachine(nothing)
    start_state = TransitionTestsStateStart(machine)
    dest_state = TransitionTestsStateDest(machine)
    unreachable_state = TransitionTestsStateUnreachable(nothing)

    HSM.transition_to_state!(machine, start_state)

    reset_transition_test_state!(machine)
    reset_transition_test_state!(start_state)
    reset_transition_test_state!(dest_state)
    reset_transition_test_state!(unreachable_state)

    return machine, start_state, dest_state, unreachable_state
end

#
# Transition from Start to Dest should succeed.
#
@testset "transition_to_state!() -- Target state in state machine" begin
    machine, start_state, dest_state, unreachable_state = build_state_machine()
    HSM.transition_to_state!(machine, dest_state)
    @test HSM.active_state(machine) == dest_state
    @test !machine.entered
    @test !machine.exited
    @test !start_state.entered
    @test start_state.exited
    @test dest_state.entered
    @test !dest_state.exited
    @test !unreachable_state.entered
    @test !unreachable_state.exited
end

#
# Transition from Start to Unreachable should fail.
#
@testset "transition_to_state!() -- Target state not in state machine" begin
    machine, start_state, dest_state, unreachable_state = build_state_machine()
    @test_throws HSM.HsmStateTransitionError HSM.transition_to_state!(machine, unreachable_state)
    @test HSM.active_state(machine) == start_state
    @test !machine.entered
    @test !machine.exited
    @test !start_state.entered
    @test !start_state.exited
    @test !dest_state.entered
    @test !dest_state.exited
    @test !unreachable_state.entered
    @test !unreachable_state.exited
end
