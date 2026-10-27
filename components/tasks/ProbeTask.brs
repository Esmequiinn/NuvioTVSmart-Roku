sub init()
    m.top.functionName = "execute"
end sub

sub execute()
    out = { ts: false, size: 0&, type: "", code: 0 }
    port = CreateObject("roMessagePort")
    t = Http_Transfer(m.top.url, port)
    t.AddHeader("Range", "bytes=0-375")
    if type(m.top.headers) = "roArray"
        for each h in m.top.headers
            if IsStr(h)
                cut = Instr(1, h, ":")
                if cut > 1 then t.AddHeader(Left(h, cut - 1).Trim(), Mid(h, cut + 1).Trim())
            end if
        end for
    end if
    if t.AsyncGetToString()
        msg = wait(5000, port)
        if type(msg) = "roUrlEvent"
            out.code = msg.GetResponseCode()
            heads = msg.GetResponseHeaders()
            body = msg.GetString()
            kind = ""
            range = ""
            length = ""
            if type(heads) = "roAssociativeArray"
                for each k in heads
                    lk = LCase(k)
                    if lk = "content-type" then kind = LCase(Str_Of(heads[k]))
                    if lk = "content-range" then range = Str_Of(heads[k])
                    if lk = "content-length" then length = Str_Of(heads[k])
                end for
            end if
            out.type = kind
            slash = Instr(1, range, "/")
            if slash > 0 then out.size = Probe_Long(Mid(range, slash + 1))
            if out.size <= 0 and out.code = 200 and length <> "" then out.size = Probe_Long(length)
            sync = Len(body) > 0 and Asc(Left(body, 1)) = 71
            out.ts = Instr(1, kind, "mp2t") > 0 or Instr(1, kind, "mpegts") > 0 or (sync and Instr(1, kind, "mpegurl") = 0 and Instr(1, kind, "mp4") = 0)
            out.ranges = out.code = 206
        else
            t.AsyncCancel()
        end if
    end if
    m.top.result = out
end sub

function Probe_Long(text as string) as longinteger
    n = 0&
    for i = 1 to Len(text)
        c = Asc(Mid(text, i, 1))
        if c >= 48 and c <= 57
            n = n * 10 + (c - 48)
        else if n > 0
            exit for
        end if
    end for
    return n
end function
