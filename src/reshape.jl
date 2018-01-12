export stack, unstack

"""
    `stack(t, by = pkeynames(t); select = excludecols(t, by), value = :value, variable = :variable)`

Reshape a table from the wide to the long format. Columns in `by` are kept as indexing columns.
Columns in `select` are stacked. In addition to the id columns, two additional columns labeled `variable` and `value`
are added, containg the column identifier and the stacked columns.

## Examples

```jldoctest stack
julia> t = table(1:4, [1, 4, 9, 16], [1, 8, 27, 64], names = [:x, :xsquare, :xcube], pkey = :x);

julia> stack(t)
Table with 8 rows, 3 columns:
x  variable  value
──────────────────
1  :xsquare  1
1  :xcube    1
2  :xsquare  4
2  :xcube    8
3  :xsquare  9
3  :xcube    27
4  :xsquare  16
4  :xcube    64
```
"""
function stack(t::NextTable, by = pkeynames(t); select = excludecols(t, by), value = :value, variable = :variable)
    (by != pkeynames(t)) && return stack(reindex(t, by, select); value = value, variable = variable)    

    valuecols = columns(t, select)
    valuecol = vec([valuecol[i] for valuecol in valuecols, i in 1:length(t)])

    labels = fieldnames(valuecols)
    labelcol = vec([label for label in labels, i in 1:length(t)])
    
    bycols = map(arg -> repeat(arg, inner = length(valuecols)), columns(t, by))
    convert(NextTable, Columns(bycols), Columns(labelcol, valuecol, names = [variable, value]))
end

function unstack(::Type{T}, key, val, cols) where {T}
    dest_val = Columns((DataValues.DataValueArray{T}(length(val)) for i in cols)...; names = cols)
    for (i, el) in enumerate(val)
        for j in el
            k, v = j
            isnull(columns(dest_val, k)[i]) || error("Repeated values with same label are not allowed")
            columns(dest_val, k)[i] = v
        end
    end
    convert(NextTable, key, dest_val)
end

function unstack(t::NextTable, by = pkeynames(t); variable = :variable, value = :value)
    tgrp = groupby((value => identity,), t, by, select = (variable, value))
    cols = union(columns(t, variable))
    T = eltype(columns(t, value))
    unstack(T isa Type{<:DataValue} ? eltype(T) : T, pkeys(tgrp), columns(tgrp, value), cols)
end
