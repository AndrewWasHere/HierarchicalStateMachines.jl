using Logging

macro transition_tests_state(name)
    return :(
        mutable struct $name <: HSM.AbstractHsmState
            parent_state::Union{HSM.AbstractHsmState, Nothing}
            active_state::Union{HSM.AbstractHsmState, Nothing}

            function $name(parent_state, active_state)
                if !isnothing(active_state)
                    error("active_state must be `nothing`")
                end
                new(parent_state, active_state)
            end
        end
    )
end
