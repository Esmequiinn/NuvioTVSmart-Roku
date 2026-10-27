function Stream_Build(s as object, url as string, addon as object, badgeRules as object, sizeBadges as boolean) as object
    name = Str_Lines(s.name)
    desc = Str_Lines(s.title)
    if desc = "" then desc = Str_Lines(s.description)
    if desc = "" then desc = Str_Lines(s.desc)
    headers = []
    binge = ""
    filename = ""
    hints = s.behaviorHints
    if type(hints) = "roAssociativeArray"
        if type(hints.proxyHeaders) = "roAssociativeArray"
            req = hints.proxyHeaders.request
            if type(req) = "roAssociativeArray"
                for each k in req
                    if IsStr(req[k]) then headers.Push(k + ": " + req[k])
                end for
            end if
        end if
        binge = Str_Of(hints.bingeGroup)
        filename = Str_Of(hints.filename)
    end if
    text = [addon.name, name, desc, filename].Join(chr(10))
    chips = Stream_Chips(text)
    size = Stream_Size(text, hints)
    if sizeBadges and size <> "" then chips.Push(size)
    label = name
    if label = "" then label = addon.name
    first = Str_FirstLine(desc)
    if first <> "" then label = Str_OneLine(label) + "  ·  " + first
    lines = [filename, addon.name]
    for each part in [name, desc]
        for each line in part.Split(chr(10))
            if line.Trim() <> "" then lines.Push(line.Trim())
        end for
    end for
    return {
        url: url
        headers: headers
        name: name
        desc: desc
        addon: addon.name
        logo: addon.logo
        order: addon.order
        binge: binge
        filename: filename
        chips: chips
        badges: Stream_Fusion(lines, badgeRules)
        label: Left(Str_OneLine(label), 120)
    }
end function


function Str_Lines(v as dynamic) as string
    text = Str_Glyphs(Str_Of(v))
    if text = "" then return ""
    re = CreateObject("roRegex", "\r\n?", "")
    text = re.ReplaceAll(text, chr(10))
    out = []
    for each line in text.Split(chr(10))
        t = line.Trim()
        if t <> "" then out.Push(t)
    end for
    return out.Join(chr(10))
end function

function Stream_Chips(text as string) as object
    chips = []
    checks = [
        ["(2160p|\b4k\b|\buhd\b)", "4K"]
        ["1440p", "1440p"]
        ["1080p", "1080p"]
        ["720p", "720p"]
        ["(480p|576p|\bsd\b)", "SD"]
    ]
    for each c in checks
        if CreateObject("roRegex", c[0], "i").IsMatch(text)
            chips.Push(c[1])
            exit for
        end if
    end for
    if CreateObject("roRegex", "\bremux\b", "i").IsMatch(text) then chips.Push("REMUX")
    if CreateObject("roRegex", "(\bdv\b|\bdovi\b|dolby[ ._-]?vision)", "i").IsMatch(text)
        chips.Push("DV")
    else if CreateObject("roRegex", "(hdr10\+|hdr10plus)", "i").IsMatch(text)
        chips.Push("HDR10+")
    else if CreateObject("roRegex", "\b(hdr|hdr10|hlg)\b", "i").IsMatch(text)
        chips.Push("HDR")
    end if
    codecs = [["(\bhevc\b|x265|h\.?265)", "HEVC"], ["\bav1\b", "AV1"], ["(\bavc\b|x264|h\.?264)", "H.264"]]
    for each c in codecs
        if CreateObject("roRegex", c[0], "i").IsMatch(text)
            chips.Push(c[1])
            exit for
        end if
    end for
    audios = [["atmos", "Atmos"], ["truehd", "TrueHD"], ["(dts[ ._-]?x|dts:x)", "DTS:X"], ["dts[ ._-]?hd", "DTS-HD"], ["\bdts\b", "DTS"], ["(\bddp|dd\+|e-?ac-?3|\beac3)", "DD+"], ["(\bdd\b|\bac-?3\b|dolby digital)", "DD"], ["\baac\b", "AAC"]]
    for each c in audios
        if CreateObject("roRegex", c[0], "i").IsMatch(text)
            chips.Push(c[1])
            exit for
        end if
    end for
    return chips
end function

function Stream_Size(text as string, hints as dynamic) as string
    if type(hints) = "roAssociativeArray" and hints.videoSize <> invalid
        bytes = 0.0 + hints.videoSize
        if bytes > 0
            gb = bytes / 1073741824.0
            if gb >= 1 then return Fmt_Decimal(gb) + " GB"
            return Int(bytes / 1048576.0).ToStr() + " MB"
        end if
    end if
    re = CreateObject("roRegex", "(\d+(?:[.,]\d+)?)\s?(GB|GiB|MB|MiB|TB)\b", "i")
    found = re.Match(text)
    if found.Count() < 3 then return ""
    unit = UCase(found[2])
    if unit = "GIB" then unit = "GB"
    if unit = "MIB" then unit = "MB"
    return found[1].Replace(",", ".") + " " + unit
end function

function Fmt_Decimal(v as dynamic) as string
    whole = Int(v)
    dec = Int((v - whole) * 10 + 0.5)
    if dec >= 10
        whole = whole + 1
        dec = 0
    end if
    return whole.ToStr() + "." + dec.ToStr()
end function

function Badge_Compact(raw as dynamic) as object
    data = raw
    if IsStr(raw)
        if raw.Trim() = "" then return []
        data = ParseJson(raw)
    end if
    if type(data) <> "roAssociativeArray" then return []
    imports = []
    if type(data.imports) = "roArray"
        imports = data.imports
    else if type(data.filters) = "roArray"
        imports = [data]
    end if
    chosen = invalid
    for each imp in imports
        if type(imp) = "roAssociativeArray" and chosen = invalid
            if Bool_Of(imp.isActive, true) then chosen = imp
        end if
    end for
    if chosen = invalid and imports.Count() > 0 then chosen = imports[0]
    out = []
    if type(chosen) <> "roAssociativeArray" or type(chosen.filters) <> "roArray" then return out
    for each f in chosen.filters
        if type(f) = "roAssociativeArray" and out.Count() < 80
            pattern = Str_Of(f.pattern).Trim()
            name = Str_Of(f.name).Trim()
            if pattern <> "" and name <> "" and Bool_Of(f.isEnabled, true)
                out.Push({ p: pattern, i: Str_Of(f.imageURL).Trim(), n: Left(name, 24), c: Badge_Color(f.tagColor), t: Badge_Color(f.textColor) })
            end if
        end if
    end for
    return out
end function

function Badge_Color(v as dynamic) as string
    hex = Str_Of(v).Trim()
    if Left(hex, 1) = "#" then hex = Mid(hex, 2)
    if not CreateObject("roRegex", "^[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$", "").IsMatch(hex) then return ""
    if Len(hex) = 8 then hex = Mid(hex, 3) + Left(hex, 2)
    if Len(hex) = 6 then hex = hex + "FF"
    return "0x" + UCase(hex)
end function

function Badge_Compile(rules as object) as object
    out = []
    for each r in rules
        pattern = Str_Of(r.p)
        flags = ""
        re = CreateObject("roRegex", "^\(\?([imsx]+)\)", "i")
        found = re.Match(pattern)
        while found.Count() > 1
            f = LCase(found[1])
            if Instr(1, f, "i") > 0 then flags = flags + "i"
            if Instr(1, f, "m") > 0 then flags = flags + "m"
            if Instr(1, f, "s") > 0 then flags = flags + "s"
            pattern = Mid(pattern, Len(found[0]) + 1)
            found = re.Match(pattern)
        end while
        compiled = CreateObject("roRegex", pattern, flags)
        if compiled <> invalid then out.Push({ re: compiled, i: r.i, n: r.n, c: r.c, t: r.t })
    end for
    return out
end function

function Stream_Fusion(lines as object, compiled as object) as object
    out = []
    if compiled = invalid or compiled.Count() = 0 then return out
    joined = []
    for each entry in lines
        if Str_Of(entry) <> "" then joined.Push(entry)
    end for
    candidates = []
    for each entry in joined
        candidates.Push(entry)
    end for
    if joined.Count() > 1 then candidates.Push(joined.Join(" "))
    seen = {}
    for each rule in compiled
        key = LCase(rule.i + "|" + rule.n)
        if not seen.DoesExist(key)
            for each c in candidates
                if rule.re.IsMatch(c)
                    seen[key] = true
                    out.Push({ i: rule.i, n: rule.n, c: rule.c, t: rule.t })
                    exit for
                end if
            end for
        end if
        if out.Count() >= 8 then exit for
    end for
    return out
end function

function Autoplay_Presets() as object
    return [
        { name: L("1080p o mayor"), p: "(2160p|4k|1080p)" }
        { name: "4K / Remux", p: "(2160p|4k|remux)" }
        { name: L("1080p estándar"), p: "(1080p|full\s*hd)" }
        { name: L("720p o menor"), p: "(720p|webrip|web-dl)" }
        { name: L("Fuentes WEB"), p: "(web-?dl|webrip|\bweb\b)" }
        { name: "BluRay", p: "(bluray|blu-ray|bdrip|brrip)" }
        { name: "HEVC / x265", p: "(hevc|x265|h\.?265)" }
        { name: "AVC / x264", p: "(\bavc\b|x264|h\.?264)" }
        { name: "HDR / Dolby Vision", p: "\b(hdr|hdr10\+?|dv|dolby\s*vision)\b" }
        { name: L("HDR sin Dolby Vision"), p: "^(?=.*\b(hdr|hdr10\+?)\b)(?!.*\b(dv|dovi|dolby\s*vision)\b).*$" }
        { name: "Atmos / DTS", p: "(atmos|\bdts\b|truehd)" }
        { name: "Latino", p: "(latino|\blat\b|español|espanol|spanish|castellano|dual)" }
        { name: L("Inglés"), p: "(english|\beng\b)" }
        { name: L("Sin CAM/TS"), p: "^(?!.*\b(cam|hdcam|ts|telesync)\b).*$" }
        { name: L("Sin REMUX/HDR"), p: "^(?!.*\b(remux|hdr|dv|dolby\s*vision)\b).*$" }
    ]
end function

function Autoplay_Exclusion(pattern as string) as dynamic
    finder = CreateObject("roRegex", "\(\?![^)]*?\(([^)]+)\)", "")
    terms = []
    rest = pattern
    found = finder.Match(rest)
    guard = 0
    while found.Count() > 1 and guard < 10
        for each t in found[1].Split("|")
            if t.Trim() <> "" then terms.Push(t.Trim())
        end for
        cut = Instr(1, rest, found[0])
        rest = Mid(rest, cut + Len(found[0]))
        found = finder.Match(rest)
        guard = guard + 1
    end while
    if terms.Count() = 0 then return invalid
    return CreateObject("roRegex", "\b(" + terms.Join("|") + ")\b", "i")
end function

function Stream_SearchText(s as object) as string
    return [Str_Of(s.addon), Str_OneLine(s.name), Str_OneLine(s.desc), Str_Of(s.filename), Str_Of(s.url)].Join(" ")
end function

function Stream_Unplayable(s as object) as boolean
    if m.devCaps = invalid
        m.devCaps = { k4: Device_Can4K(), hevc: Device_CanHevc(), dv: Device_CanDV() }
        m.devCaps.dvRe = CreateObject("roRegex", "\b(dv|dovi|dolby\s*vision)\b", "i")
        m.devCaps.hdrRe = CreateObject("roRegex", "\bhdr(10)?\+?\b", "i")
        m.devCaps.uhd = CreateObject("roRegex", "2160p|\b4k\b|\buhd\b", "i")
        m.devCaps.hevcRe = CreateObject("roRegex", "\b(x265|hevc|h\.?265|10bit|10-bit|hdr|hdr10|dv|dolby\s*vision)\b", "i")
    end if
    text = Stream_SearchText(s)
    if not m.devCaps.k4 and m.devCaps.uhd.IsMatch(text) then return true
    if not m.devCaps.hevc and m.devCaps.hevcRe.IsMatch(text) then return true
    if not m.devCaps.dv and m.devCaps.dvRe.IsMatch(text) and not m.devCaps.hdrRe.IsMatch(text) then return true
    return false
end function

function Autoplay_Prefer(streams as object, candidates as object) as object
    if not Bool_Of(St_Pref("rokuSafe"), true) then return candidates
    audio = CreateObject("roRegex", "\b(remux|truehd|true-hd|dts-hd|dts-ma|dtshd|dts-x|dtsx)\b", "i")
    good = []
    risky = []
    for each i in candidates
        if not Stream_Unplayable(streams[i])
            if audio.IsMatch(Stream_SearchText(streams[i])) then risky.Push(i) else good.Push(i)
        end if
    end for
    for each i in risky
        good.Push(i)
    end for
    return good
end function

function Autoplay_Pick(streams as object, opts as object) as integer
    if streams = invalid or streams.Count() = 0 then return -1
    file = LCase(Str_Of(opts.file))
    if file <> ""
        for i = 0 to streams.Count() - 1
            if LCase(Str_Of(streams[i].filename)) = file then return i
        end for
    end if
    safe = Bool_Of(St_Pref("rokuSafe"), true)
    binge = Str_Of(opts.binge)
    if binge <> ""
        for i = 0 to streams.Count() - 1
            if streams[i].binge = binge and not (safe and Stream_Unplayable(streams[i])) then return i
        end for
        if opts.noFallback = true then return -1
    end if
    mode = Str_Of(opts.mode)
    if mode = "manual" or mode = "" then return -1
    if Str_Of(opts.scope) = "plugins" then return -1
    allowed = {}
    if type(opts.addons) = "roArray"
        for each a in opts.addons
            if IsStr(a) and a <> "" then allowed[a] = true
        end for
    end if
    candidates = []
    for i = 0 to streams.Count() - 1
        if allowed.Count() = 0 or allowed.DoesExist(streams[i].addon) then candidates.Push(i)
    end for
    if candidates.Count() = 0 then return -1
    candidates = Autoplay_Prefer(streams, candidates)
    if mode = "first" then return candidates[0]
    pattern = Str_Of(opts.regex).Trim()
    if pattern = "" then return -1
    re = CreateObject("roRegex", pattern, "i")
    if re = invalid then return -1
    exclusion = Autoplay_Exclusion(pattern)
    for each i in candidates
        text = Stream_SearchText(streams[i])
        if re.IsMatch(text)
            if exclusion = invalid
                return i
            else if not exclusion.IsMatch(text)
                return i
            end if
        end if
    end for
    return -1
end function
