; JSON mínimo para hablar con la API de Claude, porque AutoHotkey v2 no trae uno.
; Json.Dump serializa Map, Array, números y strings; un número leído de config.ini es String y sale entre comillas,
; así que convertilo con Integer() antes. Json.Load devuelve Map, Array, String y números, true/false como 1/0 y null como "".
class Json {
    static Escapes := Map('"', '"', "\", "\", "/", "/", "b", "`b", "f", "`f", "n", "`n", "r", "`r", "t", "`t")

    static Dump(v) {
        if v is Map {
            out := ""
            for k, x in v
                out .= (A_Index = 1 ? "" : ",") Json.Quote(String(k)) ":" Json.Dump(x)
            return "{" out "}"
        }
        if v is Array {
            out := ""
            for x in v
                out .= (A_Index = 1 ? "" : ",") Json.Dump(x)
            return "[" out "]"
        }
        if v is Number
            return String(v)
        return Json.Quote(v)
    }

    static Quote(s) {
        s := StrReplace(s, "\", "\\")
        s := StrReplace(s, '"', '\"')
        s := StrReplace(s, "`n", "\n")
        s := StrReplace(s, "`r", "\r")
        s := StrReplace(s, "`t", "\t")
        while RegExMatch(s, "[\x01-\x1F]", &m)
            s := StrReplace(s, m[0], Format("\u{:04X}", Ord(m[0])))
        return '"' s '"'
    }

    static Load(s) {
        pos := 1
        v := Json._Value(s, &pos)
        Json._Ws(s, &pos)
        if pos <= StrLen(s)
            throw ValueError("JSON con texto sobrante en la posición " pos)
        return v
    }

    static _Ws(s, &pos) {
        RegExMatch(s, "\G[ \t\r\n]*", &m, pos)
        pos += m.Len
    }

    static _Value(s, &pos) {
        Json._Ws(s, &pos)
        c := SubStr(s, pos, 1)
        if c = "{" {
            obj := Map()
            pos++
            Json._Ws(s, &pos)
            if SubStr(s, pos, 1) = "}" {
                pos++
                return obj
            }
            loop {
                Json._Ws(s, &pos)
                if SubStr(s, pos, 1) != '"'
                    throw ValueError("JSON: se esperaba una clave en la posición " pos)
                k := Json._String(s, &pos)
                Json._Ws(s, &pos)
                if SubStr(s, pos, 1) != ":"
                    throw ValueError("JSON: se esperaba ':' en la posición " pos)
                pos++
                obj[k] := Json._Value(s, &pos)
                Json._Ws(s, &pos)
                c := SubStr(s, pos++, 1)
                if c = "}"
                    return obj
                if c != ","
                    throw ValueError("JSON: se esperaba ',' o '}' en la posición " pos - 1)
            }
        }
        if c = "[" {
            arr := []
            pos++
            Json._Ws(s, &pos)
            if SubStr(s, pos, 1) = "]" {
                pos++
                return arr
            }
            loop {
                arr.Push(Json._Value(s, &pos))
                Json._Ws(s, &pos)
                c := SubStr(s, pos++, 1)
                if c = "]"
                    return arr
                if c != ","
                    throw ValueError("JSON: se esperaba ',' o ']' en la posición " pos - 1)
            }
        }
        if c = '"'
            return Json._String(s, &pos)
        if RegExMatch(s, "\G-?\d+(\.\d+)?([eE][-+]?\d+)?", &m, pos) {
            pos += m.Len
            return m[0] + 0
        }
        for lit, val in Map("true", 1, "false", 0, "null", "")
            if SubStr(s, pos, StrLen(lit)) == lit {
                pos += StrLen(lit)
                return val
            }
        throw ValueError("JSON inválido en la posición " pos)
    }

    static _String(s, &pos) {
        pos++
        out := ""
        loop {
            RegExMatch(s, '\G[^"\\]*', &m, pos)
            out .= m[0]
            pos += m.Len
            c := SubStr(s, pos, 1)
            if c = '"' {
                pos++
                return out
            }
            if c = ""
                throw ValueError("JSON: string sin cerrar")
            e := SubStr(s, pos + 1, 1)
            if e == "u" {
                code := Integer("0x" SubStr(s, pos + 2, 4))
                pos += 6
                if code >= 0xD800 && code <= 0xDBFF && SubStr(s, pos, 2) == "\u" {
                    low := Integer("0x" SubStr(s, pos + 2, 4))
                    if low >= 0xDC00 && low <= 0xDFFF {
                        code := 0x10000 + ((code - 0xD800) << 10) + (low - 0xDC00)
                        pos += 6
                    }
                }
                out .= Chr(code)
            } else if Json.Escapes.Has(e) {
                out .= Json.Escapes[e]
                pos += 2
            } else
                throw ValueError("JSON: escape inválido en la posición " pos)
        }
    }
}
