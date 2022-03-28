using Logging
logger = ConsoleLogger(stdout, Logging.Debug)

with_logger(logger) do 
    include("test_handle_event.jl")
    include("test_transition_to_state.jl")
    include("test_transition_to_shallow_history.jl")
    include("test_transition_to_deep_history.jl")
end
