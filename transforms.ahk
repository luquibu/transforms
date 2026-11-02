#Requires AutoHotkey v2.0
#SingleInstance Force
#Include %A_LineFile%\..\lib\json.ahk

; Transforms: seleccioná texto, apretá el atajo de un transform y la respuesta de Claude reemplaza la selección.
; Atajos, modelo y prompts salen de config.ini y prompts\. tests\probar.ps1 arma el mismo pedido para probar los prompts:
; un cambio en el cuerpo o en los encabezados del pedido va en los dos.

API_URL := "https://api.anthropic.com/v1/messages"
API_VERSION := "2026-10-21"
API_BETA := "server-side-fallback-2026-07-01"
; Tiempo que se espera antes de restaurar el portapapeles: algunas apps (Teams) leen el pegado con demora.
ESPERA_PEGADO_MS := 400

SplitPath(A_LineFile, , &Raiz)
Ocupado := false
Cancelado := false
Http := ""

A_IconTip := "Transforms"
A_TrayMenu.Delete()
A_TrayMenu.Add("Recargar", (*) => Reload())
A_TrayMenu.Add("Abrir carpeta de prompts", (*) => Run(Raiz "\prompts"))
A_TrayMenu.Add()
A_TrayMenu.Add("Salir", (*) => ExitApp())

CargarTransforms()

; Registra un atajo por cada sección de config.ini distinta de [general]; cada sección pisa los valores de [general].
CargarTransforms() {
    ini := LeerIni(Raiz "\config.ini")
    comun := RTrim(FileRead(Raiz "\prompts\_comun.md", "UTF-8"), " `t`r`n")
    for nombre, seccion in ini {
        if nombre = "general"
            continue
        cfg := ini["general"].Clone()
        for k, v in seccion
            cfg[k] := v
        try {
            cfg["sistema"] := comun "`n`n" Trim(FileRead(Raiz "\prompts\" cfg["prompt"], "UTF-8"), " `t`r`n")
            Hotkey(cfg["hotkey"], Transformar.Bind(cfg))
        } catch as e
            MsgBox("No se pudo cargar el transform [" nombre "]: " e.Message, "Transforms", "Icon!")
    }
}

LeerIni(ruta) {
    ini := Map()
    seccion := ""
    loop parse FileRead(ruta, "UTF-8"), "`n", "`r" {
        l := Trim(A_LoopField)
        if l = "" || SubStr(l, 1, 1) = ";"
            continue
        if RegExMatch(l, "^\[(.+)\]$", &m) {
            seccion := m[1]
            ini[seccion] := Map()
        } else if seccion != "" && RegExMatch(l, "^([^=]+)=(.*)$", &m)
            ini[seccion][Trim(m[1])] := Trim(m[2])
    }
    return ini
}

; Copia la selección, la manda a Claude y pega el resultado. Ante cualquier falla deja el texto y el portapapeles como estaban.
Transformar(cfg, *) {
    global Ocupado, Cancelado
    if Ocupado {
        Avisar("Ya hay un pedido en curso; Esc lo cancela.")
        return
    }
    ; La variable se relee del registro porque Recargar hereda el entorno con el que arrancó el script.
    clave := EnvGet("TRANSFORMS_API_KEY")
    if clave = ""
        clave := RegRead("HKCU\Environment", "TRANSFORMS_API_KEY", "")
    if clave = "" {
        Avisar("Falta la variable de entorno TRANSFORMS_API_KEY.")
        return
    }

    guardado := ClipboardAll()
    A_Clipboard := ""
    Send("^c")
    if !ClipWait(1) || Trim(A_Clipboard, " `t`r`n") = "" {
        A_Clipboard := guardado
        Avisar("No hay texto seleccionado.")
        return
    }
    texto := StrReplace(A_Clipboard, "`r`n", "`n")
    ventana := WinExist("A")

    Ocupado := true
    Cancelado := false
    SetTimer(OcultarAviso, 0)
    ToolTip(cfg["label"] "… (Esc cancela)")
    Hotkey("Esc", Cancelar, "On")
    try
        resultado := Pedir(cfg, clave, texto)
    catch as e
        falla := e.Message
    Hotkey("Esc", "Off")
    ToolTip()
    Ocupado := false

    if IsSet(falla) {
        A_Clipboard := guardado
        Avisar(falla)
        return
    }

    ; El modelo no conserva los espacios y saltos de línea de los bordes; se reponen los de la selección.
    RegExMatch(texto, "^\s*", &inicio)
    RegExMatch(texto, "\s*$", &fin)
    resultado := inicio[0] Trim(StrReplace(resultado, "`r`n", "`n"), " `t`n") fin[0]
    resultado := StrReplace(resultado, "`n", "`r`n")

    if !WinActive(ventana) {
        try {
            WinActivate(ventana)
            activa := WinWaitActive(ventana, , 1)
        } catch
            activa := false
        if !activa {
            A_Clipboard := resultado
            Avisar("Cambiaste de ventana: el resultado quedó en el portapapeles.")
            return
        }
    }
    A_Clipboard := resultado
    Send("^v")
    Sleep(ESPERA_PEGADO_MS)
    A_Clipboard := guardado
}

Cancelar(*) {
    global Cancelado
    Cancelado := true
}

; Devuelve el texto de la respuesta o lanza un Error cuyo mensaje se muestra tal cual al usuario.
Pedir(cfg, clave, texto) {
    global Http
    cuerpo := Map(
        "model", cfg["model"],
        "max_tokens", Integer(cfg["max_tokens"]),
        "thinking", Map("type", "between_tools"),
        "output_config", Map("effort", cfg["effort"]),
        "fallbacks", "default",
        "system", [Map("type", "text", "text", cfg["sistema"], "cache_control", Map("type", "ephemeral"))],
        "messages", [Map("role", "user", "content", texto)])
    timeoutMs := Integer(cfg["timeout_s"]) * 1000

    ; Un solo objeto WinHttp para reutilizar la conexión entre pedidos. El pedido es asíncrono para que Esc pueda cortarlo.
    try {
        if !IsObject(Http)
            Http := ComObject("WinHttp.WinHttpRequest.5.1")
        Http.SetTimeouts(timeoutMs, timeoutMs, timeoutMs, timeoutMs)
        Http.Open("POST", API_URL, true)
        Http.SetRequestHeader("content-type", "application/json")
        Http.SetRequestHeader("x-api-key", clave)
        Http.SetRequestHeader("anthropic-version", API_VERSION)
        Http.SetRequestHeader("anthropic-beta", API_BETA)
        Http.Send(Utf8Bytes(Json.Dump(cuerpo)))
    } catch as e
        throw Error("No se pudo conectar con la API: " PrimeraLinea(e.Message))

    limite := A_TickCount + timeoutMs
    loop {
        try
            listo := Http.WaitForResponse(0)
        catch as e
            throw Error("No se pudo conectar con la API: " PrimeraLinea(e.Message))
        if listo
            break
        if Cancelado {
            Http.Abort()
            throw Error("Cancelado; el texto quedó como estaba.")
        }
        if A_TickCount > limite {
            Http.Abort()
            throw Error("Sin respuesta en " cfg["timeout_s"] " s; el texto quedó como estaba.")
        }
        Sleep(50)
    }

    estado := Http.Status
    try
        respuesta := Json.Load(Utf8Text(Http.ResponseBody))
    catch
        respuesta := Map()
    if !(respuesta is Map)
        respuesta := Map()

    if estado != 200 {
        fallaApi := respuesta.Get("error", "")
        detalle := fallaApi is Map ? fallaApi.Get("message", "") : ""
        throw Error(MotivoHttp(estado) (detalle != "" ? ": " detalle : ""))
    }
    switch respuesta.Get("stop_reason", "") {
        case "refusal": throw Error("Claude no procesó el texto (refusal); quedó como estaba.")
        case "max_tokens": throw Error("La respuesta quedó cortada por max_tokens; el texto quedó como estaba.")
    }
    resultado := ""
    for bloque in respuesta.Get("content", [])
        if bloque is Map && bloque.Get("type", "") = "text"
            resultado .= bloque["text"]
    if Trim(resultado, " `t`r`n") = ""
        throw Error("La respuesta llegó vacía; el texto quedó como estaba.")
    return resultado
}

MotivoHttp(estado) {
    switch {
        case estado = 400: return "La API rechazó el pedido (400)"
        case estado = 401: return "Clave de API inválida (401)"
        case estado = 403: return "La clave no tiene permiso (403)"
        case estado = 429: return "Límite de uso alcanzado (429); probá en un rato"
        case estado = 529: return "La API está sobrecargada (529); probá en un rato"
        case estado >= 500: return "Error de la API (" estado ")"
        default: return "Error HTTP " estado
    }
}

; WinHttp necesita los bytes UTF-8 en un SAFEARRAY; un string lo convertiría con la página de códigos del sistema.
Utf8Bytes(s) {
    buf := Buffer(StrPut(s, "UTF-8"))
    StrPut(s, buf, "UTF-8")
    n := buf.Size - 1
    arr := ComObjArray(0x11, n)
    DllCall("RtlMoveMemory", "Ptr", NumGet(ComObjValue(arr), 8 + A_PtrSize, "Ptr"), "Ptr", buf, "UPtr", n)
    return arr
}

; La respuesta se decodifica desde los bytes porque ResponseText depende del charset que declare el servidor.
Utf8Text(arr) {
    n := arr.MaxIndex() + 1
    return n > 0 ? StrGet(NumGet(ComObjValue(arr), 8 + A_PtrSize, "Ptr"), n, "UTF-8") : ""
}

PrimeraLinea(s) => Trim(StrSplit(Trim(s, " `t`r`n"), "`n")[1], " `t`r")

Avisar(mensaje) {
    ToolTip(mensaje)
    SetTimer(OcultarAviso, -4000)
}

OcultarAviso() => ToolTip()
