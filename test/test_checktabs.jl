# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/PkgTestSuite.jl/blob/master/LICENSE

using PkgTestSuite: checktabs
using Base.Test

new_file_path = Pkg.dir("PkgTestSuite", "src", "new_file_with_tabs.jl")
isfile(new_file_path) && rm(new_file_path)

@test checktabs("PkgTestSuite")

test_file_contents = """
# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/PkgTestSuite.jl/blob/master/LICENSE

function foo()
\treturn 1
end
"""
open(new_file_path, "w") do fid
    write(fid, test_file_contents)
end
@test_throws Exception checktabs("PkgTestSuite")
isfile(new_file_path) && rm(new_file_path)
