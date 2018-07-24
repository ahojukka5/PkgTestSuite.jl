# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/PkgTestSuite.jl/blob/master/LICENSE

using PkgTestSuite
using Base.Test

@testset "test checkheader" begin
    include("test_checkheader.jl")
end

@testset "test checktabs" begin 
    include("test_checktabs.jl")
end

PkgTestSuite.init("PkgTestSuite")
PkgTestSuite.test("PkgTestSuite"; run_tests=false)
PkgTestSuite.deploy("PkgTestSuite")
