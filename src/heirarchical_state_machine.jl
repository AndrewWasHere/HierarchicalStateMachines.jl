using Logging

"""
Heirarchical State Machine implementation
"""
@enum HsmResult begin
    OK
    STATE_TRANSITION_FAILED
    EVENT_NOT_HANDLED
end

"""
HsmUnhandledEventError
"""
struct HsmUnhandledEventError <: Exception
    msg::String
end

"""
Concrete events must inherit `AbstractHsmEvent`.
"""
abstract type AbstractHsmEvent end

"""
Concrete states must be mutable, inherit `AbstractHsmState`, and contain

* `parent_state::AbstractHsmState` -- initialized to the parent state of the
    concrete state, or `nothing` if it is the root state machine state.
* `active_state::AbstractHsmState` -- initialized to `nothing`.
"""
abstract type AbstractHsmState end

#####
# Internals
#####

"""
Global event handler.
This one gets called as a last resort.
"""
function on_event(state::AbstractHsmState, event::AbstractHsmEvent)
    @warn "on_event(AbstractHsmState, AbstractHsmEvent)"
    return false
end

function root_state(current_state::AbstractHsmState)
    s = current_state
    while !isnothing(s.parent)
        s = s.parent
    end
    return s
end

function active_state(current_state::AbstractHsmState)
    s = root_state(current_state)
    while !isnothing(s.active_state)
        s = s.active_state
    end
    return s
end

#####
# Public Interfaces
#####

"""
Pass event to state machine for processing.
"""
function handle_event(state_machine::AbstractHsmState, event::AbstractHsmEvent)
    handled::Bool = false

    s = active_state(state_machine)
    @warn "state: " * string(typeof(s)) * ", event: " * string(typeof(event))
    while !isnothing(s) && !(handled = on_event(s, event))
        # Event not handled by current state. Try the parent.
        s = s.parent
        @warn "state: " * string(typeof(s)) * ", event: " * string(typeof(event))
    end

    if !handled 
        # Unhandled event. This is a really good indicator that, at the very
        # least, your root state machine does not have handlers for all possible
        # events.
        throw(HsmUnhandledEventError("Unhandled Event: " * string(event)))
    end
end
