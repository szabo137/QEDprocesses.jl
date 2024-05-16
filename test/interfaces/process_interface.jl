using Random
using Suppressor
using QEDbase
using QEDprocesses

RNG = MersenneTwister(137137)
ATOL = 0.0
RTOL = sqrt(eps())

include("../test_implementation/TestImplementation.jl")

@testset "($N_INCOMING,$N_OUTGOING)" for (N_INCOMING, N_OUTGOING) in Iterators.product(
    (1, rand(RNG, 2:8)), (1, rand(RNG, 2:8))
)
    INCOMING_PARTICLES = rand(RNG, TestImplementation.PARTICLE_SET, N_INCOMING)
    OUTGOING_PARTICLES = rand(RNG, TestImplementation.PARTICLE_SET, N_OUTGOING)

    TESTPROC = TestImplementation.TestProcess(INCOMING_PARTICLES, OUTGOING_PARTICLES)
    TESTMODEL = TestImplementation.TestModel()
    TESTPSDEF = TestImplementation.TestPhasespaceDef()
    IN_PS = TestImplementation._rand_momenta(RNG, N_INCOMING)
    OUT_PS = TestImplementation._rand_momenta(RNG, N_OUTGOING)
    PSP = generate_phase_space(TESTPROC, TESTMODEL, TESTPSDEF, IN_PS, OUT_PS)

    @testset "failed interface" begin
        TESTPROC_FAIL_ALL = TestImplementation.TestProcess_FAIL_ALL(
            INCOMING_PARTICLES, OUTGOING_PARTICLES
        )
        TESTPROC_FAIL_DIFFCS = TestImplementation.TestProcess_FAIL_DIFFCS(
            INCOMING_PARTICLES, OUTGOING_PARTICLES
        )
        TESTMODEL_FAIL = TestImplementation.TestModel_FAIL()
        TESTPSDEF_FAIL = TestImplementation.TestPhasespaceDef_FAIL()

        @testset "failed process interface" begin
            @test_throws MethodError incoming_particles(TESTPROC_FAIL_ALL)
            @test_throws MethodError outgoing_particles(TESTPROC_FAIL_ALL)
        end

        @testset "$PROC $MODEL" for (PROC, MODEL) in Iterators.product(
            (TESTPROC, TESTPROC_FAIL_DIFFCS), (TESTMODEL, TESTMODEL_FAIL)
        )
            if TestImplementation._any_fail(PROC, MODEL)
                psp = generate_phase_space(PROC, MODEL, TESTPSDEF, IN_PS, OUT_PS)
                @test_throws MethodError QEDprocesses._incident_flux(psp)
                @test_throws MethodError QEDprocesses._averaging_norm(psp)
                @test_throws MethodError QEDprocesses._matrix_element(psp)
            end

            for PS_DEF in (TESTPSDEF, TESTPSDEF_FAIL)
                if TestImplementation._any_fail(PROC, MODEL, PS_DEF)
                    psp = generate_phase_space(PROC, MODEL, PS_DEF, IN_PS, OUT_PS)
                    @test_throws MethodError QEDprocesses._phase_space_factor(psp)
                end
            end
        end
    end

    @testset "broadcast" begin
        test_func(proc::AbstractProcessDefinition) = proc
        @test test_func.(TESTPROC) == TESTPROC

        test_func(model::AbstractModelDefinition) = model
        @test test_func.(TESTMODEL) == TESTMODEL
    end

    @testset "incoming/outgoing particles" begin
        @test incoming_particles(TESTPROC) == INCOMING_PARTICLES
        @test outgoing_particles(TESTPROC) == OUTGOING_PARTICLES
        @test number_incoming_particles(TESTPROC) == N_INCOMING
        @test number_outgoing_particles(TESTPROC) == N_OUTGOING
    end

    @testset "incident flux" begin
        test_incident_flux = QEDprocesses._incident_flux(TESTPROC, TESTMODEL, IN_PS)
        groundtruth = TestImplementation._groundtruth_incident_flux(IN_PS)
        @test isapprox(test_incident_flux, groundtruth, atol=ATOL, rtol=RTOL)
    end

    @testset "averaging norm" begin
        test_avg_norm = QEDprocesses._averaging_norm(TESTPROC)
        groundtruth = TestImplementation._groundtruth_averaging_norm(TESTPROC)
        @test isapprox(test_avg_norm, groundtruth, atol=ATOL, rtol=RTOL)
    end

    @testset "matrix element" begin
        test_matrix_element = QEDprocesses._matrix_element(PSP)
        groundtruth = TestImplementation._groundtruth_matrix_element(IN_PS, OUT_PS)
        @test length(test_matrix_element) == length(groundtruth)
        for i in eachindex(test_matrix_element)
            @test isapprox(test_matrix_element[i], groundtruth[i], atol=ATOL, rtol=RTOL)
        end
    end

    @testset "is in phasespace" begin
        @test QEDprocesses._is_in_phasespace(PSP)

        IN_PS_unphysical = deepcopy(IN_PS)
        IN_PS_unphysical[1] = SFourMomentum(zeros(4))
        OUT_PS_unphysical = deepcopy(OUT_PS)
        OUT_PS_unphysical[end] = ones(SFourMomentum)
        PSP_unphysical_in_ps = generate_phase_space(
            TESTPROC, TESTMODEL, TESTPSDEF, IN_PS_unphysical, OUT_PS
        )
        PSP_unphysical_out_ps = generate_phase_space(
            TESTPROC, TESTMODEL, TESTPSDEF, IN_PS, OUT_PS_unphysical
        )
        PSP_unphysical = generate_phase_space(
            TESTPROC, TESTMODEL, TESTPSDEF, IN_PS_unphysical, OUT_PS_unphysical
        )

        @test !QEDprocesses._is_in_phasespace(PSP_unphysical_in_ps)
        @test !QEDprocesses._is_in_phasespace(PSP_unphysical_out_ps)
        @test !QEDprocesses._is_in_phasespace(PSP_unphysical)
    end

    @testset "phase space factor" begin
        test_phase_space_factor = QEDprocesses._phase_space_factor(PSP)
        groundtruth = TestImplementation._groundtruth_phase_space_factor(IN_PS, OUT_PS)
        @test isapprox(test_phase_space_factor, groundtruth, atol=ATOL, rtol=RTOL)
    end
end
