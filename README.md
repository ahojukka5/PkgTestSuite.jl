# PkgTestSuite.jl

Standard test suite for packages under JuliaFEM

Usage from command line:

```julia
julia> using PkgTestSuite
julia> test(pkg)
```

From Travis-CI:

```yaml
before_script:
    - julia --color=yes -e 'Pkg.clone("https://github.com/JuliaFEM/PkgTestSuite.jl.git")'
    - julia --color=yes -e 'using PkgTestSuite; init()'
script:
    - julia --color=yes -e 'using PkgTestSuite; test()'
after_success:
    - julia --color=yes -e 'using PkgTestSuite; deploy()'
```

Default sequence is:
1. check that all source files contain licence string using CheckHeader.jl
2. check that no tabs are used in source files using CheckTabs.jl
3. check code syntax using Lint.jl
4. check documentation using Documenter.jl
5. run all unit tests
6. deploy documentation to juliafem.github.io and coverage report to coveralls.io

By default build will fail if any item in above is failing. Something this
might be too strict requirement, especially for older packages. For that
reason is's possible to set key `LINT_STRICT` to `false` in Travis environment
variable to make deploy success even if Lint.jl is giving some warnings.
Correspondingly there is a key `DOCUMENTER_STRICT` which can be set to `false`
to skip errors in Documenter.jl caused by missing docstrings or failed doctests.
