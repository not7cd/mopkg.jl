abstract type SVOptMethod end

struct SVHillClimb <: SVOptMethod end

"Finite central difference"
fdc(f, x; h=1e-5) = (f(x+h/2) - f(x-h/2))/h

"Second order central finite difference"
sfdc(f, x; h=1e-5) = (f(x+h) - 2f(x) + f(x-h))/h^2

"Find bracket with minimum"
function find_min_interval(f, x0; step=0.1, expandfactor=2.0)
    a, b = x0, x0 + step
    fa, fb = f(a), f(b)
    if fb > fa
        a, b = b, a
        fa, fb = fb, fa
        step = -step
    end
    while true
        c, fc = b + step, f(b + step)
        if fc > fb
            return a < c ? (a, c) : (c, a)
        end
        a, b = b, c
        fa, fb = fb, fc
        step = step*expandfactor
    end
end

function (svhc::SVHillClimb)(f, x0; ϵ, maxiter, dampingfactor=0.5, step=1.0)
    x, fp = x0, f(x0)
    s, fs = x0 + step, f(x0 + step)
    if fs > fp
        x, s = s, x
        fp, fs = fs, fp
        step = -step
    end
    i, fn = 0, Inf
    while abs(fn-fs) ≥ ϵ && i ≤ maxiter
        i += 1
        s += step
        fs = fn
        fn = f(s)
        if fn > fs
            step = -step*dampingfactor
        end
    end
    return fn, s
end

struct SVGoldenRatio <: SVOptMethod end

ρ = (sqrt(5) - 1)/2

fw1(a, b) = a + (1 - ρ)*(b - a)
fw2(a, b) = b - (1 - ρ)*(b - a)

function (svhc::SVGoldenRatio)(f, x0; ϵ, maxiter)
    a, b = find_min_interval(f, x0)
    @assert b > a
    k = 1  # iterations
    w1 = fw1(a, b)
    w2 = fw2(a, b)

    while abs(b - a) ≥ ϵ && k ≤ maxiter
        k += 1
        if f(w1) < f(w2)
            b = w2
            w2 = w1
            w1 = fw1(a, b)
        else
            a = w1
            w1 = w2
            w2 = fw2(a, b)
        end
    end
    return f(a), a
end
