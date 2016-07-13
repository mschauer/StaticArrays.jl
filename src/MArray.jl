type MArray{Size, T, N, L} <: StaticArray{T, N}
    data::NTuple{L,T}

    function MArray(x::NTuple{L,T})
        check_marray_parameters(Val{Size}, T, Val{N}, Val{L})
        new(x)
    end

    function MArray(x::NTuple{L})
        check_marray_parameters(Val{Size}, T, Val{N}, Val{L})
        new(convert_ntuple(T, x))
    end

    function MArray()
        check_marray_parameters(Val{Size}, T, Val{N}, Val{L})
        new()
    end
end

@generated function check_marray_parameters{Size,T,N,L}(::Type{Val{Size}}, ::Type{T}, ::Type{Val{N}}, ::Type{Val{L}})
    if !(isa(Size, Tuple{Vararg{Int}}))
        error("MArray parameter Size must be a tuple of Ints (e.g. `MArray{(3,3)}`)")
    end

    if L != prod(Size) || L < 0 || minimum(Size) < 0 || length(Size) != N
        error("Size mismatch")
    end

    return nothing
end

@generated function (::Type{MArray{Size,T,N}}){Size,T,N}(x)
    return quote
        $(Expr(:meta, :inline))
        MArray{Size,T,N,$(prod(Size))}(x)
    end
end

@generated function (::Type{MArray{Size,T}}){Size,T}(x)
    return quote
        $(Expr(:meta, :inline))
        MArray{Size,T,$(length(Size)),$(prod(Size))}(x)
    end
end

@generated function (::Type{MArray{Size}}){Size}(x)
    return quote
        $(Expr(:meta, :inline))
        MArray{Size,$(promote_tuple_eltype(x)),$(length(Size)),$(prod(Size))}(x)
    end
end

####################
## MArray methods ##
####################

@pure size{Size}(::Union{MArray{Size},Type{MArray{Size}}}) = Size
@pure size{Size,T}(::Type{MArray{Size,T}}) = Size
@pure size{Size,T,N}(::Type{MArray{Size,T,N}}) = Size
@pure size{Size,T,N,L}(::Type{MArray{Size,T,N,L}}) = Size

function getindex(v::MArray, i::Integer)
    Base.@_inline_meta
    v.data[i]
end

@propagate_inbounds setindex!{S,T}(v::MArray{S,T}, val, i::Integer) = setindex!(v, convert(T, val), i)
@inline function setindex!{S,T}(v::MArray{S,T}, val::T, i::Integer)
    @boundscheck if i < 1 || i > length(v)
        throw(BoundsError())
    end

    if isbits(T)
        unsafe_store!(Base.unsafe_convert(Ptr{T}, Base.data_pointer_from_objref(v)), val, i)
    else # TODO check that this isn't crazy. Also, check it doesn't cause problems with GC...
        unsafe_store!(Base.unsafe_convert(Ptr{Ptr{Void}}, Base.data_pointer_from_objref(v.data)), Base.data_pointer_from_objref(val), i)
    end

    return val
end

@inline Tuple(v::MArray) = v.data

macro MArray(ex)
    @assert isa(ex, Expr)
    if ex.head == :vect
        return Expr(:call, MArray{(length(ex.args),)}, Expr(:tuple, ex.args...))
    elseif ex.head == :hcat
        s1 = 1
        s2 = length(ex.args)
        return Expr(:call, MArray{(s1, s2)}, Expr(:tuple, ex.args...))
    elseif ex.head == :vcat
        # Validate
        s1 = length(ex.args)
        s2s = map(i -> ((isa(ex.args[i], Expr) && ex.args[i].head == :row) ? length(ex.args[i].args) : 0), 1:s1)
        s2 = minimum(s2s)
        if maximum(s2s) != s2
            error("Rows must be of matching lengths")
        end

        exprs = [ex.args[i].args[j] for i = 1:s1, j = 1:s2]
        return Expr(:call, MArray{(s1, s2)}, Expr(:tuple, exprs...))
    end
end
