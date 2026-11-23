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

function Rating_Text(v as dynamic) as string
    s = Str_Any(v).Trim()
    if s = "" then return ""
    x = Val(s)
    if x <= 0 then return ""
    if x > 10 then x = x / 10
    r = Int(x * 10 + 0.5)
    return Int(r / 10).ToStr() + "." + (r Mod 10).ToStr()
end function

function Img_Sized(url as string, size as string) as string
    marker = "image.tmdb.org/t/p/"
    at = Instr(1, url, marker)
    if at = 0 then return url
    start = at + Len(marker)
    slash = Instr(start, url, "/")
    if slash = 0 then return url
    current = Mid(url, start, slash - start)
    if current <> "original" and Left(current, 1) <> "w" then return url
    if current <> "original" and Val(Mid(current, 2)) <= Val(Mid(size, 2)) then return url
    return Left(url, start - 1) + size + Mid(url, slash)
end function

function Str_Any(v as dynamic) as string
    if v = invalid then return ""
    if IsStr(v) then return v
    if GetInterface(v, "ifInt") <> invalid or GetInterface(v, "ifLongInt") <> invalid then return Str(v).Trim()
    if GetInterface(v, "ifFloat") <> invalid or GetInterface(v, "ifDouble") <> invalid
        d# = v
        if d# = Fix(d#) then return Num_Whole(d#)
        return Str(v).Trim()
    end if
    return ""
end function

function Num_Whole(d as double) as string
    negative = d < 0
    if negative then d = -d
    digits = ""
    while d >= 1
        q# = Fix(d / 10)
        digit = Int(d - q# * 10 + 0.5)
        if digit > 9 then digit = 9
        digits = digit.ToStr() + digits
        d = q#
    end while
    if digits = "" then digits = "0"
    if negative then digits = "-" + digits
    return digits
end function

function Num_Exact(text as string) as string
    found = CreateObject("roRegex", "^\s*(-?)([0-9]*)(?:\.([0-9]*))?(?:[eE]([+-]?[0-9]+))?\s*$", "").Match(text)
    if found.Count() < 2 then return ""
    whole = found[2]
    frac = ""
    if found.Count() > 3 then frac = found[3]
    shift = 0
    if found.Count() > 4 and found[4] <> "" then shift = found[4].ToInt()
    digits = whole + frac
    point = Len(whole) + shift
    if point <= 0 then return "0"
    while Len(digits) < point
        digits = digits + "0"
    end while
    out = Left(digits, point)
    while Len(out) > 1 and Left(out, 1) = "0"
        out = Mid(out, 2)
    end while
    if out = "" then out = "0"
    if found[1] = "-" and out <> "0" then out = "-" + out
    return out
end function

function Json_Parse(text as string) as dynamic
    if Instr(1, text, "ListId") > 0 then text = Json_FixIds(text)
    return ParseJson(text)
end function

function Json_FixIds(text as string) as string
    re = CreateObject("roRegex", "(" + chr(34) + "[A-Za-z]*ListId" + chr(34) + "\s*:\s*)(-?[0-9][0-9.eE+-]*)", "")
    out = ""
    rest = text
    while true
        found = re.Match(rest)
        if found.Count() < 3 then exit while
        at = Instr(1, rest, found[0])
        out = out + Left(rest, at - 1) + found[1] + chr(34) + Num_Exact(found[2]) + chr(34)
        rest = Mid(rest, at + Len(found[0]))
    end while
    return out + rest
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

function Stream_Attempts(url as string, hint = "" as string) as object
    fmt = Stream_Format(url)
    if fmt = "" then fmt = hint
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

function App_Edition() as string
    info = CreateObject("roAppInfo")
    edition = LCase(Str_Of(info.GetValue("edition")).Trim())
    if edition = "" and Instr(1, UCase(Str_Of(info.GetTitle())), "IPTV") > 0 then edition = "iptv"
    return edition
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

function Device_Audio() as object
    if m.audioCaps <> invalid then return m.audioCaps
    info = CreateObject("roDeviceInfo")
    caps = {}
    checks = { ac3: { Codec: "ac3" }, eac3: { Codec: "eac3" }, dts: { Codec: "dts" }, truehd: { Codec: "truehd" }, multi: { Codec: "aac", ChCnt: 6 } }
    for each key in checks
        r = info.CanDecodeAudio(checks[key])
        caps[key] = type(r) = "roAssociativeArray" and r.result = true
    end for
    m.audioCaps = caps
    return caps
end function

function Device_AudioSummary() as string
    caps = Device_Audio()
    names = [["multi", "5.1"], ["ac3", "Dolby Digital"], ["eac3", "Dolby Digital Plus"], ["dts", "DTS"], ["truehd", "TrueHD"]]
    yes = [L("Estéreo")]
    no = []
    for each n in names
        if caps[n[0]] then yes.Push(n[1]) else no.Push(n[1])
    end for
    text = L("Sí: ") + yes.Join(", ")
    if no.Count() > 0 then text = text + "  ·  " + L("No: ") + no.Join(", ")
    return text
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

function Lang_AliasMap() as object
    if m.langAliasMap <> invalid then return m.langAliasMap
    m.langAliasMap = {
        pob: "pt-br", pb: "pt-br", ptbr: "pt-br", "pt-br": "pt-br", "por-br": "pt-br", brazilian: "pt-br", "portuguese (brazil)": "pt-br", "portugues (brasil)": "pt-br", "português (brasil)": "pt-br", portuguesebrazil: "pt-br"
        "pt-pt": "pt-pt", ptpt: "pt-pt", "por-pt": "pt-pt", "portuguese (portugal)": "pt-pt", "português (portugal)": "pt-pt"
        por: "pt", pt: "pt", portuguese: "pt", portugues: "pt", "português": "pt"
        "es-419": "es-419", "es-la": "es-419", "es-mx": "es-419", "es-ar": "es-419", "es-cl": "es-419", "es-co": "es-419", "es-pe": "es-419", "es-ve": "es-419"
        lat: "es-419", esl: "es-419", spl: "es-419", latam: "es-419", latino: "es-419", "latin spanish": "es-419", "latin american spanish": "es-419", "español latino": "es-419", "spanish (latin america)": "es-419", "spanish (mexico)": "es-419"
        "es-es": "es-es", castellano: "es-es", "español (españa)": "es-es", "castilian": "es-es"
        spa: "es", esp: "es", es: "es", spanish: "es", espanol: "es", "español": "es"
        eng: "en", en: "en", english: "en", ingles: "en", "inglés": "en", "en-us": "en", "en-gb": "en", "en-au": "en", "en-ca": "en"
        "zh-cn": "zh-cn", "zh-hans": "zh-cn", "zho-hans": "zh-cn", chs: "zh-cn", "chinese (simplified)": "zh-cn"
        "zh-tw": "zh-tw", "zh-hk": "zh-tw", "zh-hant": "zh-tw", cht: "zh-tw", zht: "zh-tw", "chinese (traditional)": "zh-tw"
        yue: "zh-ca", "zh-ca": "zh-ca", cantonese: "zh-ca"
        chi: "zh", zho: "zh", zh: "zh", chinese: "zh", chino: "zh"
        fre: "fr", fra: "fr", fr: "fr", "fr-fr": "fr", "fr-ca": "fr", french: "fr", frances: "fr", "francés": "fr", "français": "fr"
        ger: "de", deu: "de", de: "de", "de-de": "de", german: "de", deutsch: "de", aleman: "de", "alemán": "de"
        ita: "it", it: "it", "it-it": "it", italian: "it", italiano: "it"
        jpn: "ja", ja: "ja", jap: "ja", japanese: "ja", japones: "ja", "japonés": "ja"
        kor: "ko", ko: "ko", korean: "ko", coreano: "ko"
        rus: "ru", ru: "ru", russian: "ru", ruso: "ru"
        ara: "ar", ar: "ar", arabic: "ar", arabe: "ar", "árabe": "ar"
        tur: "tr", tr: "tr", turkish: "tr", turco: "tr", "türkçe": "tr"
        pol: "pl", pl: "pl", polish: "pl", polaco: "pl", polski: "pl"
        dut: "nl", nld: "nl", nl: "nl", dutch: "nl", nederlands: "nl", holandes: "nl", "holandés": "nl"
        swe: "sv", sv: "sv", swedish: "sv", sueco: "sv"
        nor: "no", nob: "no", nno: "no", no: "no", norwegian: "no", noruego: "no"
        dan: "da", da: "da", danish: "da", danes: "da", "danés": "da"
        fin: "fi", fi: "fi", finnish: "fi", finlandes: "fi", "finlandés": "fi"
        gre: "el", ell: "el", el: "el", greek: "el", griego: "el"
        cze: "cs", ces: "cs", cs: "cs", czech: "cs", checo: "cs"
        hun: "hu", hu: "hu", hungarian: "hu", hungaro: "hu", "húngaro": "hu"
        rum: "ro", ron: "ro", ro: "ro", romanian: "ro", rumano: "ro"
        tha: "th", th: "th", thai: "th", tailandes: "th", "tailandés": "th"
        vie: "vi", vi: "vi", vietnamese: "vi", vietnamita: "vi"
        ind: "id", id: "id", "in": "id", indonesian: "id", indonesio: "id"
        may: "ms", msa: "ms", ms: "ms", malay: "ms", malayo: "ms"
        hin: "hi", hi: "hi", hindi: "hi"
        ukr: "uk", uk: "uk", ukrainian: "uk", ucraniano: "uk"
        bul: "bg", bg: "bg", bulgarian: "bg", bulgaro: "bg", "búlgaro": "bg"
        hrv: "hr", hr: "hr", hbs: "hr", croatian: "hr", croata: "hr"
        srp: "sr", sr: "sr", serbian: "sr", serbio: "sr"
        "sr-me": "sr-me", cnr: "sr-me", montenegrin: "sr-me"
        slo: "sk", slk: "sk", sk: "sk", slovak: "sk", eslovaco: "sk"
        slv: "sl", sl: "sl", slovenian: "sl", esloveno: "sl"
        heb: "he", he: "he", iw: "he", hebrew: "he", hebreo: "he"
        per: "fa", fas: "fa", fa: "fa", persian: "fa", persa: "fa"
        cat: "ca", ca: "ca", catalan: "ca", "catalán": "ca"
        baq: "eu", eus: "eu", eu: "eu", basque: "eu", euskera: "eu"
        glg: "gl", gl: "gl", galician: "gl", gallego: "gl"
        tam: "ta", ta: "ta", tamil: "ta"
        tel: "te", te: "te", telugu: "te"
        ben: "bn", bn: "bn", bengali: "bn"
        mar: "mr", mr: "mr", marathi: "mr"
        urd: "ur", ur: "ur", urdu: "ur"
        und: "und", unknown: "und", desconocida: "und", desconocido: "und"
    }
    return m.langAliasMap
end function

function Lang_Norm(raw as string) as string
    s = LCase(raw.Trim())
    if s = "" then return "und"
    if m.langNormCache = invalid then m.langNormCache = {}
    if m.langNormCache.DoesExist(s) then return m.langNormCache[s]
    c = s.Replace("_", "-")
    if c = "system" or c = "device" or c = "none" or c = "off" or c = "original" or c = "forced" or c = "default"
        return c
    end if
    aliases = Lang_AliasMap()
    res = ""
    if aliases.DoesExist(c)
        res = aliases[c]
    else if Instr(1, c, "-") > 0
        parts = c.Split("-")
        primary = parts[0].Trim()
        base = primary
        if aliases.DoesExist(primary) then base = Lang_Base(aliases[primary])
        if parts.Count() > 1
            reg = parts[1].Trim()
            cand = base + "-" + reg
            if aliases.DoesExist(cand)
                res = aliases[cand]
            else if base = "es" and (reg = "419" or reg = "la" or reg = "mx" or reg = "ar" or reg = "cl" or reg = "co" or reg = "pe")
                res = "es-419"
            else if base = "zh" and (reg = "cn" or reg = "hans")
                res = "zh-cn"
            else if base = "zh" and (reg = "tw" or reg = "hk" or reg = "hant")
                res = "zh-tw"
            else
                res = base
            end if
        else
            res = base
        end if
    else
        res = c
    end if
    if res = "" then res = "und"
    if m.langNormCache.Count() > 512 then m.langNormCache = {}
    m.langNormCache[s] = res
    return res
end function

function Lang_Variant(rawLang as string, labelHint = "" as string, extraHint = "" as string) as string
    base = Lang_Norm(rawLang)
    combined = LCase(labelHint + " " + extraHint)
    if combined.Trim() <> ""
        if m.langVarRe = invalid
            m.langVarRe = {
                ptBr: CreateObject("roRegex", "\b(pt-?br|pob|bra[zs]il(ian)?|dublado)\b", "i")
                ptPt: CreateObject("roRegex", "\b(pt-?pt|portugal|iberian|european\s*portuguese)\b", "i")
                es419: CreateObject("roRegex", "\b(es-?419|es-?la|latam|latin[oa]?|mexico|argentin)\b", "i")
                esEs: CreateObject("roRegex", "\b(es-?es|castellano|spain|españa)\b", "i")
                zhCn: CreateObject("roRegex", "\b(simplified|zh-?cn|zh-?hans|chs)\b", "i")
                zhTw: CreateObject("roRegex", "\b(traditional|zh-?tw|zh-?hk|zh-?hant|cht)\b", "i")
                zhCa: CreateObject("roRegex", "\b(cantonese|yue|zh-?ca)\b", "i")
                nPt: CreateObject("roRegex", "\b(portuguese|português|portugues)\b", "i")
                nEs: CreateObject("roRegex", "\b(spanish|español|espanol)\b", "i")
                nEn: CreateObject("roRegex", "\b(english|inglés|ingles)\b", "i")
                nFr: CreateObject("roRegex", "\b(french|français|francés|frances)\b", "i")
                nDe: CreateObject("roRegex", "\b(german|deutsch|alemán|aleman)\b", "i")
                nIt: CreateObject("roRegex", "\b(italian|italiano)\b", "i")
                nJa: CreateObject("roRegex", "\b(japanese|japonés|japones)\b", "i")
                nKo: CreateObject("roRegex", "\b(korean|coreano)\b", "i")
            }
        end if
        re = m.langVarRe
        if base = "pt" or base = "und"
            if re.ptBr.IsMatch(combined) then return "pt-br"
            if re.ptPt.IsMatch(combined) then return "pt-pt"
        end if
        if base = "es" or base = "und"
            if re.es419.IsMatch(combined) then return "es-419"
            if re.esEs.IsMatch(combined) then return "es-es"
        end if
        if base = "zh" or base = "und"
            if re.zhCn.IsMatch(combined) then return "zh-cn"
            if re.zhTw.IsMatch(combined) then return "zh-tw"
            if re.zhCa.IsMatch(combined) then return "zh-ca"
        end if
        if base = "und"
            if re.nPt.IsMatch(combined) then return "pt"
            if re.nEs.IsMatch(combined) then return "es"
            if re.nEn.IsMatch(combined) then return "en"
            if re.nFr.IsMatch(combined) then return "fr"
            if re.nDe.IsMatch(combined) then return "de"
            if re.nIt.IsMatch(combined) then return "it"
            if re.nJa.IsMatch(combined) then return "ja"
            if re.nKo.IsMatch(combined) then return "ko"
        end if
    end if
    return base
end function

function Lang_Base(code as string) as string
    c = LCase(code.Trim()).Replace("_", "-")
    if c = "" then return ""
    dash = Instr(1, c, "-")
    if dash > 0 then return Left(c, dash - 1)
    return c
end function

function Lang_Name(code as string) as string
    norm = Lang_Norm(code)
    if norm = "" or norm = "und" then return L("Desconocido")
    names = {
        es: L("Español"), "es-419": L("Español (Latino)"), "es-es": L("Español (España)")
        en: L("Inglés")
        pt: L("Portugués"), "pt-br": L("Portugués (Brasil)"), "pt-pt": L("Portugués (Portugal)")
        fr: L("Francés"), it: L("Italiano"), de: L("Alemán")
        ja: L("Japonés"), ko: L("Coreano")
        zh: L("Chino"), "zh-cn": L("Chino (Simplificado)"), "zh-tw": L("Chino (Tradicional)"), "zh-ca": L("Chino (Cantonés)")
        ru: L("Ruso"), ar: L("Árabe"), hi: "Hindi", tr: L("Turco"), pl: L("Polaco")
        nl: L("Neerlandés"), sv: L("Sueco"), no: L("Noruego"), da: L("Danés"), fi: L("Finlandés")
        el: L("Griego"), cs: L("Checo"), hu: L("Húngaro"), ro: L("Rumano")
        th: L("Tailandés"), vi: L("Vietnamita"), id: L("Indonesio"), ms: L("Malayo"), uk: L("Ucraniano")
        bg: L("Búlgaro"), hr: L("Croata"), sr: L("Serbio"), "sr-me": L("Serbio (Montenegro)")
        sk: L("Eslovaco"), sl: L("Esloveno"), he: L("Hebreo"), fa: L("Persa")
        ca: L("Catalán"), eu: L("Euskera"), gl: L("Gallego")
    }
    if names.DoesExist(norm) then return names[norm]
    known = Lang_CatalogName(norm)
    if known = "" then known = Lang_CatalogName(Lang_Base(norm))
    if known <> "" then return known
    return UCase(code)
end function

function Lang_Rank(code as string) as integer
    c = Lang_Norm(code)
    if c = "es-419" or c = "es" or c = "es-es" then return 0
    if c = "en" then return 1
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
    c = Lang_Base(Lang_Norm(code))
    if c = "" or c = "system" or c = "device" or c = "none" or c = "off" or c = "original" or c = "forced" or c = "und" then return c
    map = { es: "spa", en: "eng", pt: "por", fr: "fre", it: "ita", de: "ger", ja: "jpn", ko: "kor", zh: "chi", ru: "rus", ar: "ara", hi: "hin", tr: "tur", pl: "pol", nl: "dut" }
    if map.DoesExist(c) then return map[c]
    return c
end function

function Lang_Device() as string
    locale = CreateObject("roDeviceInfo").GetCurrentLocale()
    return LCase(Left(Str_Of(locale), 2))
end function

function Lang_UiCode() as string
    if m.global <> invalid and m.global.hasField("uiLang")
        ui = LCase(Str_Of(m.global.uiLang).Trim())
        if ui <> "" and ui <> "auto" then return Lang_Norm(ui)
    end if
    return Lang_Norm(Lang_Device())
end function

function Lang_Resolve(code as string, original as string) as string
    c = LCase(code.Trim())
    if c = "system" or c = "device" then return Lang_Norm(Lang_Device())
    if c = "original" then return Lang_Norm(original)
    if c = "none" or c = "default" or c = "off" or c = "forced" or c = "" then return ""
    res = Lang_Norm(c)
    if res = "und" then return ""
    return res
end function

function Lang_MatchScore(trackLang as string, wanted as string) as integer
    a = Lang_Norm(trackLang)
    b = Lang_Norm(wanted)
    if a = "" or a = "und" or b = "" or b = "und" or b = "none" or b = "off" then return 0
    if a = b then return 3
    ba = Lang_Base(a)
    bb = Lang_Base(b)
    if ba <> bb then return 0
    if b = bb then return 2
    if a = ba then return 1
    return 0
end function

function Lang_Matches(trackLang as string, wanted as string) as boolean
    return Lang_MatchScore(trackLang, wanted) > 0
end function

function Sub_DetectFormat(rawFmt as string, url as string) as string
    f = UCase(rawFmt.Trim())
    if f = "SUBRIP" or f = "SRT" then return "SRT"
    if f = "WEBVTT" or f = "VTT" then return "VTT"
    if f = "ASS" or f = "SSA" then return UCase(f)
    low = LCase(url)
    q = Instr(1, low, "?")
    if q > 0 then low = Left(low, q - 1)
    if Right(low, 4) = ".vtt" then return "VTT"
    if Right(low, 4) = ".srt" then return "SRT"
    if Right(low, 4) = ".ass" then return "ASS"
    if Right(low, 4) = ".ssa" then return "SSA"
    return ""
end function

function Sub_DetectSdh(text as string) as boolean
    if text = "" then return false
    if m.subSdhRe = invalid then m.subSdhRe = CreateObject("roRegex", "(\b(sdh|sordos|closed\s*captions?)\b|[\[\(]\s*(cc|hi|sdh)\s*[\)\]]|hearing\s*imp)", "i")
    return m.subSdhRe.IsMatch(text)
end function

function Sub_DetectForced(text as string) as boolean
    if text = "" then return false
    if m.subForcedRe = invalid then m.subForcedRe = CreateObject("roRegex", "(\b(forced|forzado|forzados)\b|[\[\(]\s*forced\s*[\)\]])", "i")
    return m.subForcedRe.IsMatch(text)
end function

function Sub_UrlKey(url as string) as string
    u = url.Trim()
    h = Instr(1, u, "#")
    if h > 0 then u = Left(u, h - 1)
    return u
end function

function Sub_FormatLabel(item as object) as string
    parts = [Lang_Name(Str_Of(item.langKey))]
    prov = Str_Of(item.provider)
    rel = Str_Of(item.release)
    if rel <> ""
        parts.Push(rel)
    else if prov <> ""
        parts.Push(prov)
    end if
    tags = []
    if item.forced = true then tags.Push(L("Forzados"))
    if item.sdh = true then tags.Push("SDH")
    fmt = Str_Of(item.format)
    if fmt <> "" then tags.Push(fmt)
    if tags.Count() > 0 then parts.Push(tags.Join(" · "))
    return parts.Join("  ·  ")
end function

function Sub_NormalizeTrack(raw as object, defaultProvider as string, sourceType = "addon" as string) as dynamic
    if type(raw) <> "roAssociativeArray" then return invalid
    url = Str_Of(raw.url).Trim()
    if url = "" then url = Str_Of(raw.TrackName).Trim()
    if url = "" then return invalid
    rawLang = Str_Of(raw.lang)
    if rawLang = "" then rawLang = Str_Of(raw.language)
    if rawLang = "" then rawLang = Str_Of(raw.Language)
    if rawLang = "" then rawLang = Str_Of(raw.SubLanguageID)
    title = Str_Of(raw.title)
    if title = "" then title = Str_Of(raw.name)
    if title = "" then title = Str_Of(raw.release)
    if title = "" then title = Str_Of(raw.SubFileName)
    if title = "" then title = Str_Of(raw.DisplayTitle)
    if title = "" then title = Str_Of(raw.Description)
    prov = Str_Of(raw.provider)
    if prov = "" then prov = defaultProvider
    hintText = [title, Str_Of(raw.id), url].Join(" ")
    langKey = Lang_Variant(rawLang, title, url)
    langLabel = Lang_Name(langKey)
    forced = Bool_Of(raw.forced, false) or Bool_Of(raw.IsForced, false) or Sub_DetectForced(hintText)
    sdh = Bool_Of(raw.sdh, false) or Bool_Of(raw.hearingImpaired, false) or Bool_Of(raw.IsHearingImpaired, false) or Sub_DetectSdh(hintText)
    fmt = Sub_DetectFormat(Str_Of(raw.format) + Str_Of(raw.SubFormat), url)
    release = title.Trim()
    if LCase(release) = LCase(langLabel) or LCase(release) = LCase(rawLang) then release = ""
    if Len(release) > 48 then release = Left(release, 45).Trim() + "..."
    sid = Str_Of(raw.id)
    if sid = "" then sid = sourceType + "|" + prov + "|" + Sub_UrlKey(url)
    item = {
        id: sid
        url: url
        lang: rawLang
        langKey: langKey
        langLabel: langLabel
        provider: prov
        sourceType: sourceType
        forced: forced
        sdh: sdh
        format: fmt
        release: release
    }
    item.label = Sub_FormatLabel(item)
    return item
end function

sub Sub_MergeInto(target as object, incoming as object)
    if type(target) <> "roAssociativeArray" or type(incoming) <> "roAssociativeArray" then return
    tk = Str_Of(target.langKey)
    ik = Str_Of(incoming.langKey)
    if ik <> "" and ik <> "und"
        if tk = "" or tk = "und" or (tk = Lang_Base(tk) and ik <> Lang_Base(ik) and Lang_Base(ik) = tk)
            target.langKey = ik
            target.langLabel = incoming.langLabel
            if Str_Of(incoming.lang) <> "" then target.lang = incoming.lang
        end if
    end if
    target.forced = Bool_Of(target.forced, false) or Bool_Of(incoming.forced, false)
    target.sdh = Bool_Of(target.sdh, false) or Bool_Of(incoming.sdh, false)
    if Str_Of(target.format) = "" and Str_Of(incoming.format) <> "" then target.format = incoming.format
    if Str_Of(target.release) = "" and Str_Of(incoming.release) <> "" then target.release = incoming.release
    if Str_Of(target.provider) = "" and Str_Of(incoming.provider) <> "" then target.provider = incoming.provider
    target.label = Sub_FormatLabel(target)
end sub

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

sub Dbg_Log(text as string)
    path = "tmp:/nuvio_debug.log"
    fs = CreateObject("roFileSystem")
    st = fs.Stat(path)
    if st <> invalid and st.size <> invalid and st.size > 262144
        old = ReadAsciiFile(path)
        WriteAsciiFile(path, Right(old, 131072))
    end if
    d = CreateObject("roDateTime")
    d.ToLocalTime()
    line = Right("0" + d.GetHours().ToStr(), 2) + ":" + Right("0" + d.GetMinutes().ToStr(), 2) + ":" + Right("0" + d.GetSeconds().ToStr(), 2) + " " + text + Chr(10)
    ba = CreateObject("roByteArray")
    ba.FromAsciiString(line)
    if fs.Exists(path) then ba.AppendFile(path) else ba.WriteFile(path)
end sub
