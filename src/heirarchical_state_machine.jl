using Logging

"""
Unhandled event exception.

This gets thrown if an event is not handled by the state machine when
`handle_event!()` is called.
"""
struct HsmUnhandledEventError <: Exception
    msg::String
end

"""
State transition failed exception.

This gets thrown if the destination state is not a part of the state machine
when `transition_to_state!()` is called.
"""
struct HsmStateTransitionError <: Exception
    msg::String
end

"""
    AbstractHsmEvent

Abstract HSM event type.

Concrete events must inherit `AbstractHsmEvent`.
"""
abstract type AbstractHsmEvent end

"""
    AbstractHsmState

Abstract HSM state type.

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
    on_event!(state::AbstractHsmState, event::AbstractHsmEvent)

Global event handler.

Create event handlers for your derived states and events to handle those
specific events in those states.

```julia
struct MyState <: HSM.AbstractHsmState ; end
struct MyEvent <: HSM.AbstractHsmEvent ; end

function on_event!(state::MyState, event::MyEvent)
    # process event.
    return true
end
```

State-specific event handlers are expected to return `true` when they handle an
event, unless they specifically want their parent state to process the event as
well.

State-specific instances of `on_event!()` correspond to "event / action" labels
in state blocks or on state transitions in UML state charts.

```plantuml
@startuml
state ExampleMachine {
    state MyState 
    state MyOtherState

    MyState --> MyOtherState : MyEvent / do something
    MyOtherState : MyEvent / do something
}
@enduml
```

The global event handler is called as a last resort, and is expected to return 
`false` to generate an `HsmUnhandledEventError`.
"""
function on_event!(state::AbstractHsmState, event::AbstractHsmEvent)
    @debug "on_event!(AbstractHsmState, AbstractHsmEvent)"
    return false
end

"""
    on_entry!(state::AbstractHsmState)

Global state entry handler.

Create entry handlers for your derived states when you want that state to execute
something whenever it is entered. This includes transitions to itself.

```julia
struct MyState <: HSM.AbstractHsmState ; end

function on_entry!(state::MyState)
    # do something.
end
```

State-specific instances of `on_entry!()` correspond to "on entry / action"
labels in state blocks in UML state charts.

```plantuml
@startuml
state Machine {
    state MyState
    MyState : on entry / do something
}
@enduml
```

The global state entry handler is the default behavior of a state. It does not
do anything.
"""
function on_entry!(state::AbstractHsmState)
    @debug "on_entry!(AbstractHsmState)"
    # do nothing.
end

"""
    on_entry!(state::AbstractHsmState)

Global state exit handler.

Create exit handlers for your derived states when you want that state to execute
something whenever it is exited. This includes transitions to itself.

```julia
struct MyState <: HSM.AbstractHsmState ; end

function on_exit!(state::MyState)
    # do something.
end
```

State-specific instances of `on_exit!()` correspond to "on exit / action"
labels in state blocks in UML state charts.

```plantuml
@startuml
state Machine {
    state MyState
    MyState : on exit / do something
}
@enduml
```

The global state exit handler is the default behavior of a state. It does not do 
anything.
"""
function on_exit!(state::AbstractHsmState)
    @debug "on_exit!(AbstractHsmState)"
    # do nothing.
end

"""
    on_initialize!(state::AbstractHsmState)

Global state initializer.

Create initialiers for states that must be initialized upon entry. Generally,
this is used when a state has sub-states, where one must be transitioned to
when the state is entered. For example, the root state machine.

```julia
struct Machine <: HSM.AbstractHsmState ; end
struct MyState <: HSM.AbstractHsmState ; end

machine = Machine(nothing)
my_state = MyState(machine)

function on_initialize!(state::Machine)
    transition_to_state!(my_state)
end
```

State-specific instances of `on_initialize!()` correspond to the starting point 
trasitions in UML state charts.

```plantuml
@startuml
state Machine {
    state MyState

    [*] --> MyState
}
@enduml
```

The global state initializer is the default behavior of a state. It does not do 
anything.
"""
function on_initialize!(state::AbstractHsmState)
    @debug "on_initialize!(AbstractHsmState)"
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
        isnothing(left_state.parent_state) &&
        isnothing(right_state.parent_state)
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
    handle_event!(state_machine::AbstractHsmState, event::AbstractHsmEvent)

Pass `event` to `state_machine` for processing.

This is the public interface to use to pass an event to a state machine for
processing.
"""
function handle_event!(state_machine::AbstractHsmState, event::AbstractHsmEvent)
    @debug "handle_event!($(string(typeof(state_machine))), $(string(typeof(event))))"
    
    handled = false

    s = active_state(state_machine)
    while !isnothing(s) && !(handled = on_event!(s, event))
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
    transition_to_state!(machine::AbstractHsmState, state::AbstractHsmState)

Change the active state of `state_machine` to `state`.

This is the interface to use in a state's event handler (`on_event!()`, 
`on_initialize()`) to transition states.

```julia
struct Machine <: HSM.AbstractHsmState ; end
struct MyState <: HSM.AbstractHsmState ; end
struct MyOtherState <: HSM.AbstractHsmState ; end
struct MyEvent <: HSM.AbstractHsmEvent ; end

machine = Machine(nothing)
my_state = MyState(machine)
my_other_state = MyOtherState(machine)

function on_event!(state::MyState, event::MyEvent)
    # Active state becomes my_other_state.
    transition_to_state!(machine, my_other_state)
end
```

This interface corresponds to arrows from one state to another in a UML state
chart.

```plantuml
@startuml
state Machine {
    state MyState
    state MyOtherState

    MyState --> MyOtherState
}
@enduml
```
"""
function transition_to_state!(state_machine::AbstractHsmState, state::AbstractHsmState)
    @debug "transition_to_state!($(string(typeof(machine))), $(string(typeof(state))))"
    
    s = active_state(state_machine)
    cp = common_parent(s, state)

    if isnothing(cp)
        throw(
            HsmStateTransitionError(
                "Destination state " * 
                string(typeof(state)) * 
                " does not exist in state machine " * 
                string(typeof(state_machine))
            )
        )
    end

    # Call `on_exit()` from active state to common parent.
    while s != cp.parent_state
        on_exit!(s)
        s = s.parent_state
    end

    # Update active state pointers from common parent to `state`.
    state.active_state = nothing
    s = state
    while s != cp
        s.parent_state.active_state = s
        s = s.parent_state
    end

    # Call `on_entry()` for common parent's active state to `state`.
    s = cp.active_state
    while !isnothing(s)
        on_entry!(s)
        s = s.active_state
    end

    on_initialize!(state)
end

"""
    transition_to_shallow_history(state_machine::AbstractHsmState, state::AbstractHsmState)

Change the active state of `state_machine`, following the active state of
`state` as much as one layer.

This is the interface to use in a state's event handler (`on_event!()`) to 
transition to the history of a state.

```julia
struct Machine <: HSM.AbstractHsmState ; end
struct MyState <: HSM.AbstractHsmState ; end
struct MyOtherState <: HSM.AbstractHsmState ; end
struct MySubState1 <: HSM.AbstractHsmState ; end
struct MySubState2 <: HSM.AbstractHsmEvent ; end
struct MyEvent <: HSM.AbstractHsmEvent ; end

machine = Machine(nothing)
my_state = MyState(machine)
my_other_state = MyOtherState(machine)
my_sub_state_1 = MySubState1(my_other_state)
my_sub_state_2 = MySubState2(my_other_state)

function on_event!(state::MyState, event::MyEvent)
    # Will transition to last active state in my_other_state -- my_other_state,
    # my_sub_state_1, or my_sub_state_2.
    transition_to_shallow_history!(machine, my_other_state)
end
```

This interface corresponds to an arrow to a history marker in a state.

```plantuml
@startuml
state Machine {
    state MyState
    state MyOtherState {
        state MySubState1
        state MySubState2
    }

    MyState --> MyStateWithHistory[H]
}
@enduml
```
"""
function transition_to_shallow_history!(state_machine::AbstractHsmState, state::AbstractHsmState)
    @debug "transition_to_shallow_history!($(string(typeof(state_machine))), $(string(typeof(state))))"

    s = isnothing(state.active_state) ? state : state.active_state
    transition_to_state!(state_machine, s)
end

"""
    transition_to_deep_history(state_machine::AbstractHsmState, state::AbstractHsmState)

Change the active state of `state_machine`, following the active state of
`state` as far as it goes.

This is the interface to use in a state's event handler (`on_event!()`) to 
transition to the deep history of a state.

```julia
struct Machine <: HSM.AbstractHsmState ; end
struct MyState <: HSM.AbstractHsmState ; end
struct MyOtherState <: HSM.AbstractHsmState ; end
struct MySubState1 <: HSM.AbstractHsmState ; end
struct MySubState2 <: HSM.AbstractHsmEvent ; end
struct MySubSubState1 <: HSM.AbstractHsmEvent ; end
struct MySubSubState2 <: HSM.AbstractHsmEvent ; end
struct MyEvent <: HSM.AbstractHsmEvent ; end

machine = Machine(nothing)
my_state = MyState(machine)
my_other_state = MyOtherState(machine)
my_sub_state_1 = MySubState1(my_other_state)
my_sub_state_2 = MySubState2(my_other_state)
my_sub_sub-state_1 = MySubSubState1(my_sub_state_1)
my_sub_sub-state_2 = MySubSubState2(my_sub_state_1)

function on_event!(state::MyState, event::MyEvent)
    # Will transition last active state in my_other_state -- my_other_state,
    # my_sub_state_1, my_sub-state_2, my_sub_sub_state_1, or my_sub_sub_state_2.
    transition_to_shallow_history!(machine, my_other_state)
end
```
This interface corresponds to an arrow to a deep history marker in a state.

```plantuml
@startuml
state Machine {
    state MyState
    state MyOtherState {
        state MySubState1 {
            state MySubSubState1
            state MySubSubState2
        }
        state MySubState2
    }

    MyState --> MyOtherState[H*]
}
@enduml
```
"""
function transition_to_deep_history!(state_machine::AbstractHsmState, state::AbstractHsmState)
    @debug "transition_to_deep_history!($(string(typeof(state_machine))), $(string(typeof(state))))"

    s = state
    while !isnothing(s.active_state)
        s = s.active_state
    end
    transition_to_state!(state_machine, s)
end
