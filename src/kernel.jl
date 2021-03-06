module Kernel

using StaticArrays, OffsetArrays
using ..ImageFiltering: centered, KernelFactors
import ..ImageFiltering: _reshape

function product2d(kf)
    k1, k2 = kf
    k1[1].*k1[2], k2[1].*k2[2]
end

"""
`Kernel` is a module implementing filtering kernels of full
dimensionality. The following kernels are supported:

  - `sobel`
  - `prewitt`
  - `ando3`, `ando4`, and `ando5`
  - `gaussian`
  - `DoG` (Difference-of-Gaussian)
  - `LoG` (Laplacian-of-Gaussian)
  - `Laplacian`

See also: KernelFactors.
"""
Kernel

"""
    diff1, diff2 = sobel()

Return kernels for two-dimensional gradient compution using the Sobel
operator. `diff1` computes the gradient along the first (y) dimension,
and `diff2` computes the gradient along the second (x) dimension.

See also: KernelFactors.sobel, Kernel.prewitt, Kernel.ando.
"""
sobel() = product2d(KernelFactors.sobel())

sobel(extended, d) = (broadcast(*, KernelFactors.sobel(extended, d)...),)

"""
    diff1, diff2 = prewitt()

Return kernels for two-dimensional gradient compution using the
Prewitt operator.  `diff1` computes the gradient along the first (y)
dimension, and `diff2` computes the gradient along the second (x)
dimension.

See also: KernelFactors.prewitt, Kernel.sobel, Kernel.ando.
"""
prewitt() = product2d(KernelFactors.prewitt())

prewitt(extended, d) = (broadcast(*, KernelFactors.prewitt(extended, d)...),)

"""
    diff1, diff2 = ando3()

Return 3x3 kernels for two-dimensional gradient compution using the
optimal "Ando" filters.  `diff1` computes the gradient along the
y-axis (first dimension), and `diff2` computes the gradient along the
x-axis (second dimension).

# Citation
Ando Shigeru, IEEE Trans. Pat. Anal. Mach. Int., vol. 22 no 3, March
2000

See also: KernelFactors.ando3, Kernel.ando4, Kernel.ando5.
"""
ando3() = product2d(KernelFactors.ando3())

ando3(extended, d) = (broadcast(*, KernelFactors.ando3(extended, d)...),)

"""
    diff1, diff2 = ando4()

Return 4x4 kernels for two-dimensional gradient compution using the
optimal "Ando" filters.  `diff1` computes the gradient along the
y-axis (first dimension), and `diff2` computes the gradient along the
x-axis (second dimension).

# Citation
Ando Shigeru, IEEE Trans. Pat. Anal. Mach. Int., vol. 22 no 3, March
2000

See also: KernelFactors.ando4, Kernel.ando3, Kernel.ando5.
"""
function ando4()
    f = centered(@SMatrix [ -0.022116 -0.025526  0.025526  0.022116
                            -0.098381 -0.112984  0.112984  0.098381
                            -0.098381 -0.112984  0.112984  0.098381
                            -0.022116 -0.025526  0.025526  0.022116 ])
    return f', f
end

function ando4(extended::Tuple{Bool,Bool}, d)
    all(extended) || error("all dimensions must be extended")
    (ando4()[d],)
end

"""
    diff1, diff2 = ando5()

Return 5x5 kernels for two-dimensional gradient compution using the
optimal "Ando" filters.  `diff1` computes the gradient along the
y-axis (first dimension), and `diff2` computes the gradient along the
x-axis (second dimension).

# Citation
Ando Shigeru, IEEE Trans. Pat. Anal. Mach. Int., vol. 22 no 3, March
2000

See also: `KernelFactors.ando5`, `Kernel.ando3`, `Kernel.ando4`.
"""
function ando5()
    f = centered(@SMatrix [ -0.003776 -0.010199  0.0  0.010199  0.003776
                            -0.026786 -0.070844  0.0  0.070844  0.026786
                            -0.046548 -0.122572  0.0  0.122572  0.046548
                            -0.026786 -0.070844  0.0  0.070844  0.026786
                            -0.003776 -0.010199  0.0  0.010199  0.003776 ])
    return f', f
end

function ando5(extended::Tuple{Bool,Bool}, d)
    all(extended) || error("all dimensions must be extended")
    (ando5()[d],)
end

"""
    gaussian((σ1, σ2, ...), [(l1, l2, ...]) -> g
    gaussian(σ)                  -> g

Construct a multidimensional gaussian filter, with standard deviation
`σd` along dimension `d`. Optionally provide the kernel length `l`,
which must be a tuple of the same length.

If `σ` is supplied as a single number, a symmetric 2d kernel is
constructed.

See also: KernelFactors.gaussian.
"""
@inline gaussian{N}(σs::NTuple{N,Real}, ls::NTuple{N,Integer}) =
    broadcast(*, KernelFactors.gaussian(σs, ls)...)
gaussian(σ::Tuple{Real}, l::Tuple{Integer}) = KernelFactors.gaussian(σ[1], l[1])
gaussian(σ::Tuple{}, l::Tuple{}) = reshape([1])  # 0d
gaussian{T<:Real,I<:Integer}(σs::AbstractVector{T}, ls::AbstractVector{I}) =
    gaussian((σs...,), (ls...,))

@inline gaussian{N}(σs::NTuple{N,Real}) = broadcast(*, KernelFactors.gaussian(σs)...)
gaussian{T<:Real}(σs::AbstractVector{T}) = gaussian((σs...,))
gaussian(σ::Tuple{Real}) = KernelFactors.gaussian(σ[1])
gaussian(σ::Tuple{}) = reshape([1])

gaussian(σ::Real) = gaussian((σ, σ))

"""
    DoG((σp1, σp2, ...), (σm1, σm2, ...), [l1, l2, ...]) -> k
    DoG((σ1, σ2, ...))                                   -> k
    DoG(σ::Real)                                         -> k

Construct a multidimensional difference-of-gaussian kernel `k`, equal
to `gaussian(σp, l)-gaussian(σm, l)`.  When only a single `σ` is
supplied, the default is to choose `σp = σ, σm = √2 σ`. Optionally
provide the kernel length `l`; the default is to extend by two
`max(σp,σm)` in each direction from the center. `l` must be odd.

If `σ` is provided as a single number, a symmetric 2d DoG kernel is
returned.

See also: KernelFactors.IIRGaussian.
"""
DoG{N}(σps::NTuple{N,Real}, σms::NTuple{N,Real}, ls::NTuple{N,Integer}) =
    gaussian(σps, ls) - gaussian(σms, ls)
function DoG{N}(σps::NTuple{N,Real})
    σms = map(s->s*√2, σps)
    neg = gaussian(σms)
    l = map(length, indices(neg))
    gaussian(σps, l) - neg
end
DoG(σ::Real) = DoG((σ,σ))

"""
    LoG((σ1, σ2, ...)) -> k
    LoG(σ)             -> k

Construct a Laplacian-of-Gaussian kernel `k`. `σd` is the gaussian width
along dimension `d`.  If `σ` is supplied as a single number, a
symmetric 2d kernel is returned.

See also: KernelFactors.IIRGaussian and Kernel.Laplacian.
"""
function LoG{N}(σs::NTuple{N})
    w = CartesianIndex(map(n->(ceil(Int,8.5*n)>>1), σs))
    R = CartesianRange(-w, w)
    σ = SVector(σs)
    C = 1/(prod(σ)*(2π)^(N/2))
    σ2 = σ.^2
    σ2i = sum(1./σ2)
    function df(I::CartesianIndex, σ2, σ2i)
        x = SVector(I.I)
        xσ = x.^2./σ2
        (sum(xσ./σ2) - σ2i) * exp(-sum(xσ)/2)
    end
    centered([C*df(I, σ2, σ2i) for I in R])
end
LoG(σ::Real) = LoG((σ,σ))

immutable Laplacian{N}
    flags::NTuple{N,Bool}
    offsets::Vector{CartesianIndex{N}}

    function Laplacian(flags::NTuple{N,Bool})
        offsets = Array{CartesianIndex{N}}(0)
        for i = 1:N
            if flags[i]
                push!(offsets,
                      CartesianIndex{N}((ntuple(d->0, i-1)..., 1, ntuple(d->0, N-i)...)))
            end
        end
        new(flags, offsets)
    end
end

"""
    Laplacian((true,true,false,...))
    Laplacian(dims, N)
    Lacplacian()

Laplacian kernel in `N` dimensions, taking derivatives along the
directions marked as `true` in the supplied tuple. Alternatively, one
can pass `dims`, a listing of the dimensions for
differentiation. (However, this variant is not inferrable.)

`Laplacian()` is the 2d laplacian, equivalent to `Laplacian((true,true))`.

The kernel is represented as an opaque type, but you can use
`convert(AbstractArray, L)` to convert it into array format.
"""
Laplacian{N}(flags::NTuple{N,Bool}) = Laplacian{N}(flags)
Laplacian() = Laplacian((true,true))

function Laplacian(dims, N::Int)
    flags = falses(N)
    flags[[dims...]] = true
    Laplacian((flags...,))
end

Base.indices(L::Laplacian) = map(f->f ? (-1:1) : (0:0), L.flags)
Base.isempty(L::Laplacian) = false
function Base.convert{N}(::Type{AbstractArray}, L::Laplacian{N})
    A = fill!(OffsetArray{Int}(indices(L)), 0)
    for I in L.offsets
        A[I] = A[-I] = 1
    end
    A[ntuple(d->0, Val{N})...] = -2*length(L.offsets)
    A
end
_reshape{N}(L::Laplacian{N}, ::Type{Val{N}}) = L

"""
    reflect(kernel) --> reflectedkernel

Compute the pointwise reflection around 0, 0, ... of the kernel
`kernel`.  Using `imfilter` with a `reflectedkernel` performs convolution,
rather than correlation, with respect to the original `kernel`.
"""
function reflect(kernel::AbstractArray)
    inds = map(-, indices(kernel))
    out = similar(kernel, inds)
    for I in CartesianRange(indices(kernel))
        out[-I] = kernel[I]
    end
    out
end

end
