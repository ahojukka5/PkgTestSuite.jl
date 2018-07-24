# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/PkgTestSuite.jl/blob/master/LICENSE

module PkgTestSuite

using Coverage
using Documenter
using TimerOutputs
using Base.Test

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
function init(pkg::String="")
    pkg = determine_pkg_name(pkg)
    where = get(ENV, "TRAVIS_BUILD_DIR", pwd())
    repo = LibGit2.GitRepo(Pkg.dir("PkgTestSuite"))
    hash = string(LibGit2.revparseid(repo, "master"))
    hash_short = hash[1:7]
    info("init(): PkgTestSuite commit hash   $hash_short")
    info("init(): location of package        $where")
    info("init(): determined package to be   $pkg")
    Pkg.clone(where)
    Pkg.build(pkg)
end

"""
    test(pkg::String)

Run tests for pkg.
"""
function test(pkg::String="")

    pkg = determine_pkg_name(pkg)
    cd(Pkg.dir(pkg))
    Base.require(Symbol(pkg))

    # check for headers and tabulators
    checkheader(pkg)
    checktabs(pkg)

    # make it possible to allo lint check or doctest fail
    # without failing whole build
    strict_lint = (get(ENV, "LINT_STRICT", "true") == "true")
    strict_docs = (get(ENV, "DOCUMENTER_STRICT", "true") == "true")

    # run lint
    if USING_LINT
        results = lintpkg(pkg)
        if !isempty(results)
            info("Lint.jl is a tool that uses static analysis to assist ",
                 "in the development process by detecting common bugs and ",
                 "potential issues.")
            info("For this package, Lint.jl report is following:")
            display(results)
            info("For more information, see https://lintjl.readthedocs.io/en/stable/")
            warn("Package syntax test has failed.")
            if strict_lint
                @test isempty(results)
            end
        else
            info("Lint.jl: syntax check pass.")
        end
    else
        info("Lint.jl is not 0.7 compatible yet.")
    end

    # generate documentation and run doctests
    cd(Pkg.dir(pkg, "docs"))
    if isfile("make.jl")
        include("make.jl")
    else
        makedocs(
            modules = [getfield(Main, Symbol(pkg))],
            checkdocs = :all,
            strict = strict_docs)
    end

    # run pkg tests
    cd(Pkg.dir(pkg, "test"))
    if !isfile("runtests.jl")
        info("runtests.jl not found, creating default.")
        runtests_code = """
# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/$pkg.jl/blob/master/LICENSE

using Base.Test
using TimerOutputs

pkg_dir = Pkg.dir("$pkg")
maybe_test_files = readdir(joinpath(pkg_dir, "test"))
is_test_file(fn) = startswith(fn, "test_") & endswith(fn, ".jl")
test_files = filter(is_test_file, maybe_test_files)
info("\$(length(test_files)) test files found.")

const to = TimerOutput()
@testset "$pkg.jl" begin
    for fn in test_files
        info("----- Running tests from file \$fn -----")
        t0 = time()
        timeit(to, fn) do
            include(fn)
        end
        dt = round(time() - t0, 2)
        info("----- Testing file \$fn completed in \$dt seconds -----")
    end
end
println()
println("Test statistics:")
println(to)
"""
        println("writing the following runtests.jl file content:")
        println(runtests_code)
        fid = open("runtests.jl", "w")
        write(fid, runtests_code)
        close(fid)
    end
    Pkg.test(pkg, coverage=true)
end

"""
    deploy(pkg::String)

Deploy package.
"""
function deploy(pkg::String="")

    pkg = determine_pkg_name(pkg)

    mkdocs_template = """
site_name: $pkg.jl
repo_url: https://github.com/JuliaFEM/$pkg.jl
site_description: site_description
site_author: site_author

theme: readthedocs

extra_css:
    - assets/Documenter.css

extra_javascript:
    - https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML
    - assets/mathjaxhelper.js

markdown_extensions:
    - extra
    - tables
    - fenced_code
    - footnotes
    - mdx_math:
        enable_dollar_delimiter: True

docs_dir: 'build'

pages:
    - Home: index.md
"""
    cd(Pkg.dir(pkg, "docs"))
    if !isfile("mkdocs.yml")
        println("writing the following mkdocs.yml file content:")
        println(mkdocs_template)
        fid = open("mkdocs.yml", "w")
        write(fid, mkdocs_template)
        close(fid)
    end

    if !haskey(ENV, "TRAVIS")
        println("Looks that you are not running deploy on CI platform")
        println("Generating documentation using `mkdocs build`")
        run(`mkdocs build`)
        println("Documentation generated to ", Pkg.dir(pkg, "docs", "site"))
        return
    end

    # upload results to coveralls.io
    cd(Pkg.dir(pkg))
    result = Coveralls.process_folder()
    Coveralls.submit(result)

    # deploy documentation to juliafem.github.io
    cd(Pkg.dir(pkg, "docs"))
    if isfile("deploy.jl")
        include("deploy.jl")
    else
        deploydocs(
            deps = Deps.pip("mkdocs", "python-markdown-math"),
            repo = "github.com/JuliaFEM/$pkg.jl.git",
            julia = "0.6")
    end
end

export init, test, deploy

end
