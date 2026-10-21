function IsStr(v as dynamic) as boolean
    if v = invalid then return false
    return GetInterface(v, "ifString") <> invalid
end function

function IsBool(v as dynamic) as boolean
    if v = invalid then return false
    return GetInterface(v, "ifBoolean") <> invalid
end function

function ToInt(v as dynamic, fallback as integer) as integer
    if v = invalid then return fallback
    if GetInterface(v, "ifString") <> invalid then return v.ToInt()
    if GetInterface(v, "ifInt") <> invalid then return v
    if GetInterface(v, "ifLongInt") <> invalid then return v
    if GetInterface(v, "ifFloat") <> invalid then return Int(v)
    if GetInterface(v, "ifDouble") <> invalid then return Int(v)
    return fallback
end function

function Str_Of(v as dynamic) as string
    if IsStr(v) then return v
    return ""
end function

function Str_Any(v as dynamic) as string
    if v = invalid then return ""
    if IsStr(v) then return v
    if GetInterface(v, "ifInt") <> invalid or GetInterface(v, "ifFloat") <> invalid or GetInterface(v, "ifDouble") <> invalid or GetInterface(v, "ifLongInt") <> invalid
        return Str(v).Trim()
    end if
    return ""
end function

function Str_OneLine(v as dynamic) as string
    text = Str_Of(v).Trim()
    if text = "" then return ""
    re = CreateObject("roRegex", "\s*[\r\n]+\s*", "")
    return re.ReplaceAll(text, "  ·  ")
end function

function Str_FirstLine(v as dynamic) as string
    text = Str_Of(v).Trim()
    re = CreateObject("roRegex", "[\r\n]+", "")
    parts = re.Split(text)
    if parts.Count() = 0 then return ""
    return parts[0].Trim()
end function

function TypeLabel(kind as string) as string
    k = LCase(kind)
    if k = "movie" then return L("Película")
    if k = "series" then return L("Serie")
    if k = "anime" then return "Anime"
    if k = "tv" then return L("TV en vivo")
    if k = "channel" then return L("Canal")
    if k = "" then return ""
    return UCase(Left(kind, 1)) + Mid(kind, 2)
end function

function TypePlural(kind as string) as string
    k = LCase(kind)
    if k = "movie" then return L("Películas")
    if k = "series" then return "Series"
    if k = "anime" then return "Anime"
    if k = "tv" then return L("TV en vivo")
    if k = "channel" then return L("Canales")
    return TypeLabel(kind)
end function

function Fmt_Time(seconds as integer) as string
    if seconds < 0 then seconds = 0
    h = Int(seconds / 3600)
    mins = Int((seconds mod 3600) / 60)
    s = seconds mod 60
    ss = s.ToStr()
    if s < 10 then ss = "0" + ss
    if h > 0
        mm = mins.ToStr()
        if mins < 10 then mm = "0" + mm
        return h.ToStr() + ":" + mm + ":" + ss
    end if
    return mins.ToStr() + ":" + ss
end function

function Stream_Format(url as string) as string
    u = LCase(url)
    q = Instr(1, u, "?")
    path = u
    if q > 0 then path = Left(u, q - 1)
    if Instr(1, path, ".m3u8") > 0 or Instr(1, u, "m3u8") > 0 then return "hls"
    if Instr(1, path, ".mpd") > 0 then return "dash"
    if Instr(1, path, ".mkv") > 0 or Instr(1, u, ".mkv") > 0 then return "mkv"
    if Instr(1, path, ".mp4") > 0 or Instr(1, path, ".m4v") > 0 or Instr(1, path, ".mov") > 0 or Instr(1, u, ".mp4") > 0 then return "mp4"
    if Instr(1, path, ".mp3") > 0 then return "mp3"
    return ""
end function

function Net_Ip() as string
    info = CreateObject("roDeviceInfo")
    ips = info.GetIPAddrs()
    if ips <> invalid
        for each name in ips
            if IsStr(ips[name]) and ips[name] <> "" then return ips[name]
        end for
    end if
    return ""
end function

function Net_ServerUrl() as string
    ip = Net_Ip()
    if ip = "" then return ""
    return "http://" + ip + ":8888"
end function

function Net_QrUri(text as string) as string
    return "https://api.qrserver.com/v1/create-qr-code/?size=420x420&margin=14&data=" + text.EncodeUriComponent()
end function

function Bool_Of(v as dynamic, fallback as boolean) as boolean
    if IsBool(v) then return v
    return fallback
end function

function Addon_ImdbId(meta as dynamic) as string
    if type(meta) <> "roAssociativeArray" then return ""
    candidates = [meta.imdb_id, meta.imdbId, meta.imdb, meta.id]
    hints = meta.behaviorHints
    if type(hints) = "roAssociativeArray" then candidates.Push(hints.defaultVideoId)
    re = CreateObject("roRegex", "^tt\d+$", "")
    for each c in candidates
        if IsStr(c)
            if re.IsMatch(c) then return c
        end if
    end for
    return ""
end function

function Addon_UniqueIds(ids as object) as object
    out = []
    seen = {}
    for each id in ids
        if IsStr(id)
            if id <> "" and not seen.DoesExist(id)
                seen[id] = true
                out.Push(id)
            end if
        end if
    end for
    return out
end function

function Img_Logo(imdb as string) as string
    if imdb = "" then return ""
    return "https://images.metahub.space/logo/medium/" + imdb + "/img"
end function

function Img_Background(imdb as string) as string
    if imdb = "" then return ""
    return "https://images.metahub.space/background/medium/" + imdb + "/img"
end function

function Lang_Name(code as string) as string
    c = LCase(code)
    names = { spa: L("Español"), es: L("Español"), "es-mx": L("Español (Latino)"), "es-419": L("Español (Latino)"), "es-es": L("Español (España)"), lat: L("Español (Latino)"), esl: L("Español (Latino)"), spl: L("Español (Latino)"), eng: L("Inglés"), en: L("Inglés"), por: L("Portugués"), pt: L("Portugués"), pob: L("Portugués (Brasil)"), "pt-br": L("Portugués (Brasil)"), fre: L("Francés"), fra: L("Francés"), fr: L("Francés"), ita: L("Italiano"), it: L("Italiano"), ger: L("Alemán"), deu: L("Alemán"), de: L("Alemán"), jpn: L("Japonés"), ja: L("Japonés"), kor: L("Coreano"), ko: L("Coreano"), chi: L("Chino"), zho: L("Chino"), zh: L("Chino"), rus: L("Ruso"), ru: L("Ruso"), ara: L("Árabe"), ar: L("Árabe"), hin: "Hindi", hi: "Hindi", tur: L("Turco"), tr: L("Turco"), pol: L("Polaco"), pl: L("Polaco") }
    if names.DoesExist(c) then return names[c]
    if c = "" then return L("Desconocido")
    return UCase(code)
end function

function Lang_Rank(code as string) as integer
    c = LCase(code)
    if c = "spa" or c = "es" or c = "lat" or c = "esl" or c = "spl" or Left(c, 3) = "es-" then return 0
    if c = "eng" or c = "en" then return 1
    return 2
end function

function Fmt_Clock(dt as object) as string
    h = dt.GetHours()
    mins = dt.GetMinutes()
    suffix = L("a. m.")
    if h >= 12 then suffix = L("p. m.")
    h = h mod 12
    if h = 0 then h = 12
    mm = mins.ToStr()
    if mins < 10 then mm = "0" + mm
    return h.ToStr() + ":" + mm + " " + suffix
end function

function Lang_Iso3(code as string) as string
    c = LCase(code.Trim())
    c = c.Replace("_", "-")
    if c = "" or c = "system" or c = "none" or c = "off" or c = "original" or c = "forced" then return c
    map = { es: "spa", "es-419": "spa", "es-mx": "spa", "es-es": "spa", en: "eng", "en-us": "eng", "en-gb": "eng", pt: "por", "pt-br": "por", "pt-pt": "por", pob: "por", fr: "fre", fra: "fre", it: "ita", de: "ger", deu: "ger", ja: "jpn", ko: "kor", zh: "chi", zho: "chi", ru: "rus", ar: "ara", hi: "hin", tr: "tur", pl: "pol", nl: "dut", nld: "dut" }
    if map.DoesExist(c) then return map[c]
    if Len(c) = 3 then return c
    return Left(c, 2)
end function

function Lang_Device() as string
    locale = CreateObject("roDeviceInfo").GetCurrentLocale()
    return LCase(Left(Str_Of(locale), 2))
end function

function Lang_Resolve(code as string, original as string) as string
    c = LCase(code.Trim())
    if c = "system" or c = "device" then return Lang_Device()
    if c = "original" then return LCase(original)
    if c = "none" or c = "default" or c = "off" or c = "forced" then return ""
    return c
end function

function Lang_Matches(trackLang as string, wanted as string) as boolean
    a = Lang_Iso3(trackLang)
    b = Lang_Iso3(wanted)
    if a = b then return true
    if b = "spa" and (a = "lat" or a = "esl" or a = "spl" or Left(LCase(trackLang), 2) = "es") then return true
    if b = "eng" and Left(LCase(trackLang), 2) = "en" then return true
    if b = "fre" and a = "fra" then return true
    if b = "ger" and a = "deu" then return true
    return false
end function

function Trailer_Content(t as object) as object
    content = CreateObject("roSGNode", "ContentNode")
    content.url = t.url
    content.title = Str_Of(t.title)
    fmt = Str_Of(t.format)
    if fmt = "" then fmt = Stream_Format(t.url)
    if fmt <> "" then content.streamFormat = fmt
    if type(t.headers) = "roArray" and t.headers.Count() > 0 then content.HttpHeaders = t.headers
    if LCase(Left(t.url, 6)) = "https:"
        content.HttpSendClientCertificates = true
        content.HttpCertificatesFile = "common:/certs/ca-bundle.crt"
    end if
    return content
end function
