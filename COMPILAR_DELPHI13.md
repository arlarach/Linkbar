# Compilar Linkbar con Delphi 13 Community Edition

## Cambios ya aplicados en este código

| Archivo | Problema en Delphi 13 CE | Arreglo |
|---|---|---|
| `src/Linkbar.dpr` | En configuración **Debug** usaba `Linkbar.ExceptionDialog`, que depende de la librería **JEDI JCL** (no viene con Community Edition) → error *"File not found: JclSysUtils.dcu"* | Ahora solo se incluye si defines `USE_JCL` |
| `src/Linkbar.dproj` | Configuración por defecto = Debug | Por defecto = **Release** |
| `src/Linkbar.dproj` | El post-build `copy` fallaba si la carpeta tiene espacios (ej. `C:\Users\Alvaro Lara\...`) | Rutas entre comillas |
| `src/Linkbar.dproj` | Referencia a paquete viejo `TntUnicodeVcl_R70` | Eliminada |
| `components/Jumplist/JumpLists.Api.Deprecated.pas` | Tipo de `IStream.Seek` cambió entre versiones de Delphi → error *E2033 Types of actual and formal var parameters must be identical* | Usa `LargeUInt`, el mismo tipo que declara tu versión de Delphi |

## Pasos

1. **Descomprime** el zip en una carpeta, por ejemplo `C:\Dev\Linkbar`.

2. **Instala el componente SpinEdit** (lo usa la ventana de Configuración):
   - En Delphi: *File → Open* → `components\SpinEdit\SpinEdit.dpk`
   - En el *Projects* (panel derecho), clic derecho sobre `SpinEdit.bpl` → **Install**.
   - Debe decir *"Package installed. TnSpinEdit registered"*.
   - Si usas el **IDE de 64 bits** de Delphi 13, el paquete debe compilarse para Win64 (en Projects → Target Platforms agrega *Windows 64-bit*). Lo más simple es usar el IDE normal (32 bits).
   - Cierra el paquete (*File → Close All*).

3. **Abre el proyecto**: *File → Open Project* → `src\Linkbar.dproj`.
   - Si pregunta por actualizar el proyecto a la nueva versión → **Sí/OK**.
   - ⚠️ Si alguna vez aparece *"Class TnSpinEdit not found. Ignore the error and continue?"* → elige **Cancel**, NO "Ignore". Si ignoras y guardas, Delphi borra esos controles del formulario. (Significa que el paso 2 no quedó bien.)

4. En *Projects*, elige **Build Configurations → Release** y **Target Platforms → Windows 64-bit**.

5. **Project → Build Linkbar** (Shift+F9).
   - El exe queda en la carpeta `exe\` (`Linkbar.exe` y copia `LinkbarWin64.exe`).

6. **Ejecuta** `exe\Linkbar.exe`. La carpeta `exe\Locales` debe estar junto al exe (trae español: `es-ES.ini`).

## Si aparece un error

Copia el mensaje completo del panel **Messages** (archivo, línea y código, ej. `[dcc64 Error] mUnit.pas(1234): E2010 ...`) y envíamelo; lo corrijo.
