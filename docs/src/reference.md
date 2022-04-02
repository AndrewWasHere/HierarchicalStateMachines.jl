# Package Reference

## Abstract Types

The following abstract types are used to derive concrete state and event types.

```@docs
AbstractHsmEvent
AbstractHsmState
```

## Public Interfaces

The following HSM interfaces are used in state machine implementations.

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

## Exceptions

The following exceptions are defined and used by HSM.

```@docs
HsmUnhandledEventError
HsmStateTransitionError
```
