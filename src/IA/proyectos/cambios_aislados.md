# Registro de Cambios Circunstanciales

- `mUnit.pas` - 2026-10-14 09:05 Elementos fijos al colapsar (>>): imPinned, archivo pinned, SaveLinks/LoadPinned, PinnedLength, OnlyPinned en DrawItems/QuerySizing/UpdateWindowSize/DockBounds
- `LBToolbar.pas` - 2026-10-14 09:05 Campo Pinned, Sizes.OnlyPinned, PinnedWidth y layout de fijos en UpdateLines
- `mUnit.pas` - 2026-10-14 10:00 7 mejoras de colapso: persistir collapsed, reintento diferido de guardado, fijar todas las acciones, separador antes de fijos, colapsar con pantalla completa, animación en dock
- `LBToolbar.pas` - 2026-10-14 10:00 PinnedSepRect: hueco/separador antes de los elementos fijos en UpdateLines
- `Linkbar.SettingsForm.pas` - 2026-10-14 10:00 Checkboxes: colapsar con pantalla completa y animar colapso (dock); constantes INI en Linkbar.Consts.pas
- `mUnit.pas` - 2026-10-14 13:59 Tooltip en >>, marca visual de fijos, menú clic derecho en >>, contraer automático por inactividad (TooltipAnchor, DrawPinnedMark, AutoCollapseTick)
- `Linkbar.SettingsForm.pas` - 2026-10-14 13:59 Casilla de contraer automático por inactividad; constantes INI_AUTOCOLLAPSE en Linkbar.Consts.pas
- `mUnit.pas` - 2026-10-14 19:42 Iconos centrados en reposo con zoom: ZoomOffset (ZoomRoom div 2) reemplaza a ZoomBefore; el icono ampliado crece hacia ambos lados
- `LBToolbar.pas` - 2026-10-14 19:42 TPanelSizes.ZoomOffset en lugar de ZoomBefore; layout y fijos usan el desplazamiento centrado
