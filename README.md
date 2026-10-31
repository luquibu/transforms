# Transforms

Script de AutoHotkey v2 que queda residente en la bandeja. Seleccionás texto en cualquier app, apretás el atajo de un transform y la respuesta de Claude reemplaza la selección.

| Atajo | Transform | Prompt |
|---|---|---|
| Ctrl+Alt+E | Pulir un dictado en español | `prompts/pulir-espanol.md` |
| Ctrl+Alt+S | Dictado en español → inglés | `prompts/dictado-a-ingles.md` |
| Ctrl+Alt+A | Reescribir como pedido a un agente de IA | `prompts/pedido-agente.md` |
| Ctrl+Alt+D | Inglés → español conciso | `prompts/ingles-a-espanol.md` |

## Instalación

1. Instalá AutoHotkey v2 desde autohotkey.com.
2. Creá la variable de entorno de usuario `ANTHROPIC_API_KEY` con tu clave: Configuración de Windows → buscá "variables de entorno" → "Editar las variables de entorno de esta cuenta" → Nueva.
3. Abrí `transforms.ahk` con doble clic. Para que arranque con Windows, poné un acceso directo a `transforms.ahk` en la carpeta que abre `shell:startup` (Win+R).

## Uso

- Mientras espera la respuesta muestra un aviso junto al mouse; Esc cancela el pedido. Atiende un pedido a la vez.
- Ctrl+Z en la app deshace el reemplazo. El portapapeles vuelve a su contenido anterior después de pegar.
- Si no hay texto seleccionado, falta la clave, la API devuelve un error o se agota el tiempo, avisa y no toca el texto.
- Si cambiás de ventana antes de que llegue la respuesta, el resultado queda en el portapapeles en lugar de pegarse.

## Cambiar un transform

- `prompts/_comun.md` tiene las reglas compartidas: fidelidad, literales, nombres y vocabulario técnico. Cada pedido manda `_comun.md` seguido del prompt del transform.
- `config.ini` define por transform el atajo, el prompt y el aviso de espera, y puede pisar `model`, `effort` y `max_tokens` de `[general]`.
- Después de editar, elegí "Recargar" en el menú del ícono de la bandeja.

## Probar los prompts

`tests/probar.ps1` corre los casos de `tests/casos/<prompt>/` contra la API con el mismo pedido que arma el script y guarda cada salida en `tests/salidas/<prompt>/`, que git ignora. Cada caso se llama por la trampa que cubre, por ejemplo `03-planificar-sin-push.txt`.

```powershell
.\tests\probar.ps1                               # todos los prompts
.\tests\probar.ps1 -Solo pulir-espanol            # un prompt
.\tests\probar.ps1 -Solo pedido-agente -SegundaPasada   # además reaplica el prompt sobre su salida
```

La segunda pasada debería cambiar poco o nada. La tabla final muestra latencia, tokens y lectura de caché por caso.
