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

macro transition_tests_state(name)
    return :(
        mutable struct $name <: HSM.AbstractHsmState
            parent_state::Union{HSM.AbstractHsmState, Nothing}
            active_state::Union{HSM.AbstractHsmState, Nothing}

            function $name(parent_state, active_state)
                if !isnothing(active_state)
                    error("active_state must be `nothing`")
                end
                new(parent_state, active_state)
            end
        end
    )
end

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

    HSM.transition_to_state(machine, start_state)

    return machine, start_state, dest_state, unreachable_state
end

#
# Transition from Start to Dest should succeed
#
@testset "transition_to_state() -- Target state in state machine" begin
    machine, start_state, dest_state, unreachable_state = build_state_machine()
    HSM.transition_to_state(machine, dest_state)
    @test HSM.active_state(machine) == dest_state
end

#
# Transition from Start to Unreachable should fail.
#
@testset "transition_to_state() -- Target state not in state machine" begin
    machine, start_state, dest_state, unreachable_state = build_state_machine()
    @test_throws HSM.HsmStateTransitionError HSM.transition_to_state(machine, unreachable_state)
    @test HSM.active_state(machine) == start_state
end