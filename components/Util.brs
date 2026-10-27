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
    if GetInterface(v, "ifInt") <> invalid or GetInterface(v, "ifLongInt") <> invalid then return Str(v).Trim()
    if GetInterface(v, "ifFloat") <> invalid or GetInterface(v, "ifDouble") <> invalid
        if v = Int(v) and Abs(v) < 2000000000 then return Str(Int(v)).Trim()
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

function Stream_Attempts(url as string) as object
    fmt = Stream_Format(url)
    u = LCase(url)
    q = Instr(1, u, "?")
    path = u
    if q > 0 then path = Left(u, q - 1)
    list = []
    isTs = Right(path, 3) = ".ts"
    if fmt <> ""
        list.Push({ url: url, fmt: fmt })
        list.Push({ url: url, fmt: "" })
    else if isTs
        if Instr(1, path, "/live/") > 0
            cut = Len(path) - 3
            list.Push({ url: Left(url, cut) + ".m3u8" + Mid(url, Len(path) + 1), fmt: "hls" })
        end if
        list.Push({ url: url, fmt: "" })
        list.Push({ url: url, fmt: "ts" })
        list.Push({ url: url, fmt: "hls" })
    else
        list.Push({ url: url, fmt: "" })
        list.Push({ url: url, fmt: "hls" })
        list.Push({ url: url, fmt: "mkv" })
    end if
    return list
end function

function Img_Fix(url as string) as string
    u = url.Trim()
    if LCase(Left(u, 19)) <> "https://github.com/" then return u
    q = Instr(1, u, "?")
    path = u
    if q > 0 then path = Left(u, q - 1)
    parts = Mid(path, 20).Split("/")
    if parts.Count() < 5 then return u
    if parts[2] <> "blob" and parts[2] <> "raw" then return u
    rest = []
    for i = 3 to parts.Count() - 1
        rest.Push(parts[i])
    end for
    return "https://raw.githubusercontent.com/" + parts[0] + "/" + parts[1] + "/" + rest.Join("/")
end function

function App_Version() as string
    return CreateObject("roAppInfo").GetVersion() + " beta"
end function

function Device_Can4K() as boolean
    info = CreateObject("roDeviceInfo")
    mode = Str_Of(info.GetVideoMode())
    if Left(mode, 4) <> "2160" then return false
    r = info.CanDecodeVideo({ Codec: "hevc" })
    if type(r) = "roAssociativeArray" and r.result = false then return false
    return true
end function

function Device_CanDV() as boolean
    props = CreateObject("roDeviceInfo").GetDisplayProperties()
    if type(props) <> "roAssociativeArray" then return false
    return Bool_Of(props.DolbyVision, false)
end function

function Device_CanHevc() as boolean
    r = CreateObject("roDeviceInfo").CanDecodeVideo({ Codec: "hevc" })
    if type(r) = "roAssociativeArray" and r.result = false then return false
    return true
end function

function Device_Summary() as string
    info = CreateObject("roDeviceInfo")
    res = info.GetUIResolution()
    ui = ""
    if type(res) = "roAssociativeArray" then ui = Str_Of(res.name)
    hevc = L("No")
    if Device_CanHevc() then hevc = L("Sí")
    dv = L("No")
    if Device_CanDV() then dv = L("Sí")
    free = CreateObject("roRegistry").GetSpaceAvailable()
    return L("Espacio libre: ") + free.ToStr() + " bytes  ·  Roku " + Str_Of(info.GetModelDisplayName()) + " (" + Str_Of(info.GetModel()) + ")  ·  " + Str_Of(info.GetVideoMode()) + "  ·  UI " + ui + "  ·  HEVC: " + hevc + "  ·  Dolby Vision: " + dv
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

function Lang_Catalog() as object
    return [
        { code: "af", name: "Afrikaans" }
        { code: "sq", name: "Albanian" }
        { code: "am", name: "Amharic" }
        { code: "ar", name: "Arabic" }
        { code: "hy", name: "Armenian" }
        { code: "az", name: "Azerbaijani" }
        { code: "eu", name: "Basque" }
        { code: "be", name: "Belarusian" }
        { code: "bn", name: "Bengali" }
        { code: "bs", name: "Bosnian" }
        { code: "bg", name: "Bulgarian" }
        { code: "my", name: "Burmese" }
        { code: "ca", name: "Catalan" }
        { code: "zh", name: "Chinese" }
        { code: "zh-CN", name: "Chinese (Simplified)" }
        { code: "zh-TW", name: "Chinese (Traditional)" }
        { code: "hr", name: "Croatian" }
        { code: "cs", name: "Czech" }
        { code: "da", name: "Danish" }
        { code: "nl", name: "Dutch" }
        { code: "en", name: "English" }
        { code: "en-AU", name: "English (Australia)" }
        { code: "en-CA", name: "English (Canada)" }
        { code: "en-GB", name: "English (United Kingdom)" }
        { code: "et", name: "Estonian" }
        { code: "tl", name: "Filipino" }
        { code: "fi", name: "Finnish" }
        { code: "fr", name: "French" }
        { code: "gl", name: "Galician" }
        { code: "ka", name: "Georgian" }
        { code: "de", name: "German" }
        { code: "el", name: "Greek" }
        { code: "gu", name: "Gujarati" }
        { code: "he", name: "Hebrew" }
        { code: "hi", name: "Hindi" }
        { code: "hu", name: "Hungarian" }
        { code: "is", name: "Icelandic" }
        { code: "id", name: "Indonesian" }
        { code: "ga", name: "Irish" }
        { code: "it", name: "Italian" }
        { code: "ja", name: "Japanese" }
        { code: "kn", name: "Kannada" }
        { code: "kk", name: "Kazakh" }
        { code: "km", name: "Khmer" }
        { code: "ko", name: "Korean" }
        { code: "lo", name: "Lao" }
        { code: "lv", name: "Latvian" }
        { code: "lt", name: "Lithuanian" }
        { code: "mk", name: "Macedonian" }
        { code: "ms", name: "Malay" }
        { code: "ml", name: "Malayalam" }
        { code: "mt", name: "Maltese" }
        { code: "mr", name: "Marathi" }
        { code: "mn", name: "Mongolian" }
        { code: "ne", name: "Nepali" }
        { code: "no", name: "Norwegian" }
        { code: "fa", name: "Persian" }
        { code: "pl", name: "Polish" }
        { code: "pt-br", name: "Portuguese (Brazil)" }
        { code: "pt", name: "Portuguese (Portugal)" }
        { code: "pa", name: "Punjabi" }
        { code: "ro", name: "Romanian" }
        { code: "ru", name: "Russian" }
        { code: "sr", name: "Serbian" }
        { code: "si", name: "Sinhala" }
        { code: "sk", name: "Slovak" }
        { code: "sl", name: "Slovenian" }
        { code: "es", name: "Spanish" }
        { code: "es-419", name: "Spanish (Latin America)" }
        { code: "es-MX", name: "Spanish (Mexico)" }
        { code: "sw", name: "Swahili" }
        { code: "sv", name: "Swedish" }
        { code: "ta", name: "Tamil" }
        { code: "te", name: "Telugu" }
        { code: "th", name: "Thai" }
        { code: "tr", name: "Turkish" }
        { code: "uk", name: "Ukrainian" }
        { code: "ur", name: "Urdu" }
        { code: "uz", name: "Uzbek" }
        { code: "vi", name: "Vietnamese" }
        { code: "cy", name: "Welsh" }
        { code: "zu", name: "Zulu" }
    ]
end function

function Lang_CatalogName(code as string) as string
    c = LCase(code)
    for each e in Lang_Catalog()
        if LCase(e.code) = c then return e.name
    end for
    return ""
end function

function Lang_Name(code as string) as string
    c = LCase(code)
    names = { spa: L("Español"), es: L("Español"), "es-mx": L("Español (Latino)"), "es-419": L("Español (Latino)"), "es-es": L("Español (España)"), lat: L("Español (Latino)"), esl: L("Español (Latino)"), spl: L("Español (Latino)"), eng: L("Inglés"), en: L("Inglés"), por: L("Portugués"), pt: L("Portugués"), pob: L("Portugués (Brasil)"), "pt-br": L("Portugués (Brasil)"), fre: L("Francés"), fra: L("Francés"), fr: L("Francés"), ita: L("Italiano"), it: L("Italiano"), ger: L("Alemán"), deu: L("Alemán"), de: L("Alemán"), jpn: L("Japonés"), ja: L("Japonés"), kor: L("Coreano"), ko: L("Coreano"), chi: L("Chino"), zho: L("Chino"), zh: L("Chino"), rus: L("Ruso"), ru: L("Ruso"), ara: L("Árabe"), ar: L("Árabe"), hin: "Hindi", hi: "Hindi", tur: L("Turco"), tr: L("Turco"), pol: L("Polaco"), pl: L("Polaco") }
    if names.DoesExist(c) then return names[c]
    if c = "" then return L("Desconocido")
    known = Lang_CatalogName(c)
    if known <> "" then return known
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

function Fmt_Date(iso as string) as string
    parts = iso.Split("-")
    if parts.Count() < 3 then return iso
    months = ["ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sep", "oct", "nov", "dic"]
    mIndex = parts[1].ToInt() - 1
    if mIndex < 0 or mIndex > 11 then return iso
    return parts[2].ToInt().ToStr() + " " + L(months[mIndex]) + " " + parts[0]
end function

function Flag_Langs() as object
    return {
        MX: "Latino", AR: "Latino", CO: "Latino", CL: "Latino", PE: "Latino", VE: "Latino", EC: "Latino", UY: "Latino", BO: "Latino", PY: "Latino", GT: "Latino", CR: "Latino", PA: "Latino", DO: "Latino", PR: "Latino", CU: "Latino", HN: "Latino", SV: "Latino", NI: "Latino"
        ES: "Castellano", US: "English", GB: "English", CA: "English", AU: "English", IE: "English", NZ: "English"
        BR: "Português (BR)", PT: "Português", FR: "Français", IT: "Italiano", DE: "Deutsch", NL: "Nederlands", PL: "Polski", TR: "Türkçe", SE: "Svenska", NO: "Norsk", DK: "Dansk", FI: "Suomi"
        JP: "Japonés", KR: "Coreano", CN: "Chino", TW: "Chino", HK: "Chino", RU: "Ruso", UA: "Ucraniano", IN: "Hindi", TH: "Tailandés", VN: "Vietnamita", ID: "Indonesio", SA: "Árabe", AE: "Árabe", EG: "Árabe", IL: "Hebreo", GR: "Griego", HU: "Magyar", CZ: "Čeština", RO: "Română"
    }
end function

function Str_IsForeign(cp as integer) as boolean
    if cp < 1424 then return false
    if cp >= 7680 and cp <= 8191 then return false
    if cp < 8192 then return true
    if cp >= 11904 and cp <= 55215 then return true
    if cp >= 63744 and cp <= 64255 then return true
    if cp >= 65280 and cp <= 65519 then return true
    if cp >= 131072 and cp <= 196607 then return true
    return false
end function

function Str_Plain(text as string) as boolean
    ba = CreateObject("roByteArray")
    ba.FromAsciiString(text)
    return ba.Count() = Len(text)
end function

function Str_HasForeign(text as string) as boolean
    if Str_Plain(text) then return false
    n = Len(text)
    for i = 1 to n
        cp = Asc(Mid(text, i, 1))
        if cp >= 55296 and cp <= 56319 and i < n
            low = Asc(Mid(text, i + 1, 1))
            if low >= 56320 and low <= 57343 then cp = 65536 + (cp - 55296) * 1024 + (low - 56320)
        end if
        if Str_IsForeign(cp) then return true
    end for
    return false
end function

function Str_Glyphs(text as string) as string
    if Str_Plain(text) then return text
    keep = { "8211": true, "8212": true, "8216": true, "8217": true, "8220": true, "8221": true, "8226": true, "8230": true }
    out = ""
    dirty = false
    flag = ""
    langs = invalid
    used = {}
    lower = LCase(text)
    n = Len(text)
    i = 1
    while i <= n
        cp = Asc(Mid(text, i, 1))
        if cp >= 55296 and cp <= 56319 and i < n
            low = Asc(Mid(text, i + 1, 1))
            if low >= 56320 and low <= 57343
                cp = 65536 + (cp - 55296) * 1024 + (low - 56320)
                i = i + 1
            end if
        end if
        if cp >= 127462 and cp <= 127487
            dirty = true
            flag = flag + Chr(65 + cp - 127462)
            if Len(flag) = 2
                if langs = invalid then langs = Flag_Langs()
                name = flag
                if langs.DoesExist(flag) then name = langs[flag]
                if not used.DoesExist(name) and Instr(1, lower, LCase(name)) = 0
                    used[name] = true
                    out = out + name
                end if
                flag = ""
            end if
        else
            if flag <> "" then flag = ""
            if (cp >= 8192 and not keep.DoesExist(cp.ToStr())) or Str_IsForeign(cp)
                dirty = true
            else
                out = out + Chr(cp)
            end if
        end if
        i = i + 1
    end while
    if not dirty then return text
    re = CreateObject("roRegex", "[ \t]{2,}", "")
    out = re.ReplaceAll(out, " ")
    edge = CreateObject("roRegex", "^[\s:|/,\-]+|[\s:|/,\-(]+$", "")
    return edge.ReplaceAll(out, "")
end function

function Str_CleanDeep(v as dynamic) as dynamic
    if IsStr(v)
        if Left(v, 4) = "http" or Left(v, 4) = "pkg:" then return v
        return Str_Glyphs(v)
    end if
    t = type(v)
    if t = "roArray"
        for i = 0 to v.Count() - 1
            v[i] = Str_CleanDeep(v[i])
        end for
    else if t = "roAssociativeArray"
        skip = { id: true, url: true, poster: true, logo: true, background: true, thumb: true, photo: true, image: true, imdb_id: true, trailerLocal: true, behaviorHints: true, links: true, videoId: true, slug: true }
        for each k in v
            if not skip.DoesExist(k) then v[k] = Str_CleanDeep(v[k])
        end for
    end if
    return v
end function
