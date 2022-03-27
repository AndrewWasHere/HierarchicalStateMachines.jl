"""
State machine used for these tests:

@startuml
state TestParentChildEventHandlingMachine {
    ChildHandledEvent / set handled_child_handled_event
    ChildUnhandledEvent / set handled_child_unhandled_event

    state TestParentChildEventHandlingChild {
        ChildHandledEvent / set handled_child_handled_event
    }
}
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
            parent_state::Union{HSM.AbstractHsmState, Nothing}
            active_state::Union{HSM.AbstractHsmState, Nothing}
            handled_child_handled_event::Bool
            handled_child_unhandled_event::Bool

            function $name(
                parent_state, 
                active_state, 
                handled_child_handled_event, 
                handled_child_unhandled_event
            )
                if !isnothing(active_state)
                    error("active_state must be `nothing`")
                elseif handled_child_handled_event
                    error("handled_child_handled_event must be `false`")
                elseif handled_child_unhandled_event
                    error("handled_child_unhandled_event must be `false`")
                end
                new(
                    parent_state, 
                    active_state, 
                    handled_child_handled_event, 
                    handled_child_unhandled_event
                )
            end
        end
    )
end

@test_parent_child_event_state(TestParentChildEventHandlingMachine)
TestParentChildEventHandlingMachine(parent_state) = TestParentChildEventHandlingMachine(
    parent_state, nothing, false, false
)

@test_parent_child_event_state(TestParentChildEventHandlingChild)
TestParentChildEventHandlingChild(parent_state) = TestParentChildEventHandlingChild(
    parent_state, nothing, false, false
)

function HSM.on_event(state::TestParentChildEventHandlingMachine, event::ChildHandledEvent)
    @debug "on_event(TestParentChildEventHandlingMachine, ChildHandledEvent)"
    state.handled_child_handled_event = true
    return true
end

function HSM.on_event(state::TestParentChildEventHandlingMachine, event::ChildUnhandledEvent)
    @debug "on_event(TestParentChildEventHandlingMachine, ChildUnhandledEvent)"
    state.handled_child_unhandled_event = true
    return true
end

function HSM.on_event(state::TestParentChildEventHandlingChild, event::ChildHandledEvent)
    @debug "on_event(TestParentChildEventHandlingMachine, ChildHandledEvent)"
    state.handled_child_handled_event = true
    return true
end

@testset "handle_event() -- Parent state handler not called when child handles event" begin
    machine = TestParentChildEventHandlingMachine(nothing)
    child = TestParentChildEventHandlingChild(machine)
    HSM.transition_to_state(machine, child)

    HSM.handle_event(child, ChildHandledEvent())
    @test machine.handled_child_handled_event == false
    @test machine.handled_child_unhandled_event == false
    @test child.handled_child_handled_event == true
    @test child.handled_child_unhandled_event == false
end

@testset "handle_event() -- Parent state handler called when child does not handle event" begin
    
end