function Hlsp_Local(kind as string, url as string) as string
    return "http://127.0.0.1:8888/hlsp/" + kind + "?u=" + CreateObject("roUrlTransfer").Escape(url)
end function

function Hlsp_Transfer(url as string, headers as dynamic, port as object) as object
    t = CreateObject("roUrlTransfer")
    t.SetUrl(url)
    t.SetPort(port)
    t.EnableEncodings(true)
    t.RetainBodyOnError(true)
    hasAgent = false
    if type(headers) = "roArray"
        for each h in headers
            if IsStr(h)
                cut = Instr(1, h, ":")
                if cut > 1
                    name = Left(h, cut - 1).Trim()
                    if LCase(name) = "user-agent" then hasAgent = true
                    t.AddHeader(name, Mid(h, cut + 1).Trim())
                end if
            end if
        end for
    end if
    if not hasAgent then t.AddHeader("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36")
    if LCase(Left(url, 6)) = "https:"
        t.SetCertificatesFile("common:/certs/ca-bundle.crt")
        t.InitClientCertificates()
    end if
    return t
end function

function Hlsp_Text(url as string, headers as dynamic, wait_ms as integer) as object
    port = CreateObject("roMessagePort")
    t = Hlsp_Transfer(url, headers, port)
    out = { code: 0, text: "", url: url }
    if not t.AsyncGetToString() then return out
    msg = wait(wait_ms, port)
    if type(msg) = "roUrlEvent"
        out.code = msg.GetResponseCode()
        out.text = msg.GetString()
    else
        t.AsyncCancel()
    end if
    return out
end function

function Hlsp_File(url as string, headers as dynamic, range as string, wait_ms as integer) as object
    port = CreateObject("roMessagePort")
    t = Hlsp_Transfer(url, headers, port)
    t.EnableEncodings(false)
    if range <> "" then t.AddHeader("Range", range)
    file = "tmp:/hlsp_" + CreateObject("roDeviceInfo").GetRandomUUID() + ".bin"
    out = { code: 0, file: "", type: "" }
    if not t.AsyncGetToFile(file) then return out
    msg = wait(wait_ms, port)
    if type(msg) = "roUrlEvent"
        out.code = msg.GetResponseCode()
        out.file = file
        heads = msg.GetResponseHeaders()
        if type(heads) = "roAssociativeArray"
            for each k in heads
                if LCase(k) = "content-type" then out.type = Str_Of(heads[k])
            end for
        end if
    else
        t.AsyncCancel()
        DeleteFile(file)
    end if
    return out
end function

function Hlsp_Abs(base as string, ref as string) as string
    r = ref.Trim()
    low = LCase(r)
    if Left(low, 7) = "http://" or Left(low, 8) = "https://" then return r
    cut = Instr(1, base, "://")
    if cut = 0 then return r
    if Left(r, 2) = "//" then return Left(base, cut) + r
    rest = Mid(base, cut + 3)
    slash = Instr(1, rest, "/")
    origin = base
    path = "/"
    if slash > 0
        origin = Left(base, cut + 2 + slash - 1)
        path = Mid(rest, slash)
    end if
    if Left(r, 1) = "/" then return origin + r
    q = Instr(1, path, "?")
    if q > 0 then path = Left(path, q - 1)
    last = 0
    for i = Len(path) to 1 step -1
        if Mid(path, i, 1) = "/"
            last = i
            exit for
        end if
    end for
    if last > 0 then path = Left(path, last) else path = "/"
    return origin + path + r
end function

function Hlsp_Rewrite(text as string, base as string) as string
    nl = chr(10)
    out = []
    variant = false
    uriRe = CreateObject("roRegex", "URI=" + chr(34) + "([^" + chr(34) + "]+)" + chr(34), "i")
    for each raw in text.Replace(chr(13), "").Split(nl)
        line = raw.Trim()
        if line = ""
            out.Push(line)
        else if Left(line, 1) = "#"
            if Left(UCase(line), 18) = "#EXT-X-STREAM-INF:" then variant = true
            found = uriRe.Match(line)
            if found.Count() > 1
                target = Hlsp_Abs(base, found[1])
                kind = "r"
                if Instr(1, LCase(target), ".m3u8") > 0 or Left(UCase(line), 13) = "#EXT-X-MEDIA:" then kind = "p"
                line = line.Replace(found[1], Hlsp_Local(kind, target))
            end if
            out.Push(line)
        else
            target = Hlsp_Abs(base, line)
            kind = "s"
            if variant or Instr(1, LCase(target), ".m3u8") > 0 then kind = "p"
            variant = false
            out.Push(Hlsp_Local(kind, target))
        end if
    end for
    return out.Join(nl) + nl
end function

function Hlsp_Sync(bytes as object) as integer
    n = bytes.Count()
    for i = 0 to n - 377
        if bytes[i] = 71 and bytes[i + 188] = 71 and bytes[i + 376] = 71 then return i
    end for
    if n > 0 and n < 377 and bytes[0] = 71 then return 0
    return -1
end function

function Hlsp_First(text as string, base as string, wantVariant as boolean) as string
    variant = false
    for each raw in text.Replace(chr(13), "").Split(chr(10))
        line = raw.Trim()
        if Left(UCase(line), 18) = "#EXT-X-STREAM-INF:" then variant = true
        if line <> "" and Left(line, 1) <> "#"
            if wantVariant = variant then return Hlsp_Abs(base, line)
            variant = false
        end if
    end for
    return ""
end function

function Hlsp_Disguised(url as string, headers as dynamic) as boolean
    top = Hlsp_Text(url, headers, 8000)
    if top.code < 200 or top.code >= 400 or Left(top.text.Trim(), 7) <> "#EXTM3U" then return false
    text = top.text
    base = url
    if Instr(1, UCase(text), "#EXT-X-STREAM-INF") > 0
        variant = Hlsp_First(text, url, true)
        if variant = "" then return false
        sub2 = Hlsp_Text(variant, headers, 8000)
        if sub2.code < 200 or sub2.code >= 400 then return false
        text = sub2.text
        base = variant
    end if
    if Instr(1, UCase(text), "#EXT-X-MAP") > 0 then return false
    seg = Hlsp_First(text, base, false)
    if seg = "" then return false
    got = Hlsp_File(seg, headers, "bytes=0-2047", 8000)
    if got.file = "" then return false
    bytes = CreateObject("roByteArray")
    ok = bytes.ReadFile(got.file)
    DeleteFile(got.file)
    if not ok or bytes.Count() < 400 then return false
    if bytes[0] = 71 then return false
    return Hlsp_Sync(bytes) > 0
end function
