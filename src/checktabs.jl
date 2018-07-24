# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/PkgTestSuite.jl/blob/master/LICENSE

"""
    checktabs(pkg_name)

Read all julia source files of package and check that no tabulators are found
from files.
"""
function checktabs(package::String)
    pkg_dir = Pkg.dir(package)
    dirs = ["src", "test"]
    hastabs = false
    nfiles = 0
    for dir in dirs
        isdir(joinpath(pkg_dir, dir)) || continue
        all_files = readdir(joinpath(pkg_dir, dir))
        for file_name in all_files
            endswith(file_name, ".jl") || continue
            nfiles += 1
            src_file = joinpath(pkg_dir, dir, file_name)
            src_lines = readlines(open(src_file))
            for (i, line) in enumerate(src_lines)
                if '\t' in line
                    warn("use of tabulator found at file $file_name, at line $i:")
                    println(line)
                    hastabs = true
                end
            end
        end
    end
    if hastabs
        error("Source files has tabs. Please fix files.")
    end
    info("No use of tabulator found from $nfiles source files.")
    return true
end
