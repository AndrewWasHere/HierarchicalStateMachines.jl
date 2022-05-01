# HSM.jl

Hierarchical state machine library based on Unified Modeling Language state
machines (also called state charts).

Hierarchical state machines allow for the use of sub-states within states.
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
a (possibly mutable) `struct` derived from `AbstractHsmState` for every state in 
the state machine, as well as the state machine itself. Each derived struct must 
contain, at a minimum, `state_info::HSM.HsmStateInfo`. Generally speaking, there 
will also be a reference to a container holding process data to be acted upon.

For every user-defined event handled by the state machine, create a `struct` 
derived from `AbstractHsmEvent`. There are no required fields for the struct 
derived from `AbstractHsmEvent`.

Instantiate one instance of each state. Top-level states pass the state machine
instance as the `parent_state` argument to its contained `state_info`. 
Sub-states pass their parent state instance as the `parent_state`. The root 
state machine state passes `nothing` as the parent state.

For example, to create a state machine called `MyStateMachine` that contains
two states `FooState` and `BarState`, you would define three concrete 
derivations of `AbstractHsmState` containing a minimum of a `state_info` field.
Their constructors would take a `parent_state` argument that got passed to the
`HsmStateInfo` constructor for `state_info`.

```julia
struct MyStateMachine <: HSM.AbstractHsmState
    state_info::HSM.HsmStateInfo

    MyStateMachine(parent) = new(HSM.HsmStateInfo(parent))
end

struct FooState <: HSM.AbstractHsmState
    state_info::HSM.HsmStateInfo

    FooState(parent) = new(HSM.HsmStateInfo(parent))
end

struct BarState <: HSM.AbstractHsmState
    state_info::HSM.HsmStateInfo

    BarState(parent) = new(HSM.HsmStateInfo(parent))
end

my_state_machine = MyStateMachine(nothing)
foo_state = FooState(my_state_machine)
bar_state = BarState(my_state_machine)
```

Extend `on_event!()` to handle specific events in specific states. Similarly, 
extend `on_entry!()`, `on_exit!()`, and `on_initialize!()` as necessary. Be sure 
event handlers for the root state machine state handle all expected events, and 
return `true` in each `on_event!()` extension.

Use `transition_to_state!()`, `transition_to_shallow_history!()`, and
`transition_to_deep_history!()` in your event handlers to effect state
transitions.

Finally, in your event loop, pass events to the state machine by calling
`handle_event!()`.

See [test_thermometer.jl](https://github.com/AndrewWasHere/HSM.jl/blob/main/test/test_thermometer.jl) 
for a concrete example, minus the event loop.
