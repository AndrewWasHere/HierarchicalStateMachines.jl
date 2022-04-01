"""
Thermometer state machine:

@startuml
state ThermometerStateMachine {
    state OffState {
        on entry / set display to "off".
    }
    state OnState {
        on entry / set display to "--".
        TemperatureEvent : set display to converted temperature value.

        CelsiusState {
            on entry / set converter to celsius.
        }
        FarenheitState {
            on entry / set converter to farenheit.
        }
        KelvinState {
            on entry / set converter to kelvin.
        }

        [*] --> CelsiusState
        CelsiusState -> FarenheitState : UnitsEvent
        FarenheitState -> KelvinState : UnitsEvent
        KelvinState -> CelsiusState : UnitsEvent
    }

    [*] --> OffState
    OffState -> OnState : PowerEvent
    OnState -> OffState : PowerEvent
}
@enduml
"""

using Logging, Test, HSM

#####
# Temperature converter functions.
#####

celsius(t::Float64) = string(round(t, digits=1)) * "°C"
farenheit(t::Float64) = string(round((t * 1.8) + 32.0, digits=1)) * "°F"
kelvin(t::Float64) = string(round(t + 273.15, digits=1)) * "K"

#####
# Thermometer model.
#####

mutable struct Thermometer
    display::String
    temperature::Union{Float64, Nothing}
    convert::Function

    function Thermometer(display="", temperature=nothing, convert=celsius)
        new(display, temperature, convert)
    end
end

thermometer = Thermometer()

#####
# Events.
#####

struct PowerEvent <: HSM.AbstractHsmEvent
end

struct UnitsEvent <: HSM.AbstractHsmEvent
end

struct TemperatureEvent <:HSM.AbstractHsmEvent
    temperature::Float64
end

#####
# State machine.
#####

macro thermometer_state(name)
    return :(
        mutable struct $name <: HSM.AbstractHsmState
            parent_state::Union{HSM.AbstractHsmState, Nothing}
            active_state::Union{HSM.AbstractHsmState, Nothing}
            thermometer::Thermometer
        end
    )
end

@thermometer_state(ThermometerStateMachine)
@thermometer_state(OffState)
@thermometer_state(OnState)
@thermometer_state(CelsiusState)
@thermometer_state(FarenheitState)
@thermometer_state(KelvinState)

thermometer_state_machine = ThermometerStateMachine(nothing, nothing, thermometer)
off_state = OffState(thermometer_state_machine, nothing, thermometer)
on_state = OnState(thermometer_state_machine, nothing, thermometer)
celsius_state = CelsiusState(on_state, nothing, thermometer)
farenheit_state = FarenheitState(on_state, nothing, thermometer)
kelvin_state = KelvinState(on_state, nothing, thermometer)

# Root state machine state event handlers.
# The root state machine state must handle all possible user-defined events --
# defining `on_event!()` functions for each -- which return `true` to avoid
# UnhandledExceptionErrors being thrown.

function HSM.on_initialize!(state::ThermometerStateMachine)
    @debug "on_initialize(ThermometerStateMachine)"
    HSM.transition_to_state!(thermometer_state_machine, off_state)
end

function HSM.on_event!(state::ThermometerStateMachine, event::PowerEvent)
    @debug "on_event!(ThermometerStateMachine, PowerEvent)"
    return true
end

function HSM.on_event!(state::ThermometerStateMachine, event::UnitsEvent)
    @debug "on_event!(ThermometerStateMachine, UnitsEvent)"
    return true
end

function HSM.on_event!(state::ThermometerStateMachine, event::TemperatureEvent)
    @debug "on_event!(ThermometerStateMachine, TemperatureEvent)"
    return true
end

# Off state event handlers.

function HSM.on_entry!(state::OffState)
    @debug "on_entry(OffState)"
    state.thermometer.display = "off"
end

function HSM.on_event!(state::OffState, event::PowerEvent)
    @debug "on_event(OffState, PowerEvent)"
    HSM.transition_to_deep_history!(thermometer_state_machine, on_state)
    return true
end

# On state event handlers.

function HSM.on_initialize!(state::OnState)
    @debug "on_initialize!(OnState)"
    HSM.transition_to_state!(thermometer_state_machine, celsius_state)
end

function HSM.on_entry!(state::OnState)
    @debug "on_entry!(OnState)"
    state.thermometer.display = "--"
end

function HSM.on_event!(state::OnState, event::PowerEvent)
    @debug "on_event!(OnState, PowerEvent)"
    HSM.transition_to_state!(thermometer_state_machine, off_state)
    return true
end

function HSM.on_event!(state::OnState, event::TemperatureEvent)
    @debug "on_event!(OnState, TemperatureEvent)"
    state.thermometer.display = state.thermometer.convert(event.temperature)
    state.thermometer.temperature = event.temperature
    return true
end

# Celsius state event handlers.

function HSM.on_entry!(state::CelsiusState)
    @debug "on_entry!(CelsiusState)"
    state.thermometer.convert = celsius
    if !isnothing(state.thermometer.temperature)
        state.thermometer.display = state.thermometer.convert(state.thermometer.temperature)
    end
end

function HSM.on_event!(state::CelsiusState, event::UnitsEvent)
    @debug "on_event!(CelsiusState, UnitsEvent)"
    HSM.transition_to_state!(thermometer_state_machine, farenheit_state)
    return true
end

# Farenheit state event handlers.

function HSM.on_entry!(state::FarenheitState)
    @debug "on_entry!(FarenheitState)"
    state.thermometer.convert = farenheit
    if !isnothing(state.thermometer.temperature)
        state.thermometer.display = state.thermometer.convert(state.thermometer.temperature)
    end
end

function HSM.on_event!(state::FarenheitState, event::UnitsEvent)
    @debug "on_event!(FarenheitState, UnitsEvent)"
    HSM.transition_to_state!(thermometer_state_machine, kelvin_state)
    return true
end

# Kelvin state event handlers.

function HSM.on_entry!(state::KelvinState)
    @debug "on_entry!(KelvinState)"
    state.thermometer.convert = kelvin
    if !isnothing(state.thermometer.temperature)
        state.thermometer.display = state.thermometer.convert(state.thermometer.temperature)
    end
end

function HSM.on_event!(state::KelvinState, event::UnitsEvent)
    @debug "on_event!(KelvinState, UnitsEvent)"
    HSM.transition_to_state!(thermometer_state_machine, celsius_state)
    return true
end

#####
# Exercise / Test state machine.
#####

@testset "State machine initialization" begin
    # Initialize the state machine.
    HSM.transition_to_state!(thermometer_state_machine, thermometer_state_machine)

    @test HSM.active_state(thermometer_state_machine) == off_state
    @test thermometer.display == "off"
end

@testset "Off State tests" begin
    # Test ignored events.
    HSM.handle_event!(thermometer_state_machine, UnitsEvent())

    @test HSM.active_state(thermometer_state_machine) == off_state
    @test thermometer.display == "off"

    HSM.handle_event!(thermometer_state_machine, TemperatureEvent(10.0))

    @test HSM.active_state(thermometer_state_machine) == off_state
    @test thermometer.display == "off"

    # Test power event.
    HSM.handle_event!(thermometer_state_machine, PowerEvent())

    @test HSM.active_state(thermometer_state_machine) == celsius_state
    @test thermometer.display == "--"
end

@testset "On State tests" begin
    # Test units event.
    HSM.handle_event!(thermometer_state_machine, UnitsEvent())

    @test HSM.active_state(thermometer_state_machine) == farenheit_state
    @test thermometer.display == "--"

    HSM.handle_event!(thermometer_state_machine, UnitsEvent())

    @test HSM.active_state(thermometer_state_machine) == kelvin_state
    @test thermometer.display == "--"

    HSM.handle_event!(thermometer_state_machine, TemperatureEvent(0.0))

    @test thermometer.display == "273.2K"

    HSM.handle_event!(thermometer_state_machine, UnitsEvent())

    @test HSM.active_state(thermometer_state_machine) == celsius_state
    @test thermometer.display == "0.0°C"

    HSM.handle_event!(thermometer_state_machine, UnitsEvent())

    @test HSM.active_state(thermometer_state_machine) == farenheit_state
    @test thermometer.display == "32.0°F"

    HSM.handle_event!(thermometer_state_machine, PowerEvent())

    @test HSM.active_state(thermometer_state_machine) == off_state
    @test thermometer.display == "off"
end

@testset "On - Off - On retains memory" begin
    HSM.handle_event!(thermometer_state_machine, PowerEvent())

    @test HSM.active_state(thermometer_state_machine) == farenheit_state
    @test thermometer.display == "32.0°F"
end
