using TableTraits
using TableTraitsUtils

TableTraits.isiterable(x::NDSparse) = true
TableTraits.isiterabletable(x::NDSparse) = true

function TableTraits.getiterator{S<:NDSparse}(source::S)
    return rows(source)
end

function NDSparse(x; idxcols::Union{Void,Vector{Symbol}}=nothing, datacols::Union{Void,Vector{Symbol}}=nothing)
    if isiterabletable(x)
        iter = getiterator(x)

        source_colnames = TableTraits.column_names(iter)

        if idxcols==nothing && datacols==nothing
            idxcols = source_colnames[1:end-1]
            datacols = [source_colnames[end]]
        elseif idxcols==nothing
            idxcols = setdiff(source_colnames,datacols)
        elseif datacols==nothing
            datacols = setdiff(source_colnames, idxcols)
        end

        if length(setdiff(idxcols, source_colnames))>0
            error("Unknown idxcol")
        end

        if length(setdiff(datacols, source_colnames))>0
            error("Unknown datacol")
        end

        source_data, source_names = TableTraitsUtils.create_columns_from_iterabletable(x)

        idxcols_indices = [findfirst(source_colnames,i) for i in idxcols]
        datacols_indices = [findfirst(source_colnames,i) for i in datacols]

        idx_storage = Columns(source_data[idxcols_indices]..., names=source_colnames[idxcols_indices])
        data_storage = Columns(source_data[datacols_indices]..., names=source_colnames[datacols_indices])

        return NDSparse(idx_storage, data_storage)
    elseif idxcols==nothing && datacols==nothing
        return convert(NDSparse, x)
    else
        throw(ArgumentError("x cannot be turned into an NDSparse."))
    end
end
