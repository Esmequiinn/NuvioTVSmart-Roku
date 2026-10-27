function Ui_Ink(color as string) as string
    hex = color
    if LCase(Left(hex, 2)) = "0x" then hex = Mid(hex, 3)
    if Len(hex) < 6 then return "0xFFFFFFFF"
    r = Val(Mid(hex, 1, 2), 16)
    g = Val(Mid(hex, 3, 2), 16)
    b = Val(Mid(hex, 5, 2), 16)
    light = (r * 299 + g * 587 + b * 114) / 1000
    if light > 170 then return "0x0C0C0FFF"
    return "0xFFFFFFFF"
end function
