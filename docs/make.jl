# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/PkgTestSuite.jl/blob/master/LICENSE

using Documenter
using PkgTestSuite

makedocs(modules=[PkgTestSuite],
         format = :html,
         checkdocs = :all,
         sitename = "PkgTestSuite.jl",
         pages = ["index.md"]
        )
