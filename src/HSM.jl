module HSM

include("hierarchical_state_machine.jl")

# Types
export AbstractHsmEvent, AbstractHsmState, HsmStateInfo, 
    HsmStateTransitionError, HsmUnhandledEventError

# Interfaces
export handle_event!, transition_to_deep_history!, 
    transition_to_shallow_history!, transition_to_state!

# Extendable Interfaces
export on_entry!, on_event!, on_exit!, on_initialize!

# Getters and setters
export active_substate, active_substate!, parent_state, parent_state!

end # module
