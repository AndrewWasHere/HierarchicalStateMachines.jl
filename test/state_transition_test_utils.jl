using Logging

macro transition_tests_state(name)
    return :(
        struct $name <: HSM.AbstractHsmState
            state_info::HSM.HsmStateInfo

            $name(parent_state) = new(HSM.HsmStateInfo(parent_state))
        end
    )
end
