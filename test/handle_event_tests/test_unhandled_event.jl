using Logging, Test, HSM

struct HandledEvent <: HSM.AbstractHsmEvent
end

struct UnhandledEvent <: HSM.AbstractHsmEvent
end

"""
Handle Event tests state machine.
"""
mutable struct TestUnhandledEventMachine <: HSM.AbstractHsmState
    parent_state::Union{HSM.AbstractHsmState, Nothing}
    active_state::Union{HSM.AbstractHsmState, Nothing}
    handled_event::Bool
    
    function TestUnhandledEventMachine(parent_state, active_state, handled_event)
        if !isnothing(active_state) 
            error("active_state must be `nothing`.")
        elseif handled_event
            error("handled_event must be `false`.")
        end
        new(parent_state, active_state, handled_event)
    end
end

TestUnhandledEventMachine(parent_state) = TestUnhandledEventMachine(parent_state, nothing, false)

# TestUnhandledEventMachineState event handlers.
# This test deliberately does not handle all events in the root machine state.
# In practice, your root machine state must have `on_event()` event handlers
# for all possible state machine events, otherwise the machine may raise an
# exception, and end up in an unexpected state.
function HSM.on_event!(state::TestUnhandledEventMachine, event::HandledEvent)
    @debug "on_event!(TestUnhandledEventMachine, HandledEvent)"
    state.handled_event = true
    return true
end

@testset "handle_event!() -- HSM guards against unhandled events." begin
    machine = TestUnhandledEventMachine(nothing)

    # Unhandled event should throw an error and not set `handled_event`.
    @test_throws HSM.HsmUnhandledEventError HSM.handle_event!(machine, UnhandledEvent())
    @test !machine.handled_event

    # Handled event should not throw an error and set `handled_event`.
    HSM.handle_event!(machine, HandledEvent())
    @test machine.handled_event
    
end