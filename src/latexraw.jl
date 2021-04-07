@doc doc"""
    latexraw(arg)

Generate LaTeX equations from `arg`.

Parses expressions, ParameterizedFunctions, SymEngine.Base and arrays thereof.
Returns a string formatted for LaTeX.

# Examples

## using expressions
```jldoctest
expr = :(x/(y+x))
latexraw(expr)

# output

"\\frac{x}{y + x}"
```

```jldoctest
expr = Meta.parse("x/(y+x)")
latexraw(expr)

# output

"\\frac{x}{y + x}"
```

## using ParameterizedFunctions
```julia
using DifferentialEquations;
f = @ode_def feedback begin
         dx = y/c_1 - x
         dy = x^c_2 - y
       end c_1=>1.0 c_2=>1.0
latexraw(f)

# output

2-element Array{String,1}:
 "dx/dt = \\frac{y}{c_{1}} - x"
 "dy/dt = x^{c_{2}} - y"
```

## using SymEngine
```jldoctest
using SymEngine
@vars x y
symExpr = x + x + x*y*y
latexraw(symExpr)

# output

"2 \\cdot x + x \\cdot y^{2}"
```
"""
# latexraw(args...; kwargs...) = latexify(args...; kwargs..., env=:raw)
latexraw(args...; kwargs...) = _latexraw(args...; kwargs...)

_latexraw(ex::Expr; kwargs...) = _latextree(ex; kwargs...)
_latexraw(ex; kwargs...) = nested(ex) ? _latextree(ex; kwargs...) : throw(ArgumentError("Unsupported type $(typeof(ex)) to Latexify._latexraw")) 


function _latexraw(args...; kwargs...)
    @assert length(args) > 1 "latexify does not support objects of type $(typeof(args[1]))."
    _latexraw(args; kwargs...)
end
_latexraw(arr::Union{AbstractArray, Tuple}; kwargs...) = _latexarray(arr; kwargs...)
_latexraw(i::Nothing; kwargs...) = ""
_latexraw(i::SubString; kwargs...) = latexraw(Meta.parse(i); kwargs...)
_latexraw(i::SubString{LaTeXStrings.LaTeXString}; kwargs...) = i
_latexraw(i::Rational; kwargs...) = i.den == 1 ? latexraw(i.num; kwargs...) : latexraw(:($(i.num)/$(i.den)); kwargs...)
_latexraw(z::Complex; kwargs...) = LaTeXString("$(latexraw(z.re;kwargs...))$(z.im < 0 ? "-" : "+" )$(latexraw(abs(z.im);kwargs...))\\textit{i}")
#latexraw(i::DataFrames.DataArrays.NAtype) = "\\textrm{NA}"
_latexraw(str::LaTeXStrings.LaTeXString; kwargs...) = str

function _latexraw(i::Number; fmt=PlainNumberFormatter(), kwargs...)
    try isinf(i) && return LaTeXString("\\infty") catch; end
    fmt isa String && (fmt = PrintfNumberFormatter(fmt))
    return LaTeXString(fmt(i))
end

function _latexraw(i::Char; convert_unicode=true, kwargs...)
    LaTeXString(convert_unicode ? unicode2latex(string(i)) : string(i))
end

function _latexraw(i::Symbol; convert_unicode=true, kwargs...)
    str = string(i == :Inf ? :∞ : i)
    str = convertSubscript(str)
    convert_unicode && (str = unicode2latex(str))
    return LaTeXString(str)
end

function _latexraw(i::String; kwargs...)
    try
        ex = Meta.parse(i)
        return latexraw(ex; kwargs...)
    catch ParseError
        error("""
in Latexify.jl:
You are trying to create latex-maths from a `String` that cannot be parsed as
an expression.

`latexify` will, by default, try to parse any string inputs into expressions
and this parsing has just failed.

If you are passing strings that you want returned verbatim as part of your input,
try making them `LaTeXString`s first.

If you are trying to make a table with plain text, try passing the keyword
argument `latex=false`. You should also ensure that you have chosen an output
environment that is capable of displaying not-maths objects. Try for example
`env=:table` for a latex table or `env=:mdtable` for a markdown table.
""")
    end
end

_latexraw(i::Missing; kwargs...) = "\\textrm{NA}"
