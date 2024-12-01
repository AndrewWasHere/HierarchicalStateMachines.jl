using Logging, Test
import HierarchicalStateMachines as HSM

struct HsmStateInfoState <: HSM.AbstractHsmState
    # Actual contents are not necessary for tests, so they're left out for 
    # convenience.
end

@testset "HsmStateInfo()" begin
    # Test default constructor.
    info = HSM.HsmStateInfo(nothing)
    @test !isnothing(info)
    @test isnothing(info.parent_state)
    @test isnothing(info.active_substate)

    something = HsmStateInfoState()
    info = HSM.HsmStateInfo(something)
    @test !isnothing(info)
    @test info.parent_state == something
    @test isnothing(info.active_substate)

    # Test multiple-argument constructor does not exist.
    @test_throws MethodError HSM.HsmStateInfo(nothing, nothing)
end
