# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/PkgTestSuite.jl/blob/master/LICENSE

using PkgTestSuite: checktabs
using Base.Test

new_file_path = Pkg.dir("PkgTestSuite", "src", "new_file_with_tabs.jl")
if isfile(new_file_path)
    rm(new_file_path)
end

@test checktabs("PkgTestSuite")

fid = open(new_file_path, "w")
write(fid, """
# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/PkgTestSuite.jl/blob/master/LICENSE

function foo()
\treturn 1
end
""")
close(fid)
@test_throws Exception checktabs("PkgTestSuite")
