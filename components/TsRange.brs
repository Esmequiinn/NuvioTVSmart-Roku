function Ts_Pid(b as object, o as integer) as integer
    return (b[o + 1] and 31) * 256 + b[o + 2]
end function

function Ts_Unit(b as object, o as integer) as boolean
    return (b[o + 1] and 64) <> 0
end function

function Ts_Payload(b as object, o as integer) as integer
    control = (b[o + 3] and 48) \ 16
    if (control and 1) = 0 then return -1
    p = o + 4
    if (control and 2) <> 0 then p = p + 1 + b[o + 4]
    if p >= o + 188 then return -1
    return p
end function

function Ts_Section(b as object, o as integer) as integer
    if not Ts_Unit(b, o) then return -1
    p = Ts_Payload(b, o)
    if p < 0 then return -1
    s = p + 1 + b[p]
    if s + 12 >= o + 188 then return -1
    return s
end function

function Ts_Audio(kind as integer, tags as object) as dynamic
    if kind = 15 or kind = 17 then return { codec: "AAC", family: "aac" }
    if kind = 3 or kind = 4 then return { codec: "MP3", family: "mp3" }
    if kind = 129 then return { codec: "Dolby Digital", family: "ac3" }
    if kind = 135 then return { codec: "Dolby Digital Plus", family: "eac3" }
    if kind = 130 or kind = 133 or kind = 138 then return { codec: "DTS", family: "dts" }
    if kind = 131 or kind = 132 then return { codec: "TrueHD", family: "truehd" }
    if kind = 6
        if tags.DoesExist("106") then return { codec: "Dolby Digital", family: "ac3" }
        if tags.DoesExist("122") then return { codec: "Dolby Digital Plus", family: "eac3" }
        if tags.DoesExist("123") then return { codec: "DTS", family: "dts" }
    end if
    return invalid
end function

function Ts_Program(b as object, start as integer) as dynamic
    n = b.Count() - 188
    pmt = -1
    o = start
    while o <= n
        if b[o] = 71
            pid = Ts_Pid(b, o)
            s = Ts_Section(b, o)
            if s >= 0 and pid = 0 and pmt < 0 and b[s] = 0
                e = s + 8
                last = s + 3 + (b[s + 1] and 15) * 256 + b[s + 2] - 4
                while e + 4 <= last and e + 4 <= o + 188
                    if b[e] * 256 + b[e + 1] <> 0
                        pmt = (b[e + 2] and 31) * 256 + b[e + 3]
                        exit while
                    end if
                    e = e + 4
                end while
            else if s >= 0 and pid = pmt and b[s] = 2
                last = s + 3 + (b[s + 1] and 15) * 256 + b[s + 2] - 4
                if last <= o + 188
                    out = { pmtPid: pmt, videoPid: -1, videoKind: 0, audio: [] }
                    e = s + 12 + (b[s + 10] and 15) * 256 + b[s + 11]
                    while e + 5 <= last
                        kind = b[e]
                        epid = (b[e + 1] and 31) * 256 + b[e + 2]
                        size = (b[e + 3] and 15) * 256 + b[e + 4]
                        if (kind = 27 or kind = 36 or kind = 2) and out.videoPid < 0
                            out.videoPid = epid
                            out.videoKind = kind
                        end if
                        tags = {}
                        lang = ""
                        c = e + 5
                        limit = c + size
                        while c + 2 <= limit
                            tag = b[c]
                            length = b[c + 1]
                            tags[tag.ToStr()] = true
                            if tag = 10 and length >= 3 then lang = LCase(Chr(b[c + 2]) + Chr(b[c + 3]) + Chr(b[c + 4]))
                            c = c + 2 + length
                        end while
                        info = Ts_Audio(kind, tags)
                        if info <> invalid then out.audio.Push({ pid: epid, lang: lang, codec: info.codec, family: info.family })
                        e = e + 5 + size
                    end while
                    return out
                end if
            end if
        end if
        o = o + 188
    end while
    return invalid
end function

function Ts_Pts(b as object, o as integer, pid as integer) as double
    if b[o] <> 71 or not Ts_Unit(b, o) or Ts_Pid(b, o) <> pid then return -1
    p = Ts_Payload(b, o)
    if p < 0 or p + 14 > o + 188 then return -1
    if b[p] <> 0 or b[p + 1] <> 0 or b[p + 2] <> 1 then return -1
    if (b[p + 7] and 128) = 0 then return -1
    v = CDbl((b[p + 9] and 14) \ 2) * 1073741824
    v = v + CDbl(b[p + 10]) * 4194304 + CDbl(b[p + 11] \ 2) * 32768 + b[p + 12] * 128 + (b[p + 13] \ 2)
    return v
end function

function Ts_Duration(head as object, headStart as integer, tail as object, pid as integer) as integer
    first = -1
    n = head.Count() - 188
    o = headStart
    while o <= n and first < 0
        first = Ts_Pts(head, o, pid)
        o = o + 188
    end while
    if first < 0 then return 0
    at = Hlsp_Sync(tail)
    if at < 0 then return 0
    last = -1
    n = tail.Count() - 188
    o = at
    while o <= n
        v = Ts_Pts(tail, o, pid)
        if v > last then last = v
        o = o + 188
    end while
    if last < 0 then return 0
    diff = last - first
    if diff < 0 then diff = diff + CDbl(65536) * 131072
    secs = Int(diff / 90000)
    if secs < 60 or secs > 21600 then return 0
    return secs
end function

function Ts_Inspect(url as string, headers as dynamic, size as longinteger) as dynamic
    headLen = 188 * 3000
    tailLen = 188 * 1500
    if size < headLen * 2 then return invalid
    head = Ts_Fetch(url, headers, 0, headLen)
    if head = invalid then return invalid
    start = Hlsp_Sync(head)
    if start < 0 then return invalid
    program = Ts_Program(head, start)
    if program = invalid or program.videoPid < 0 then return invalid
    tail = Ts_Fetch(url, headers, size - tailLen, tailLen)
    duration = 0
    if tail <> invalid then duration = Ts_Duration(head, start, tail, program.videoPid)
    marks = []
    if duration > 0
        try
            marks = Ts_Marks(url, headers, size, start, program.videoPid, Ts_FirstPts(head, start, program.videoPid), duration)
        catch e
            marks = []
        end try
    end if
    return { start: start, duration: duration, marks: marks, pmtPid: program.pmtPid, videoPid: program.videoPid, videoKind: program.videoKind, audio: program.audio, pat: Ts_Packet(head, start, 0), pmt: Ts_Packet(head, start, program.pmtPid) }
end function

function Ts_FirstPts(b as object, start as integer, pid as integer) as double
    n = b.Count() - 188
    o = start
    while o <= n
        v = Ts_Pts(b, o, pid)
        if v >= 0 then return v
        o = o + 188
    end while
    return -1
end function

function Ts_Marks(url as string, headers as dynamic, size as longinteger, start as integer, pid as integer, first as double, duration as integer) as object
    marks = []
    if first < 0 then return marks
    count = 8
    sample = 188 * 200
    usable = size - start
    gap = usable \ (count + 1)
    wrap = CDbl(65536) * 131072
    clock = CreateObject("roTimespan")
    for k = 1 to count
        if clock.TotalMilliseconds() > 7000 then exit for
        off = start + gap * k
        off = off - ((off - start) mod 188)
        b = invalid
        try
            b = Ts_Fetch(url, headers, off, sample)
        catch e
            b = invalid
        end try
        if b = invalid then exit for
        at = Hlsp_Sync(b)
        if at >= 0
            v = Ts_FirstPts(b, at, pid)
            if v >= 0
                diff = v - first
                if diff < 0 then diff = diff + wrap
                secs = diff / 90000
                if secs > 0 and secs < duration and (marks.Count() = 0 or secs > marks[marks.Count() - 1].s) then marks.Push({ o: CDbl(off + at), s: secs })
            end if
        end if
    end for
    return marks
end function

function Ts_TimeAt(h as object, offset as double) as double
    start = CDbl(ToInt(h.start, 0))
    size = CDbl(h.size)
    duration = CDbl(ToInt(h.duration, 0))
    prevO = start
    prevS = 0.0
    marks = h.marks
    if type(marks) = "roArray"
        for each mk in marks
            mo = CDbl(mk.o)
            ms = CDbl(mk.s)
            if offset <= mo
                if mo <= prevO then return ms
                return prevS + (ms - prevS) * (offset - prevO) / (mo - prevO)
            end if
            prevO = mo
            prevS = ms
        end for
    end if
    if size <= prevO then return duration
    v = prevS + (duration - prevS) * (offset - prevO) / (size - prevO)
    if v > duration then v = duration
    return v
end function

function Ts_Packet(b as object, start as integer, pid as integer) as string
    n = b.Count() - 188
    o = start
    while o <= n
        if b[o] = 71 and Ts_Pid(b, o) = pid and Ts_Unit(b, o)
            one = CreateObject("roByteArray")
            for i = 0 to 187
                one.Push(b[o + i])
            end for
            return one.ToHexString()
        end if
        o = o + 188
    end while
    return ""
end function

function Ts_KeyStart(b as object, o as integer, pid as integer, kind = 27 as integer) as boolean
    if not Ts_VideoStart(b, o, pid) then return false
    if kind <> 27 and kind <> 36 and kind <> 2
        return (b[o + 3] and 32) <> 0 and b[o + 4] > 0 and (b[o + 5] and 64) <> 0
    end if
    n = b.Count()
    pk = o
    first = true
    zeros = 0
    hops = 0
    while pk + 188 <= n and hops < 24
        if b[pk] <> 71 then return false
        if Ts_Pid(b, pk) = pid
            if not first and Ts_Unit(b, pk) then return false
            p = Ts_Payload(b, pk)
            if p >= 0
                if first
                    if p + 9 > pk + 188 or b[p] <> 0 or b[p + 1] <> 0 or b[p + 2] <> 1 then return false
                    p = p + 9 + b[p + 8]
                    first = false
                end if
                last = pk + 188
                while p < last
                    v = b[p]
                    if zeros >= 2 and v = 1
                        if p + 1 < last
                            nb = b[p + 1]
                            if kind = 36
                                t = (nb \ 2) and 63
                                if t >= 16 and t <= 21 then return true
                                if t <= 9 then return false
                            else if kind = 2
                                if nb = 179 then return true
                                if nb = 0 then return false
                            else
                                t = nb and 31
                                if t = 5 then return true
                                if t = 1 then return false
                            end if
                        end if
                        zeros = 0
                    else if v = 0
                        zeros = zeros + 1
                    else
                        zeros = 0
                    end if
                    p = p + 1
                end while
            end if
            hops = hops + 1
        end if
        pk = pk + 188
    end while
    return false
end function

function Ts_Fetch(url as string, headers as dynamic, offset as longinteger, length as longinteger) as dynamic
    got = Hlsp_File(url, headers, "bytes=" + Str_Any(offset) + "-" + Str_Any(offset + length - 1), 12000)
    if got.file = "" then return invalid
    bytes = CreateObject("roByteArray")
    ok = got.code = 206 and bytes.ReadFile(got.file)
    DeleteFile(got.file)
    if not ok then return invalid
    return bytes
end function

function Ts_Playlist(h as object, base as string) as string
    size = h.size
    start = ToInt(h.start, 0)
    duration = ToInt(h.duration, 0)
    usable = size - start
    perSec = usable / duration
    seg = Int(perSec * 6 / 188) * 188
    if seg < 188 * 5000 then seg = 188 * 5000
    if seg > 188 * 20000 then seg = 188 * 20000
    nl = chr(10)
    out = []
    longest = 1
    offset = start + 0&
    while offset < size
        length = seg
        if offset + length > size then length = size - offset
        part = Ts_TimeAt(h, CDbl(offset + length)) - Ts_TimeAt(h, CDbl(offset))
        if part < 0.1 then part = 0.1
        if part > longest then longest = part
        out.Push("#EXTINF:" + Ts_Secs(part) + ",")
        out.Push(base + "&o=" + Str_Any(offset) + "&n=" + Str_Any(length))
        offset = offset + length
    end while
    headLines = ["#EXTM3U", "#EXT-X-VERSION:3", "#EXT-X-PLAYLIST-TYPE:VOD", "#EXT-X-TARGETDURATION:" + (Int(longest) + 1).ToStr(), "#EXT-X-MEDIA-SEQUENCE:0"]
    headLines.Append(out)
    headLines.Push("#EXT-X-ENDLIST")
    return headLines.Join(nl) + nl
end function

function Ts_Long(text as string) as longinteger
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

function Ts_Secs(v as float) as string
    ms = Int(v * 1000 + 0.5)
    whole = Int(ms / 1000)
    frac = (ms - whole * 1000).ToStr()
    while Len(frac) < 3
        frac = "0" + frac
    end while
    return whole.ToStr() + "." + frac
end function

function Ts_VideoStart(b as object, o as integer, pid as integer) as boolean
    return b[o] = 71 and Ts_Unit(b, o) and Ts_Pid(b, o) = pid
end function

function Ts_Piece(h as object, offset as longinteger, length as longinteger) as dynamic
    size = h.size
    lastEnd = -1&
    if m.tsLastEnd <> invalid then lastEnd = m.tsLastEnd
    servedEnd = -1&
    if m.tsServedEnd <> invalid then servedEnd = m.tsServedEnd
    jump = offset > ToInt(h.start, 0) and offset <> lastEnd
    margin = 188 * 6000
    if jump then margin = 188 * 14000
    want = length + margin
    if offset + want > size then want = size - offset
    clock = CreateObject("roTimespan")
    got = Hlsp_File(h.url, h.headers, "bytes=" + Str_Any(offset) + "-" + Str_Any(offset + want - 1), 60000)
    Dbg_Log("tsr fetch o=" + Str_Any(offset) + " want=" + Str_Any(want) + " code=" + ToInt(got.code, 0).ToStr() + " ms=" + clock.TotalMilliseconds().ToStr())
    if got.file = "" then return invalid
    if got.code <> 206
        DeleteFile(got.file)
        return invalid
    end if
    full = CreateObject("roByteArray")
    if not full.ReadFile(got.file)
        DeleteFile(got.file)
        return invalid
    end if
    total = full.Count() - (full.Count() mod 188)
    video = ToInt(h.videoPid, -1)
    keep = ToInt(h.keep, -1)
    begin = 0
    skip = 0
    found = -2
    if offset > ToInt(h.start, 0) and not jump and servedEnd > offset then skip = Int(CDbl(servedEnd - offset))
    if skip >= total
        DeleteFile(got.file)
        m.tsLastEnd = offset + length
        body = CreateObject("roByteArray")
        if Str_Of(h.pat) <> "" and Str_Of(h.pmt) <> "" then body.FromHexString(Str_Of(h.pat) + Str_Of(h.pmt))
        return body
    end if
    if skip > 0
        begin = skip - (skip mod 188)
        while begin < total and not Ts_VideoStart(full, begin, video)
            begin = begin + 188
        end while
        if begin >= total then begin = skip - (skip mod 188)
    else if offset > ToInt(h.start, 0)
        found = -1
        if jump
            probe = 0
            while probe < total and found < 0
                if Ts_KeyStart(full, probe, video, ToInt(h.videoKind, 27)) then found = probe
                probe = probe + 188
            end while
        end if
        if found >= 0
            begin = found
        else
            while begin < total and not Ts_VideoStart(full, begin, video)
                begin = begin + 188
            end while
            if begin >= total then begin = 0
        end if
    end if
    m.tsLastEnd = offset + length
    cut = length - (length mod 188)
    if cut <= begin then cut = begin + 188
    if offset + length >= size
        cut = total
    else
        while cut < total and not Ts_VideoStart(full, cut, video)
            cut = cut + 188
        end while
    end if
    m.tsServedEnd = offset + cut
    tails = []
    o = cut
    while o < total and keep >= 0
        if full[o] = 71 and Ts_Pid(full, o) = keep
            if Ts_Unit(full, o) then exit while
            tails.Push(o)
        end if
        o = o + 188
    end while
    full = invalid
    body = CreateObject("roByteArray")
    if offset > ToInt(h.start, 0) and Str_Of(h.pat) <> "" and Str_Of(h.pmt) <> ""
        body.FromHexString(Str_Of(h.pat) + Str_Of(h.pmt))
    end if
    if cut > begin
        chunk = CreateObject("roByteArray")
        chunk.ReadFile(got.file, begin, cut - begin)
        body.Append(chunk)
    end if
    one = CreateObject("roByteArray")
    for each t in tails
        one.ReadFile(got.file, t, 188)
        body.Append(one)
    end for
    DeleteFile(got.file)
    Ts_KeepAudio(body, h)
    Dbg_Log("tsr o=" + Str_Any(offset) + " n=" + Str_Any(length) + " jump=" + jump.ToStr() + " key=" + found.ToStr() + " skip=" + skip.ToStr() + " begin=" + begin.ToStr() + " cut=" + cut.ToStr() + " got=" + total.ToStr() + " out=" + body.Count().ToStr())
    return body
end function

sub Ts_KeepAudio(b as object, h as object)
    drop = h.drop
    if type(drop) <> "roArray" or drop.Count() = 0 then return
    gone = {}
    for each pid in drop
        gone[ToInt(pid, -1).ToStr()] = true
    end for
    pmt = ToInt(h.pmtPid, -1)
    n = b.Count() - 188
    o = 0
    while o <= n
        if b[o] = 71
            pid = Ts_Pid(b, o)
            if pid = pmt
                Ts_RewritePmt(b, o, gone)
            else if gone.DoesExist(pid.ToStr())
                b[o + 1] = (b[o + 1] and 224) + 31
                b[o + 2] = 255
            end if
        end if
        o = o + 188
    end while
end sub

sub Ts_RewritePmt(b as object, o as integer, gone as object)
    s = Ts_Section(b, o)
    if s < 0 or b[s] <> 2 then return
    length = (b[s + 1] and 15) * 256 + b[s + 2]
    last = s + 3 + length - 4
    if last + 4 > o + 188 then return
    e = s + 12 + (b[s + 10] and 15) * 256 + b[s + 11]
    keepBytes = []
    removed = 0
    while e + 5 <= last
        epid = (b[e + 1] and 31) * 256 + b[e + 2]
        size = 5 + (b[e + 3] and 15) * 256 + b[e + 4]
        if gone.DoesExist(epid.ToStr())
            removed = removed + size
        else
            for i = 0 to size - 1
                keepBytes.Push(b[e + i])
            end for
        end if
        e = e + size
    end while
    if removed = 0 then return
    w = s + 12 + (b[s + 10] and 15) * 256 + b[s + 11]
    for each v in keepBytes
        b[w] = v
        w = w + 1
    end for
    length = length - removed
    b[s + 1] = (b[s + 1] and 240) + (length \ 256)
    b[s + 2] = length mod 256
    crc = Ts_Crc(b, s, w)
    b[w] = Ts_Byte(crc, 3)
    b[w + 1] = Ts_Byte(crc, 2)
    b[w + 2] = Ts_Byte(crc, 1)
    b[w + 3] = Ts_Byte(crc, 0)
    for i = w + 4 to o + 187
        b[i] = 255
    end for
end sub

function Ts_Xor(a as integer, b as integer) as integer
    return (a or b) and (not (a and b))
end function

function Ts_Shl8(v as integer) as integer
    out = (v and &h7FFFFF) * 256
    if (v and &h800000) <> 0 then out = out or &h80000000
    return out
end function

function Ts_Byte(v as integer, index as integer) as integer
    if index = 3
        top = (v and &h7F000000) \ &h1000000
        if v < 0 then top = top + 128
        return top
    end if
    if index = 2 then return (v and &hFF0000) \ &h10000
    if index = 1 then return (v and &hFF00) \ &h100
    return v and &hFF
end function

function Ts_CrcTable() as object
    if m.tsCrc <> invalid then return m.tsCrc
    table = []
    for i = 0 to 255
        table.Push(Ts_ShiftIn(i))
    end for
    m.tsCrc = table
    return table
end function

function Ts_ShiftIn(i as integer) as integer
    c = (i and 127) * &h1000000
    if i >= 128 then c = c or &h80000000
    for k = 1 to 8
        high = c < 0
        c = Ts_Shl1(c)
        if high then c = Ts_Xor(c, &h04C11DB7)
    end for
    return c
end function

function Ts_Shl1(v as integer) as integer
    out = (v and &h3FFFFFFF) * 2
    if (v and &h40000000) <> 0 then out = out or &h80000000
    return out
end function

function Ts_Crc(b as object, from as integer, upto as integer) as integer
    table = Ts_CrcTable()
    crc = &hFFFFFFFF
    for i = from to upto - 1
        idx = Ts_Xor(Ts_Byte(crc, 3), b[i])
        crc = Ts_Xor(Ts_Shl8(crc), table[idx])
    end for
    return crc
end function
