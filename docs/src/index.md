# HSM.jl

Heirarchical state macine library based on Unified Modeling Language state
machines (also called statecharts).

Heirarchcial state machines allow for the use of sub-states within states.
This can reduce boilerplate actions in similar states by encapsulating those
states in a parent state, and moving the boilerplate action to the parent state.

## Installation

You can obtain HSM using Julia's Package Manager REPL.

```julia
pkg> add https://github.com/AndrewWasHere/HSM.jl.git
```

Or directly from the Julia REPL.

```julia
using Pkg
Pkg.add(url="https://github.com/AndrewWasHere/HSM.jl.git")
```

## Use

The general procedure for implementing a state machine using HSM is to create
a `mutable struct` derived from `AbstractHsmState` for every state in the state 
machine, as well as the state machine itself. Each derived struct must contain,
at a minimum, `parent_state::AbstractHsmState` and 
`active_state::AbstractHsmState`. Generally speaking, there will also be a
reference to a container holding process data to be acted upon.

For every event handled by the state machine, create a `struct` derived from 
`AbstractHsmEvent`. There are no required fields for the stuct derived from
`AbstractHsmEvent`.

Instantiate one instance of each state. Top-level states pass the state machine
instance as the `parent_state` argument to its constructor. Sub-states pass
their parent state instance as the `parent_state` argument to its constructor.
The root state machine state passes `nothing` as the parent state.

Extend `on_event!()` to handle specific events in specific states. Similarly, 
extend `on_entry!()`, `on_exit!()`, and `on_initialize!()` as necessary. Be sure 
the root state machine state handles all expected events, and returns `true` in 
each `on_event!()` extension.

Use `transition_to_state!()`, `transition_to_shallow_history!()`, and
`transition_to_deep_history!()` in your event handlers to effect state
transitions.

Finally, in your event loop, pass events to the state machine by calling
`handle_event!()`.

See [test_thermometer.jl](https://github.com/AndrewWasHere/HSM.jl/blob/main/test/test_thermometer.jl) 
for a concrete example, minus the event loop.
