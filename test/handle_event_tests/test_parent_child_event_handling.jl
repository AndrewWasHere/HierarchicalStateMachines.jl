"""
State machine used for these tests:

@startuml
state TestParentChildEventHandlingMachine {
    state TestParentChildEventHandlingChild 
    TestParentChildEventHandlingChild : ChildHandledEvent / set handled_child_handled_event
}

TestParentChildEventHandlingMachine : ChildHandledEvent / set handled_child_handled_event
TestParentChildEventHandlingMachine : ChildUnhandledEvent / set_handled_child_unhandled_event
@enduml
"""

using Logging, Test, HSM

struct ChildHandledEvent <: HSM.AbstractHsmEvent
end

struct ChildUnhandledEvent <: HSM.AbstractHsmEvent
end

macro test_parent_child_event_state(name)
    return :(
        mutable struct $name <: HSM.AbstractHsmState
            state_info::HSM.HsmStateInfo
            handled_child_handled_event::Bool
            handled_child_unhandled_event::Bool

            $name(parent_state) = new(HSM.HsmStateInfo(parent_state), false, false)
        end
    )
end

@test_parent_child_event_state(TestParentChildEventHandlingMachine)
@test_parent_child_event_state(TestParentChildEventHandlingChild)

function HSM.on_event!(state::TestParentChildEventHandlingMachine, event::ChildHandledEvent)
    @debug "on_event!(TestParentChildEventHandlingMachine, ChildHandledEvent)"
    state.handled_child_handled_event = true
    return true
end

function HSM.on_event!(state::TestParentChildEventHandlingMachine, event::ChildUnhandledEvent)
    @debug "on_event!(TestParentChildEventHandlingMachine, ChildUnhandledEvent)"
    state.handled_child_unhandled_event = true
    return true
end

function HSM.on_event!(state::TestParentChildEventHandlingChild, event::ChildHandledEvent)
    @debug "on_event!(TestParentChildEventHandlingMachine, ChildHandledEvent)"
    state.handled_child_handled_event = true
    return true
end

@testset "handle_event!() -- Parent state handler not called when child handles event" begin
    machine = TestParentChildEventHandlingMachine(nothing)
    child = TestParentChildEventHandlingChild(machine)
    HSM.transition_to_state!(machine, child)

    HSM.handle_event!(child, ChildHandledEvent())
    @test machine.handled_child_handled_event == false
    @test machine.handled_child_unhandled_event == false
    @test child.handled_child_handled_event == true
    @test child.handled_child_unhandled_event == false
end

@testset "handle_event!() -- Parent state handler called when child does not handle event" begin
    machine = TestParentChildEventHandlingMachine(nothing)
    child = TestParentChildEventHandlingChild(machine)
    HSM.transition_to_state!(machine, child)

    HSM.handle_event!(child, ChildUnhandledEvent())
    @test machine.handled_child_handled_event == false
    @test machine.handled_child_unhandled_event == true
    @test child.handled_child_handled_event == false
    @test child.handled_child_unhandled_event == false
end
