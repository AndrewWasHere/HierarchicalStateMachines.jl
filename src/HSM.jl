module HSM

include("heirarchical_state_machine.jl")

# Types
export AbstractHsmEvent, AbstractHsmState, HsmStateInfo, 
    HsmStateTransitionError, HsmUnhandledEventError

# Interfaces
export handle_event!, transition_to_deep_history!, 
    transition_to_shallow_history!, transition_to_state!

# Extendable Interfaces
export on_entry!, on_event!, on_exit!, on_initialize!

end # module
