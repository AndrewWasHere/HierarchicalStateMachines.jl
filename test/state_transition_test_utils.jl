using Logging

macro transition_tests_state(name)
    return :(
        mutable struct $name <: HSM.AbstractHsmState
            state_info::HSM.HsmStateInfo
            entered::Bool
            exited::Bool

            $name(parent_state) = new(HSM.HsmStateInfo(parent_state), false, false)
        end
    )
end

function reset_transition_test_state!(s)
    s.entered = false
    s.exited = false
end