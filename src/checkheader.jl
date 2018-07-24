# This file is a part of JuliaFEM. 
# License is MIT: see https://github.com/JuliaFEM/PkgTestSuite.jl/blob/master/LICENSE

"""
    read_header(fid)

Read header from file content.

Searches "part of" and "license" lines using regular expression
from file header.
"""
function read_header(fd)
    lines = readlines(fd)
    header_comment = true
    header_lines = []
    regex_strings = [r"(This file is a part of \w+)",
                     r"(License is [\s\w.]+: [\w\W\s]+)"]
    no_empty_lines = filter(x->x != "", lines)
    for line in no_empty_lines
        !startswith(line, "#") && break
        for each in regex_strings
            found = match(each, line)
            found != nothing && push!(header_lines, found[1])
        end
    end
    return header_lines
end

"""
    checkheader(pkg_name; source_dirs=["src", "test"])

Check headers of files.

Reads all julia source files from source_dirs and compares
that file license header matches the one found from packages
main file license header.
"""
function checkheader(package::String; source_dirs=["src", "test"])
    pkg_dir = Pkg.dir(package)
    main_file = joinpath(pkg_dir, "src", package * ".jl")
    main_header = open(read_header, main_file)
    nlines = length(main_header)
    info("Found header from $package.jl:")
    info("------------------------------")
    for j=1:nlines
        info(main_header[j])
    end
    info("------------------------------")
    hasdiff = false
    nfiles = 0
    for dir in source_dirs
        isdir(joinpath(pkg_dir, dir)) || continue
        all_files = readdir(joinpath(pkg_dir, dir))
        only_julia_files = filter(x->endswith(x, ".jl"), all_files)
        for file_name in only_julia_files
            nfiles += 1
            src_file = joinpath(pkg_dir, dir, file_name)
            header_compare = open(read_header, src_file)
            lines_in_compare = length(header_compare)
            if lines_in_compare != nlines
                info(header_compare, " ", file_name)
                warn("The number of header lines differs in file $dir/$file_name:")
                hasdiff = true
                continue
            end
            for j=1:nlines
                if main_header[j] != header_compare[j]
                    warn("Header content difference in file $dir/$file_name:")
                    hasdiff = true
                    break
                end
            end
        end
    end
    if hasdiff
        error("Found header differences between source files!")
    end
    info("Header is same in all $nfiles files.")
    return true
end

export checkheader
