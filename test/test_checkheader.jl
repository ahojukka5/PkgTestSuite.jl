# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/PkgTestSuite.jl/blob/master/LICENSE

using PkgTestSuite: checkheader
using Base.Test

new_file_path = Pkg.dir("PkgTestSuite", "src", "new_file_with_wrong_license_header.jl")
if isfile(new_file_path)
    rm(new_file_path)
end

@test checkheader("PkgTestSuite")

fid = open(new_file_path, "w")
write(fid, """
# This file is not a part of JuliaFEM.
# License is not MIT: don't see https://github.com/JuliaFEM/PkgTestSuite.jl/blob/master/LICENSE

function foo()
    return 1
end
""")
close(fid)
@test_throws Exception checkheader("PkgTestSuite")
