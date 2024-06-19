using QEDprocesses
using Random
using QEDbase: QEDbase
using QEDcore

POLS = [QEDbase.PolX(), QEDbase.PolY(), QEDbase.AllPol()]
SPINS = [QEDbase.SpinUp(), QEDbase.SpinDown(), QEDbase.AllSpin()]
POL_AND_SPIN_COMBINATIONS = Iterators.product(SPINS, POLS, SPINS, POLS)
POL_COMBINATIONS = Iterators.product(POLS, POLS)
BUF = IOBuffer()

@testset "constructor" begin
    @testset "default" begin
        proc = Compton()
        @test QEDprocesses._spin_or_pol(proc, QEDbase.Photon(), QEDbase.Incoming()) ==
            QEDbase.AllPol()
        @test QEDprocesses._spin_or_pol(proc, QEDbase.Electron(), QEDbase.Incoming()) ==
            QEDbase.AllSpin()
        @test QEDprocesses._spin_or_pol(proc, QEDbase.Photon(), QEDbase.Outgoing()) ==
            QEDbase.AllPol()
        @test QEDprocesses._spin_or_pol(proc, QEDbase.Electron(), QEDbase.Outgoing()) ==
            QEDbase.AllSpin()

        print(BUF, proc)
        @test String(take!(BUF)) == "one-photon Compton scattering"

        show(BUF, MIME"text/plain"(), proc)
        @test String(take!(BUF)) ==
            "one-photon Compton scattering\n    incoming: electron ($(QEDbase.AllSpin())), photon ($(QEDbase.AllPol()))\n    outgoing: electron ($(QEDbase.AllSpin())), photon ($(QEDbase.AllPol()))\n"
    end

    @testset "in_pol" begin
        @testset "$pol" for pol in POLS
            proc = Compton(pol)
            @test QEDprocesses._spin_or_pol(proc, QEDbase.Electron(), QEDbase.Incoming()) ==
                QEDbase.AllSpin()
            @test QEDprocesses._spin_or_pol(proc, QEDbase.Photon(), QEDbase.Incoming()) ==
                pol
            @test QEDprocesses._spin_or_pol(proc, QEDbase.Electron(), QEDbase.Outgoing()) ==
                QEDbase.AllSpin()
            @test QEDprocesses._spin_or_pol(proc, QEDbase.Photon(), QEDbase.Outgoing()) ==
                QEDbase.AllPol()

            print(BUF, proc)
            @test String(take!(BUF)) == "one-photon Compton scattering"

            show(BUF, MIME"text/plain"(), proc)
            @test String(take!(BUF)) ==
                "one-photon Compton scattering\n    incoming: electron ($(QEDbase.AllSpin())), photon ($(pol))\n    outgoing: electron ($(QEDbase.AllSpin())), photon ($(QEDbase.AllPol()))\n"
        end
    end

    @testset "in_pol+out_pol" begin
        @testset "$in_pol, $out_pol" for (in_pol, out_pol) in POL_COMBINATIONS
            proc = Compton(in_pol, out_pol)
            @test QEDprocesses._spin_or_pol(proc, QEDbase.Electron(), QEDbase.Incoming()) ==
                QEDbase.AllSpin()
            @test QEDprocesses._spin_or_pol(proc, QEDbase.Photon(), QEDbase.Incoming()) ==
                in_pol
            @test QEDprocesses._spin_or_pol(proc, QEDbase.Electron(), QEDbase.Outgoing()) ==
                QEDbase.AllSpin()
            @test QEDprocesses._spin_or_pol(proc, QEDbase.Photon(), QEDbase.Outgoing()) ==
                out_pol

            print(BUF, proc)
            @test String(take!(BUF)) == "one-photon Compton scattering"

            show(BUF, MIME"text/plain"(), proc)
            @test String(take!(BUF)) ==
                "one-photon Compton scattering\n    incoming: electron ($(QEDbase.AllSpin())), photon ($(in_pol))\n    outgoing: electron ($(QEDbase.AllSpin())), photon ($(out_pol))\n"
        end
    end
    @testset "all spins+pols" begin
        @testset "$in_spin, $in_pol, $out_spin, $out_pol" for (
            in_spin, in_pol, out_spin, out_pol
        ) in POL_AND_SPIN_COMBINATIONS
            proc = Compton(in_spin, in_pol, out_spin, out_pol)
            @test QEDprocesses._spin_or_pol(proc, QEDbase.Electron(), QEDbase.Incoming()) ==
                in_spin
            @test QEDprocesses._spin_or_pol(proc, QEDbase.Photon(), QEDbase.Incoming()) ==
                in_pol
            @test QEDprocesses._spin_or_pol(proc, QEDbase.Electron(), QEDbase.Outgoing()) ==
                out_spin
            @test QEDprocesses._spin_or_pol(proc, QEDbase.Photon(), QEDbase.Outgoing()) ==
                out_pol

            print(BUF, proc)
            @test String(take!(BUF)) == "one-photon Compton scattering"

            show(BUF, MIME"text/plain"(), proc)
            @test String(take!(BUF)) ==
                "one-photon Compton scattering\n    incoming: electron ($(in_spin)), photon ($(in_pol))\n    outgoing: electron ($(out_spin)), photon ($(out_pol))\n"
        end
    end
end
@testset "particle content" begin
    proc = Compton()
    @test incoming_particles(proc) == (QEDbase.Electron(), QEDbase.Photon())
    @test outgoing_particles(proc) == (QEDbase.Electron(), QEDbase.Photon())
    @test number_incoming_particles(proc) == 2
    @test number_outgoing_particles(proc) == 2
end
