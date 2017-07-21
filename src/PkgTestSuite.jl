# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/PkgTestSuite.jl/blob/master/LICENSE

module PkgTestSuite

installed_packages = Pkg.installed()

if !haskey(installed_packages, "CheckHeader")
    Pkg.clone("https://github.com/ahojukka5/CheckHeader.jl.git")
end
if !haskey(installed_packages, "CheckTabs")
    Pkg.clone("https://github.com/ahojukka5/CheckTabs.jl.git")
end
if !haskey(installed_packages, "Coverage")
    Pkg.add("Coverage")
end
if !haskey(installed_packages, "Documenter")
    Pkg.add("Documenter")
end
if !haskey(installed_packages, "Lint")
    Pkg.add("Lint")
end

using CheckHeader
using CheckTabs
using Coverage
using Documenter
using Lint

using Base.Test

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
    results = lintpkg(pkg)
    if !isempty(results)
        info("Lint.jl is a tool that uses static analysis to assist in the development process by detecting common bugs and potential issues.")
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

    # generate documentation and run doctests
    cd(Pkg.dir(pkg, "docs"))
    makedocs(
        modules = [getfield(Main, Symbol(pkg))],
        checkdocs = :all,
        strict = strict_docs)

    # run pkg tests
    Pkg.test(pkg, coverage=true)
end

"""
    deploy(pkg::String)

Deploy package.
"""
function deploy(pkg::String="")

    pkg = determine_pkg_name(pkg)
    cd(Pkg.dir(pkg))

    # upload results to coveralls.io
    result = Coveralls.process_folder()
    Coveralls.submit(result)
    cd(Pkg.dir(pkg, "docs"))

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
    println("writing the following mkdocs.yml file content:")
    println(mkdocs_template)

    # deploy documentation to juliafem.github.io
    fid = open("mkdocs.yml", "w")
    write(fid, mkdocs_template)
    close(fid)
    deploydocs(
        deps = Deps.pip("mkdocs", "python-markdown-math"),
        repo = "github.com/JuliaFEM/$pkg.jl.git",
        julia = "0.6")
end

export init, test, deploy

end