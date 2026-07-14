; ============================================================================
; JSON.ahk
; ----------------------------------------------------------------------------
; Minimal, dependency-free JSON parser/serializer for AutoHotkey v2.
; Used by Config.ahk to read/write NumpadOS's config.json.
;
; Conventions:
;   - JSON objects  -> AHK Map
;   - JSON arrays   -> AHK Array
;   - JSON strings  -> AHK String
;   - JSON numbers  -> AHK Integer/Float
;   - JSON true/false -> AHK 1/0
;   - JSON null     -> AHK "" (empty string sentinel)
;
; Public API:
;   JSON.Load(text)          -> Map/Array/primitive
;   JSON.Dump(value, pretty := true) -> String
; ============================================================================

class JSON
{
    ; ---- Public: parse a JSON string into AHK data structures ----
    static Load(text)
    {
        pos := 1
        JSON._SkipWs(text, &pos)
        value := JSON._ParseValue(text, &pos)
        JSON._SkipWs(text, &pos)
        return value
    }

    ; ---- Public: serialize AHK data structures into a JSON string ----
    static Dump(value, pretty := true)
    {
        return JSON._Write(value, pretty, 0)
    }

    ; ================= internal: parsing =================

    static _SkipWs(text, &pos)
    {
        len := StrLen(text)
        while (pos <= len)
        {
            c := SubStr(text, pos, 1)
            if (c = " " or c = "`t" or c = "`r" or c = "`n")
                pos++
            else
                break
        }
    }

    static _ParseValue(text, &pos)
    {
        JSON._SkipWs(text, &pos)
        c := SubStr(text, pos, 1)
        if (c = "{")
            return JSON._ParseObject(text, &pos)
        else if (c = "[")
            return JSON._ParseArray(text, &pos)
        else if (c = '"')
            return JSON._ParseString(text, &pos)
        else if (c = "t" or c = "f")
            return JSON._ParseBool(text, &pos)
        else if (c = "n")
            return JSON._ParseNull(text, &pos)
        else
            return JSON._ParseNumber(text, &pos)
    }

    static _ParseObject(text, &pos)
    {
        obj := Map()
        pos++ ; skip {
        JSON._SkipWs(text, &pos)
        if (SubStr(text, pos, 1) = "}")
        {
            pos++
            return obj
        }
        loop
        {
            JSON._SkipWs(text, &pos)
            key := JSON._ParseString(text, &pos)
            JSON._SkipWs(text, &pos)
            pos++ ; skip :
            val := JSON._ParseValue(text, &pos)
            obj[key] := val
            JSON._SkipWs(text, &pos)
            c := SubStr(text, pos, 1)
            if (c = ",")
            {
                pos++
                continue
            }
            else if (c = "}")
            {
                pos++
                break
            }
            else
                throw Error("JSON parse error: expected , or } at position " pos)
        }
        return obj
    }

    static _ParseArray(text, &pos)
    {
        arr := Array()
        pos++ ; skip [
        JSON._SkipWs(text, &pos)
        if (SubStr(text, pos, 1) = "]")
        {
            pos++
            return arr
        }
        loop
        {
            val := JSON._ParseValue(text, &pos)
            arr.Push(val)
            JSON._SkipWs(text, &pos)
            c := SubStr(text, pos, 1)
            if (c = ",")
            {
                pos++
                continue
            }
            else if (c = "]")
            {
                pos++
                break
            }
            else
                throw Error("JSON parse error: expected , or ] at position " pos)
        }
        return arr
    }

    static _ParseString(text, &pos)
    {
        ; assumes current char is opening quote
        if (SubStr(text, pos, 1) != '"')
            throw Error("JSON parse error: expected string at position " pos)
        pos++
        out := ""
        len := StrLen(text)
        while (pos <= len)
        {
            c := SubStr(text, pos, 1)
            if (c = '"')
            {
                pos++
                return out
            }
            else if (c = "\")
            {
                pos++
                esc := SubStr(text, pos, 1)
                switch esc
                {
                    case '"': out .= '"'
                    case "\": out .= "\"
                    case "/": out .= "/"
                    case "b": out .= Chr(8)
                    case "f": out .= Chr(12)
                    case "n": out .= "`n"
                    case "r": out .= "`r"
                    case "t": out .= "`t"
                    case "u":
                        hex := SubStr(text, pos + 1, 4)
                        out .= Chr("0x" . hex)
                        pos += 4
                    default:
                        out .= esc
                }
                pos++
            }
            else
            {
                out .= c
                pos++
            }
        }
        throw Error("JSON parse error: unterminated string")
    }

    static _ParseBool(text, &pos)
    {
        if (SubStr(text, pos, 4) = "true")
        {
            pos += 4
            return true
        }
        else if (SubStr(text, pos, 5) = "false")
        {
            pos += 5
            return false
        }
        throw Error("JSON parse error: invalid literal at position " pos)
    }

    static _ParseNull(text, &pos)
    {
        if (SubStr(text, pos, 4) = "null")
        {
            pos += 4
            return ""
        }
        throw Error("JSON parse error: invalid literal at position " pos)
    }

    static _ParseNumber(text, &pos)
    {
        start := pos
        len := StrLen(text)
        while (pos <= len)
        {
            c := SubStr(text, pos, 1)
            if InStr("-+0123456789.eE", c)
                pos++
            else
                break
        }
        numStr := SubStr(text, start, pos - start)
        if (numStr = "")
            throw Error("JSON parse error: invalid number at position " pos)
        return IsInteger(numStr) ? Integer(numStr) : Number(numStr)
    }

    ; ================= internal: serializing =================

    static _Write(value, pretty, depth)
    {
        indent := pretty ? "    " : ""
        nl := pretty ? "`n" : ""
        pad := ""
        loop depth
            pad .= indent
        childPad := pad . indent

        if IsObject(value)
        {
            if (value is Map)
            {
                if (value.Count = 0)
                    return "{}"
                parts := []
                for k, v in value
                    parts.Push(childPad . '"' . JSON._Escape(k) . '":' . (pretty ? " " : "") . JSON._Write(v, pretty, depth + 1))
                return "{" . nl . JSON._JoinParts(parts, "," . nl) . nl . pad . "}"
            }
            else if (value is Array)
            {
                if (value.Length = 0)
                    return "[]"
                parts := []
                for v in value
                    parts.Push(childPad . JSON._Write(v, pretty, depth + 1))
                return "[" . nl . JSON._JoinParts(parts, "," . nl) . nl . pad . "]"
            }
            else
                throw Error("JSON.Dump: unsupported object type")
        }
        else if (Type(value) = "Integer" || Type(value) = "Float")
        {
            return String(value)
        }
        else if (value == "")
        {
            ; empty string is used as our null sentinel
            return '""'
        }
        else
        {
            return '"' . JSON._Escape(value) . '"'
        }
    }

    static _JoinParts(parts, sep)
    {
        out := ""
        for i, p in parts
            out .= (i = 1 ? "" : sep) . p
        return out
    }

    static _Escape(str)
    {
        str := StrReplace(str, "\", "\\")
        str := StrReplace(str, '"', '\"')
        str := StrReplace(str, "`n", "\n")
        str := StrReplace(str, "`r", "\r")
        str := StrReplace(str, "`t", "\t")
        return str
    }
}
