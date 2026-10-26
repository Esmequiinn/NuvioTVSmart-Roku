sub init()
    m.top.functionName = "execute"
end sub

function Upd_Repo() as string
    return "Esmequiinn/NuvioTVSmart-Roku"
end function

sub execute()
    m.top.result = Upd_Check()
end sub

function Upd_Check() as object
    res = Upd_Get("https://api.github.com/repos/" + Upd_Repo() + "/releases?per_page=10")
    if res.code <> 200 then return {}
    list = ParseJson(res.body)
    if type(list) <> "roArray" then return {}
    best = invalid
    bestParts = invalid
    for each rel in list
        if type(rel) = "roAssociativeArray" and not Bool_Of(rel.draft, false)
            parts = Upd_Parts(Str_Of(rel.tag_name))
            if parts.Count() = 0 then parts = Upd_Parts(Str_Of(rel.name))
            if parts.Count() > 0 and (best = invalid or Upd_Newer(parts, bestParts))
                best = rel
                bestParts = parts
            end if
        end if
    end for
    if best = invalid then return {}
    local = Upd_Parts(CreateObject("roAppInfo").GetVersion())
    if not Upd_Newer(bestParts, local) then return {}
    tag = Str_Of(best.tag_name)
    if tag <> "" and tag = m.top.seen then return {}
    version = Upd_Join(bestParts)
    lang = m.top.lang
    notes = ""
    if lang = "es"
        notes = Upd_Section(Upd_Raw(tag, "CHANGELOG.es.md"), version)
    else
        notes = Upd_Section(Upd_Raw(tag, "CHANGELOG.md"), version)
    end if
    if notes = "" then notes = Upd_Clean(Str_Of(best.body))
    if notes <> "" and lang <> "es" and lang <> "en" and lang <> ""
        translated = Upd_Translate(notes, lang)
        if translated <> "" then notes = translated
    end if
    return { tag: tag, version: version, notes: Str_Glyphs(notes), url: Str_Of(best.html_url) }
end function

function Upd_Get(url as string) as object
    port = CreateObject("roMessagePort")
    t = Http_Transfer(url, port)
    if Instr(1, url, "api.github.com") > 0 then t.AddHeader("Accept", "application/vnd.github+json")
    out = { code: 0, body: "" }
    if not t.AsyncGetToString() then return out
    msg = wait(10000, port)
    if type(msg) = "roUrlEvent"
        out.code = msg.GetResponseCode()
        out.body = msg.GetString()
    else
        t.AsyncCancel()
    end if
    return out
end function

function Upd_Raw(tag as string, file as string) as string
    for each ref in [tag, "main"]
        if ref <> ""
            res = Upd_Get("https://raw.githubusercontent.com/" + Upd_Repo() + "/" + ref.EncodeUriComponent() + "/" + file)
            if res.code = 200 and res.body <> "" then return res.body
        end if
    end for
    return ""
end function

function Upd_Parts(text as string) as object
    out = []
    num = ""
    started = false
    for i = 1 to Len(text)
        ch = Mid(text, i, 1)
        if ch >= "0" and ch <= "9"
            num = num + ch
            started = true
        else if started and ch = "."
            out.Push(Val(num))
            num = ""
        else if started
            exit for
        end if
    end for
    if num <> "" then out.Push(Val(num))
    return out
end function

function Upd_Newer(a as object, b as object) as boolean
    n = a.Count()
    if b.Count() > n then n = b.Count()
    for i = 0 to n - 1
        x = 0
        y = 0
        if i < a.Count() then x = a[i]
        if i < b.Count() then y = b[i]
        if x <> y then return x > y
    end for
    return false
end function

function Upd_Join(parts as object) as string
    out = []
    for each p in parts
        out.Push(Int(p).ToStr())
    end for
    return out.Join(".")
end function

function Upd_Section(text as string, version as string) as string
    if text = "" then return ""
    lines = text.Split(Chr(10))
    found = false
    picked = []
    for each line in lines
        ln = line.Trim()
        if Left(ln, 3) = "## "
            if found then exit for
            if Instr(1, ln, "[" + version + "]") > 0 or Instr(1, ln, " " + version) > 0 then found = true
        else if found
            picked.Push(line)
        end if
    end for
    if not found then return ""
    return Upd_Clean(picked.Join(Chr(10)))
end function

function Upd_Clean(text as string) as string
    text = text.Replace(Chr(13), "").Replace(Chr(8594), ">")
    links = CreateObject("roRegex", "\[([^\]]*)\]\([^)]*\)", "")
    text = links.ReplaceAll(text, "\1")
    marks = CreateObject("roRegex", "\*\*|__|`", "")
    text = marks.ReplaceAll(text, "")
    out = []
    blank = true
    for each line in text.Split(Chr(10))
        ln = line.Trim()
        if ln = ""
            if not blank then out.Push("")
            blank = true
        else
            if Left(ln, 1) = "#"
                while Left(ln, 1) = "#"
                    ln = Mid(ln, 2)
                end while
                ln = ln.Trim()
                if not blank then out.Push("")
            else if Left(ln, 2) = "- " or Left(ln, 2) = "* "
                ln = "•  " + Mid(ln, 3).Trim()
            end if
            out.Push(ln)
            blank = false
        end if
    end for
    while out.Count() > 0 and out[out.Count() - 1] = ""
        out.Pop()
    end while
    return out.Join(Chr(10))
end function

function Upd_Translate(text as string, lang as string) as string
    port = CreateObject("roMessagePort")
    t = Http_Transfer("https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=" + lang + "&dt=t", port)
    t.AddHeader("Content-Type", "application/x-www-form-urlencoded;charset=UTF-8")
    if not t.AsyncPostFromString("q=" + text.EncodeUriComponent()) then return ""
    msg = wait(10000, port)
    if type(msg) <> "roUrlEvent"
        t.AsyncCancel()
        return ""
    end if
    if msg.GetResponseCode() <> 200 then return ""
    data = ParseJson(msg.GetString())
    if type(data) <> "roArray" or data.Count() = 0 or type(data[0]) <> "roArray" then return ""
    out = ""
    for each seg in data[0]
        if type(seg) = "roArray" and seg.Count() > 0 and IsStr(seg[0]) then out = out + seg[0]
    end for
    return out
end function
