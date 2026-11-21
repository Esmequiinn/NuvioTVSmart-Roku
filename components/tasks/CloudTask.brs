sub init()
    m.top.functionName = "execute"
end sub

sub execute()
    p = m.top.params
    if type(p) <> "roAssociativeArray" then p = {}
    mode = Str_Of(p.mode)
    provider = Str_Of(p.provider)
    result = { ok: false, error: "" }
    try
        if mode = "list"
            result = Cloud_ListAll()
        else if mode = "files"
            result = Cloud_Files(provider, p.item)
            result.index = ToInt(p.index, -1)
        end if
    catch e
        result = { ok: false, error: Str_Of(e.message) }
    end try
    result.mode = mode
    m.top.result = result
end sub
