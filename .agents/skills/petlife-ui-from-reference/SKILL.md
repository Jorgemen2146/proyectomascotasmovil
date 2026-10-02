---
name: petlife-ui-from-reference
description: Implementa o ajusta pantallas Flutter de PetLife a partir de screenshots, mockups o referencias visuales. Usar cuando una tarea pida reproducir una referencia en la app móvil; no usar para cambios sin referencia visual.
---

# PetLife UI from Reference

Trata la referencia visual como fuente de verdad. Reprodúcela con la máxima fidelidad razonable; no entregues una variante meramente inspirada ni sustituyas elementos por alternativas más fáciles.

## Antes de editar

1. Inspecciona la referencia con la herramienta de imagen disponible. Registra estructura, jerarquía, medidas relativas, alineación, espaciado, colores, tipografía, radios, sombras, imágenes, iconos, barras, overlays y estados visibles.
2. Localiza la pantalla, ruta, providers, modelos, repositorios y pruebas existentes. Si la pantalla existe, entiende su comportamiento antes de cambiarla.
3. Lee [references/petlife-frontend.md](references/petlife-frontend.md) para aplicar la arquitectura, design system y componentes reales del repositorio.
4. Define internamente qué archivos cambiar, qué reutilizar, qué crear, qué lógica preservar y qué cambios son solo visuales.

Si la referencia no permite medir un detalle con certeza, infiérelo por proporciones y usa el lenguaje visual de PetLife. Una decisión explícita de la referencia prevalece sobre el valor visual por defecto de PetLife.

## Implementación

- Conserva Riverpod, GoRouter, Dio, modelos, repositorios, servicios y contratos existentes. No cambies endpoints ni introduzcas otro gestor de estado para resolver una tarea visual.
- Mantén datos reales conectados al estado/backend. No hardcodees identidad o contenido de usuario ni agregues datos permanentes de demostración.
- Reutiliza tokens y widgets compartidos cuando puedan producir la referencia fielmente. No fuerces un componente existente si su contrato visual impide reproducirla: extiéndelo de forma compatible o crea una pieza enfocada en la feature.
- Mantén loading, loaded, empty, error, disabled y refreshing que correspondan. No elimines estados para imitar una captura estática.
- Usa iconos funcionales, no emojis, salvo que la referencia contenga explícitamente un emoji.
- Diseña para SafeArea, teclado, scroll, textos y nombres largos, imágenes y anchos pequeños/grandes. Evita dimensiones rígidas salvo que sean necesarias para la composición y tengan una adaptación comprobable.
- Limita el cambio a la pantalla y componentes necesarios; no hagas refactors generales.

## Verificación

Lee y sigue [references/visual-validation.md](references/visual-validation.md). Formatear, analizar y probar es necesario, pero no sustituye la comparación visual.

No afirmes que el resultado es "pixel perfect", "idéntico" o "exactamente igual" si no ejecutaste la pantalla y la comparaste visualmente con la referencia. Informa con precisión qué validación no fue posible.
