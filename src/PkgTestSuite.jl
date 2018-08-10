# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/PkgTestSuite.jl/blob/master/LICENSE

module PkgTestSuite

using Coverage
using Documenter
using TimerOutputs
if VERSION < v"1.0.0"
    using Base.Test
else
    using Test
end

USING_LINT = true
try
    using Lint
catch
    info("Cannot use Lint.jl with Julia version $VERSION")
    USING_LINT = false
end

include("checkheader.jl")
include("checktabs.jl")

"""
    determine_pkg_name(pkg::String="")

A helper function to determine package name.
"""
function determine_pkg_name(pkg::String="")
    if pkg == ""
        if !haskey(ENV, "TRAVIS_REPO_SLUG")
            error("package name not given and not in Travis-CI environmnt")
        end
        s = ENV["TRAVIS_REPO_SLUG"]
        info("TRAVIS_REPO_SLUG = $s")
        pkg = replace(split(s,'/')[end], ".jl", "")
    end
    return pkg
end

"""
    init()

Clone and build package subject to testing.
"""
function init(pkg_name::String="")
    pkg_name = determine_pkg_name(pkg_name)
    info("PkgTestSuite.init(): determined package name to be $pkg_name")
    inside_travis = haskey(ENV, "TRAVIS")
    if inside_travis
        pkg_path = ENV["TRAVIS_BUILD_DIR"]
    else
        pkg_path = Pkg.dir(pkg_name)
    end
    info("PkgTestSuite.init(): detemined location of package to be $pkg_path")
    if pkg_name == "PkgTestSuite"
        # self-checking PkgTestSuite, not build another time even inside Travis-CI
        return nothing
    end
    repo = LibGit2.GitRepo(Pkg.dir("PkgTestSuite"))
    hash_long = string(LibGit2.revparseid(repo, "master"))
    hash_short = hash_long[1:7]
    info("PkgTestSuite.init(): Determined PkgTestSuite commit hash to be $hash_short")
    if inside_travis
        info("Inside Travis-CI, cloning and building package")
        Pkg.clone(pkg_path)
        Pkg.build(pkg_name)
    end
    return nothing
end

"""
    test(pkg_name)

Run tests for package.
"""
function test(pkg_name=""; run_tests=true)

    pkg_name = determine_pkg_name(pkg_name)
    pkg_dir = Pkg.dir(pkg_name)
    cd(pkg_dir)
    if VERSION < v"0.7.0-beta2.0"
        Base.require(Symbol(pkg_name))
        pkg = getfield(Main, Symbol(pkg_name))
    else
        pkg = Base.require(Module(Symbol(pkg_name)), Symbol(pkg_name))
    end

    # check for headers and tabulators
    checkheader(pkg_name)
    checktabs(pkg_name)

    # make it possible to allow lint check or doctest fail
    # without failing whole build
    strict_lint = (get(ENV, "LINT_STRICT", "true") == "true")
    strict_docs = (get(ENV, "DOCUMENTER_STRICT", "true") == "true")

    # run lint
    if USING_LINT
        results = lintpkg(pkg_name)
        if !isempty(results)
            info("Lint.jl is a tool that uses static analysis to assist ",
                 "in the development process by detecting common bugs and ",
                 "potential issues.")
            info("For this package, Lint.jl report is following:")
            display(results)
            info("For more information, see https://lintjl.readthedocs.io/en/stable/")
            warn("Package syntax test has failed.")
            if strict_lint
                errors_and_warnings = filter(i -> !isinfo(i), results)
                @test isempty(errors_and_warnings)
            end
        else
            info("Lint.jl: syntax check pass.")
        end
    else
        info("Lint.jl is not $VERSION compatible yet.")
    end

    # generate documentation and run doctests
    docs_dir = Pkg.dir(pkg_name, "docs")    
    docs_src_dir = Pkg.dir(pkg_name, "docs", "src")
    readme_file = Pkg.dir(pkg_name, "README.md")
    index_file = Pkg.dir(pkg_name, "docs", "src", "index.md")
    if !isdir(docs_dir)
        info("Creating new directory $docs_dir")
        mkdir(docs_dir)
    end
    if !isdir(docs_src_dir)
        info("Creating new directory $docs_src_dir")
        mkdir(docs_src_dir)
    end
    if !isfile(index_file)
        warn("$index_file not found.")
        if isfile(readme_file)
            info("Copying $readme_file to $index_file")
            cp(readme_file, index_file)
        else
            index_file_default_contents = """# $pkg_name.jl

Package documentation missing. Start writing documentation to package by
creating docs/src/index.md where it is described what this package does.

Also, create README.md"""
            open(index_file, "w") do fid
                write(fid, index_file_default_contents)
            end
        end
    end
    cd(docs_dir)
    makefile = joinpath(docs_dir, "make.jl")
    if isfile(makefile)
        include(makefile)
    else
        warn("$makefile not found, using defaults to generate documentation.")
        makedocs(
            modules = [pkg],
            format = :html,
            checkdocs = :all,
            sitename = "$pkg_name.jl",
            pages = ["index.md"],
            strict = strict_docs)
    end

    # run pkg tests
    runtests_file = Pkg.dir(pkg_name, "test", "runtests.jl")
    if isfile(runtests_file) && run_tests
        Pkg.test(pkg_name, coverage=true)
    else
        warn("Not running tests for $pkg_name.")
    end
    return nothing
end

"""
    deploy(pkg::String)

Deploy package.
"""
function deploy(pkg::String="")

    pkg = determine_pkg_name(pkg)

    if !haskey(ENV, "TRAVIS")
        info("Looks that you are not running deploy on CI platform.")
        info("Documentation generated to ", Pkg.dir(pkg, "docs", "site"))
        return nothing
    end

    # upload results to coveralls.io
    cd(Pkg.dir(pkg))
    result = Coveralls.process_folder()
    Coveralls.submit(result)

    # deploy documentation to juliafem.github.io
    cd(Pkg.dir(pkg, "docs"))
    deploy_file = Pkg.dir(pkg, "docs", "deploy.jl")
    if isfile(deploy_file)
        include(deploy_file)
    else
        warn("deploy.jl not found, deploying using default settings")
        deploydocs(
            repo = "github.com/JuliaFEM/$pkg.jl.git",
            julia = "0.6",
            deps = nothing,
            make = nothing)
    end

    return nothing
end

export init, test, deploy

end
