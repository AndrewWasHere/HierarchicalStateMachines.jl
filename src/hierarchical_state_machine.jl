using Logging

"""
Unhandled event exception.

This gets thrown if an event is not handled by the state machine when
`handle_event!()` is called. This usually means the root state machine state
does not have an event handler for the event type, or is not returning `true`.
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

Concrete events must extend `AbstractHsmEvent`.
"""
abstract type AbstractHsmEvent end

"""
    AbstractHsmState

Abstract HSM state type.

Concrete states must extend `AbstractHsmState`, and either contain an 
`HsmStateInfo`  struct called `state_info`, or implement the `parent_state()`, 
`parent_state!()`, `active_substate()`, and `active_substate!()` getters and 
setters. 

Pass the parent state to the HsmStateInfo constructor in the concrete state's 
constructor if using `HsmStateInfo`.

Example:

```julia
struct MyState <: AbstractHsmState
    state_info::HsmStateInfo
    app_info::MyStatefulApplicationInfo

    MyState(parent_state, app_info) = new(HSM.HsmStateInfo(parent_state), app_info)
end
```

Otherwise, call `parent_state(obj, <parent state>)` and 
`active_substate(obj, nothing)` when constructing your concrete state.
"""
abstract type AbstractHsmState end

"""
    parent_state(obj::AbstractHsmState)

parent_state getter. 

Extend this for your concrete class if your concrete struct does not include 
`state_info::HsmStateInfo`.
"""
function parent_state(obj::AbstractHsmState)
    obj.state_info.parent_state
end

"""
    parent_state!(obj::AbstractHsmState, value::Union{AbstractHsmState, Nothing})

parent_state setter.

Extend this for your concrete class if your concrete struct does not include 
`state_info::HsmStateInfo`.
"""
function parent_state!(obj::AbstractHsmState, value::Union{AbstractHsmState, Nothing})
    obj.state_info.parent_state = value
end

"""
    active_substate(obj::AbstracHsmState)

active_substate getter.

Extend this for your concrete class if your concrete struct does not include 
`state_info::HsmStateInfo`.
"""
function active_substate(obj::AbstractHsmState)
    obj.state_info.active_substate
end

"""
    active_substate!(obj::AbstractHsmState, value::Union{AbstractHsmState, Nothing})

active_substate setter.

Extend this for your concrete class if your concrete struct does not include 
`state_info::HsmStateInfo`.
"""
function active_substate!(obj::AbstractHsmState, value::Union{AbstractHsmState, Nothing})
    obj.state_info.active_substate = value
end

"""
    HsmStateInfo

State information needed by HSM interfaces that act on `AbstractHsmState`s.

* `parent_state::AbstractHsmState` -- initialized to the parent state of the
    concrete state, or `nothing` if it is the root state machine state.
* `active_substate::AbstractHsmState` -- initialized to `nothing`.
"""
mutable struct HsmStateInfo
    parent_state::Union{AbstractHsmState, Nothing}
    active_substate::Union{AbstractHsmState, Nothing}

    """
        HsmStateInfo(parent_state::Union{AbstractHsmState, Nothing})

    Constructor for HsmStateInfo.

    `parent_state` argument is the state containing the current state, or 
    `nothing`, if the state is the root state machine.
    """
    function HsmStateInfo(parent_state)
        new(parent_state, nothing)
    end
end

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
    @debug "on_event!(AbstractHsmState, AbstractHsmEvent) for ($(string(typeof(state))), $(string(typeof(event))))"
    return false
end

"""
    on_entry!(state::AbstractHsmState)

Global state entry handler.

Create entry handlers for your derived states when you want that state to 
execute something whenever it is entered. This includes transitions to itself.

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
    @debug "on_entry!(AbstractHsmState) for $(string(typeof(state)))"
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
    @debug "on_exit!(AbstractHsmState) for $(string(typeof(state)))"
    # do nothing.
end

"""
    on_initialize!(state::AbstractHsmState)

Global state initializer.

Create initializers for states that must be initialized upon entry. Generally,
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
    @debug "on_initialize!(AbstractHsmState) for $(string(typeof(state)))"
    # Do nothing.
end

#####
# Internals
#####

"""
    root_state(current_state::AbstractHsmState)

Returns the root state of `current_state`.

Follows the state's parent state up, until there is no more parent state.

Example:

Given the following state machine:

```plantuml
@startuml
state A {
    state B
    state C {
        state D
        state E
    }
}
@enduml
```

The root state of any state in the state machine is `A`.
"""
function root_state(current_state::AbstractHsmState)
    s = current_state
    while !isnothing(parent_state(s))
        s = parent_state(s)
    end
    return s
end

"""
    active_state(current_state::AbstractHsmState)

Returns the active state of the state machine that `current_state` resides in.

Example:

Given the following state machine:

```plantuml
@startuml
state A {
    state B
    state C {
        state D
        state E
    }
}
@enduml

If state `B` is the last state transitioned to, then the active state for any
state in the state machine will be `B`.
```
"""
function active_state(current_state::AbstractHsmState)
    s = root_state(current_state)
    while !isnothing(active_substate(s))
        s = active_substate(s)
    end
    return s
end

"""
    common_parent(left_state::AbstractHsmState, right_state::AbstractHsmState)

Returns the common parent of `left_state` and `right_state`.

Example:

Given the following state machine:

```plantuml
@startuml
state A {
    state B
    state C {
        state D
        state E
    }
}
@enduml
```

The common parent of `A` and any other state is `A`.

The common parent of `B` and any other state is `A`.

The common parent of `C` and any of its substates is `C`.

The common parent of `D` and `E` is `C`.
"""
function common_parent(
    left_state::AbstractHsmState, 
    right_state::AbstractHsmState
)
    l = left_state
    while !isnothing(l)
        r = right_state
        while !isnothing(r)
            if r == l
                # Common parent found.
                return r
            end

            r = parent_state(r)
        end

        l = parent_state(l)
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
        s = parent_state(s)
    end

    if !handled 
        # Unhandled event. This is a really good indicator that, at the very
        # least, your root state machine does not have handlers for all possible
        # events.
        throw(
            HsmUnhandledEventError("Unhandled Event: $(string(typeof(event))). Does your root state machine have an event handler (`on_event!()`) for this event?")
        )
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
function transition_to_state!(
    state_machine::AbstractHsmState, 
    state::AbstractHsmState
)
    @debug "transition_to_state!($(string(typeof(state_machine))), $(string(typeof(state))))"
    
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

    # Call `on_exit!()` from active state up to, but not including common 
    # parent.
    while s != cp
        on_exit!(s)
        s = parent_state(s)
    end

    # Update active state pointers from common parent to `state`.
    active_substate!(state, nothing)
    s = state
    while s != cp
        active_substate!(parent_state(s), s)
        s = parent_state(s)
    end

    # Call `on_entry!()` for common parent's active state to `state`.
    s = active_substate(cp)
    while !isnothing(s)
        on_entry!(s)
        s = active_substate(s)
    end

    on_initialize!(state)
end

"""
    transition_to_shallow_history!(state_machine::AbstractHsmState, state::AbstractHsmState)

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

    MyState --> MyOtherState[H]
}
@enduml
```
"""
function transition_to_shallow_history!(
    state_machine::AbstractHsmState, 
    state::AbstractHsmState
)
    @debug "transition_to_shallow_history!($(string(typeof(state_machine))), $(string(typeof(state))))"

    as = active_substate(state)
    s = isnothing(as) ? state : as
    transition_to_state!(state_machine, s)
end

"""
    transition_to_deep_history!(state_machine::AbstractHsmState, state::AbstractHsmState)

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
function transition_to_deep_history!(
    state_machine::AbstractHsmState, 
    state::AbstractHsmState
)
    @debug "transition_to_deep_history!($(string(typeof(state_machine))), $(string(typeof(state))))"

    s = state
    while !isnothing(active_substate(s))
        s = active_substate(s)
    end
    transition_to_state!(state_machine, s)
end
