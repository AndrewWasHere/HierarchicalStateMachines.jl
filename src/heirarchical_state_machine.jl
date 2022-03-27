using Logging

"""
Unhandled event exception.
"""
struct HsmUnhandledEventError <: Exception
    msg::String
end

"""
State transition failed exception.
"""
struct HsmStateTransitionError <: Exception
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
# Global Handlers
#####

"""
Global event handler.

State-specific event handlers are expected to return `true` when they handle an
event, unless they specifically want their parent state to process the event as
well.

This one gets called as a last resort, and is expected to return `false` to 
propagate the event up parent state machine states.
"""
function on_event(state::AbstractHsmState, event::AbstractHsmEvent)
    @debug "on_event(AbstractHsmState, AbstractHsmEvent)"
    return false
end

"""
Global state entry handler.
This is the default behavior of a state.
"""
function on_entry(state::AbstractHsmState)
    @debug "on_entry(AbstractHsmState)"
    # do nothing.
end

"""
Global state exit handler.
This is the default behavior of a state.
"""
function on_exit(state::AbstractHsmState)
    @debug "on_exit(AbstractHsmState)"
    # do nothing.
end

"""
Global state initializer.
This is the default behavior of a state.
"""
function on_initialize(state::AbstractHsmState)
    @debug "on_initialize(AbstractHsmState)"
    # Do nothing.
end

#####
# Internals
#####

function root_state(current_state::AbstractHsmState)
    s = current_state
    while !isnothing(s.parent_state)
        s = s.parent_state
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

function common_parent(left_state::AbstractHsmState, right_state::AbstractHsmState)
    if isnothing(left_state) || isnothing(right_state)
        return nothing
    end

    if (
        left_state == right_state &&
        isnothing(left_state.parent) &&
        isnothing(right_state.parent)
    )
        # `left_state` and `right_state` are the root machine state.
        return left_state
    end

    l = left_state
    while !isnothing(l)
        r = right_state
        while !isnothing(r)
            if r == l
                # Common parent found.
                return r
            end
            r = r.parent_state
        end

        l = l.parent_state
    end

    # No common parent.
    return nothing
end

#####
# Public Interfaces
#####

"""
Pass event to state machine for processing.
"""
function handle_event(state_machine::AbstractHsmState, event::AbstractHsmEvent)
    @debug "handle_event($(string(typeof(state_machine))), $(string(typeof(event))))"
    handled::Bool = false

    s = active_state(state_machine)
    while !isnothing(s) && !(handled = on_event(s, event))
        # Event not handled by current state. Try the parent.
        s = s.parent_state
    end

    if !handled 
        # Unhandled event. This is a really good indicator that, at the very
        # least, your root state machine does not have handlers for all possible
        # events.
        throw(HsmUnhandledEventError("Unhandled Event: " * string(event)))
    end
end

"""
Change the active state of the state machine.
"""
function transition_to_state(machine::AbstractHsmState, state::AbstractHsmState)
    @debug "transition_to_state($(string(typeof(machine))), $(string(typeof(state))))"
    
    s = active_state(machine)
    cp = common_parent(s, state)

    if isnothing(cp)
        throw(
            HsmStateTransitionError(
                "Destination state " * 
                string(typeof(state)) * 
                " does not exist in state machine " * 
                string(typeof(machine))
            )
        )
    end

    # Call `on_exit()` from active state to common parent.
    while s != cp.parent_state
        on_exit(s)
        s = s.parent_state
    end

    # Update active state pointers from common parent to `state`.
    s = state
    while s != cp
        s.parent_state.active_state = s
        s = s.parent_state
    end

    # Call `on_entry()` for common parent's active state to `state`.
    s = cp.active_state
    while !isnothing(s)
        on_entry(s)
        s = s.active_state
    end

    on_initialize(state)
end