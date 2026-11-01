sub init()
    m.top.functionName = "execute"
end sub

sub execute()
    out = { ts: false, size: 0&, type: "", code: 0, url: "", fmt: "" }
    target = m.top.url
    d = m.top.debrid
    if type(d) = "roAssociativeArray" and Str_Of(d.hash) <> ""
        r = Deb_Resolve(St_Integrations(), d)
        if not Bool_Of(r.ok, false)
            m.top.result = { failed: true, error: Str_Of(r.error) }
            return
        end if
        target = r.url
        out.url = target
    end if
    port = CreateObject("roMessagePort")
    t = Http_Transfer(target, port)
    t.AddHeader("Range", "bytes=0-375")
    if type(m.top.headers) = "roArray"
        for each h in m.top.headers
            if IsStr(h)
                cut = Instr(1, h, ":")
                if cut > 1 then t.AddHeader(Left(h, cut - 1).Trim(), Mid(h, cut + 1).Trim())
            end if
        end for
    end if
    file = "tmp:/probe_" + CreateObject("roDateTime").AsSeconds().ToStr() + "_" + Rnd(1000000).ToStr() + ".bin"
    if t.AsyncGetToFile(file)
        msg = wait(5000, port)
        if type(msg) = "roUrlEvent"
            out.code = msg.GetResponseCode()
            heads = msg.GetResponseHeaders()
            bytes = CreateObject("roByteArray")
            if not bytes.ReadFile(file) then bytes = CreateObject("roByteArray")
            DeleteFile(file)
            disposition = ""
            kind = ""
            range = ""
            length = ""
            if type(heads) = "roAssociativeArray"
                for each k in heads
                    lk = LCase(k)
                    if lk = "content-type" then kind = LCase(Str_Of(heads[k]))
                    if lk = "content-range" then range = Str_Of(heads[k])
                    if lk = "content-length" then length = Str_Of(heads[k])
                    if lk = "content-disposition" then disposition = Str_Of(heads[k])
                end for
            end if
            out.type = kind
            slash = Instr(1, range, "/")
            if slash > 0 then out.size = Probe_Long(Mid(range, slash + 1))
            if out.size <= 0 and out.code = 200 and length <> "" then out.size = Probe_Long(length)
            sync = bytes.Count() > 0 and bytes[0] = 71
            out.fmt = Probe_Format(bytes, kind, disposition)
            out.ts = Instr(1, kind, "mp2t") > 0 or Instr(1, kind, "mpegts") > 0 or (sync and Instr(1, kind, "mpegurl") = 0 and Instr(1, kind, "mp4") = 0)
            out.ranges = out.code = 206
        else
            t.AsyncCancel()
        end if
    end if
    m.top.result = out
end sub

function Probe_Format(bytes as object, kind as string, disposition as string) as string
    if bytes.Count() >= 4 and bytes[0] = 26 and bytes[1] = 69 and bytes[2] = 223 and bytes[3] = 163 then return "mkv"
    if bytes.Count() >= 8 and bytes[4] = 102 and bytes[5] = 116 and bytes[6] = 121 and bytes[7] = 112 then return "mp4"
    if Instr(1, kind, "matroska") > 0 or Instr(1, kind, "webm") > 0 then return "mkv"
    if Instr(1, kind, "video/mp4") > 0 or Instr(1, kind, "quicktime") > 0 then return "mp4"
    low = LCase(disposition)
    if Instr(1, low, ".mkv") > 0 then return "mkv"
    if Instr(1, low, ".mp4") > 0 or Instr(1, low, ".m4v") > 0 then return "mp4"
    return ""
end function

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
