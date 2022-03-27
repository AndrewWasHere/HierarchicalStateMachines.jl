using Logging, Test, HSM

struct ChildHandledEvent <: HSM.AbstractHsmEvent
end

struct ChildUnhandledEvent <: HSM.AbstractHsmEvent
end

mutable struct TestParentChildEventHandlingMachine <: HSM.AbstractHsmState
    parent_state::Union{HSM.AbstractHsmState, Nothing}
    active_state::Union{HSM.AbstractHsmState, Nothing}
    handled_child_handled_event::Bool
    handled_child_unhandled_event::Bool

    function TestParentChildEventHandlingMachine(
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

TestParentChildEventHandlingMachine(parent_state) = TestParentChildEventHandlingMachine(
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

@testset "handle_event() -- Parent state handler not called when child handles event" begin
    machine = TestParentChildEventHandlingMachine(nothing)
end

@testset "handle_event() -- Parent state handler called when child does not handle event" begin
    
end