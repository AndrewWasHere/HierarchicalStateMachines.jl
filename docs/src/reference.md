# Package Reference

## Abstract Types

The following abstract types are used to derive concrete state and event types.

```@docs
AbstractHsmEvent
AbstractHsmState
HsmStateInfo
```

## Public Interfaces

The following HierarchicalStateMachines interfaces are used in state machine 
implementations.

```@docs
handle_event!(state_machine::AbstractHsmState, event::AbstractHsmEvent)
transition_to_deep_history!(state_machine::AbstractHsmState, state::AbstractHsmState)
transition_to_shallow_history!(state_machine::AbstractHsmState, state::AbstractHsmState)
transition_to_state!(state_machine::AbstractHsmState, state::AbstractHsmState)
```

## Extendable Interfaces

The following interfaces are extended to implement event handlers for specific
states and events.

```@docs
on_entry!(state::AbstractHsmState)
on_event!(state::AbstractHsmState, event::AbstractHsmEvent)
on_exit!(state::AbstractHsmState)
on_initialize!(state::AbstractHsmState)
```

## Extendable Getters and Setters

The following getters and setters are extended to implement the required parent
and active state requirements for concrete implementations of 
`AbstractHsmState`. Extending the getters and setters is only necessary if
the concrete implementation does not have a `state_info::HsmStateInfo` member.

```@docs
active_substate(obj::AbstractHsmState)
active_substate!(obj::AbstractHsmState, value::Union{AbstractHsmState, Nothing})
parent_state(obj::AbstractHsmState)
parent_state!(obj::AbstractHsmState, value::Union{AbstractHsmState, Nothing})
```

## Exceptions

The following exceptions are defined and used by HierarchicalStateMachines.

```@docs
HsmUnhandledEventError
HsmStateTransitionError
```
