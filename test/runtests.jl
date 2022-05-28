using Logging
logger = ConsoleLogger(stdout, Logging.Warn)

with_logger(logger) do 
    include("test_active_state.jl")
    include("test_common_parent.jl")
    include("test_hsm_state_info.jl")
    include("test_handle_event.jl")
    include("test_root_state.jl")
    include("test_transition_to_state.jl")
    include("test_transition_to_shallow_history.jl")
    include("test_transition_to_deep_history.jl")
    include("test_thermometer.jl")
end
