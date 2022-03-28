module HSM

include("heirarchical_state_machine.jl")

# Types
export HsmStateTransitionError, HsmUnhandledEventError

# Interfaces
export handle_event!, transition_to_deep_history!, 
    transition_to_shallow_history!, transition_to_state!

end # module
