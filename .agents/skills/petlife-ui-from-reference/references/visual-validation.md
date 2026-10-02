# Flujo de fidelidad y validación visual

## 1. Descomponer la referencia

Antes de editar, crea un inventario interno por regiones, de arriba abajo:

- viewport, SafeArea, status/navigation bars y fondo;
- header/app bar, contenido principal, elementos flotantes y navegación inferior;
- columnas/filas, alineaciones, distribución, scroll y capas;
- medidas relativas: márgenes exteriores, padding interior, gaps, anchos, altos y proporciones de imagen;
- texto: familia, tamaño, peso, altura de línea, tracking, alineación, wrapping y truncado;
- superficies: color, gradiente, borde, radio, sombra y opacidad;
- iconos/imágenes: recurso, tamaño, color, `BoxFit`, recorte, foco y fallback;
- interacción y estados que la captura no muestre pero el flujo real necesite.

Distingue observación directa de inferencia. Para detalles no visibles, sigue el design system de PetLife.

## 2. Preservar el contrato de la pantalla

Traza el dato desde provider/controller hasta repositorio antes de mover UI. Conserva navegación, callbacks, formularios, validación, accesibilidad y estados asíncronos. Una captura cargada no autoriza eliminar loading, empty, error, disabled o refreshing.

Decide la reutilización por fidelidad y compatibilidad:

- usa el widget existente sin cambios si coincide;
- añade parámetros compatibles si la variación será reutilizable;
- crea un widget privado de feature si es específico;
- evita alterar globalmente un token para corregir una sola pantalla.

## 3. Verificar técnicamente

Después de implementar:

1. Ejecuta `dart format` solo sobre archivos Dart modificados.
2. Ejecuta `flutter analyze`.
3. Ejecuta primero los tests de la feature y responsive afectados; después amplía a `flutter test` si el tiempo y entorno lo permiten.
4. Ejecuta `flutter build apk --debug` cuando el cambio o la tarea justifique validar Android.
5. Revisa el diff para confirmar que no cambiaste lógica, contratos ni archivos ajenos accidentalmente.

No ocultes fallos preexistentes: sepáralos de los introducidos por el cambio y reporta ambos con evidencia.

## 4. Comparar el render

Si hay emulador/dispositivo:

1. Ejecuta PetLife con la configuración apropiada y navega a la pantalla real.
2. Captura el mismo tamaño/estado que la referencia, con datos reales o fixtures temporales de test; no agregues datos falsos permanentes.
3. Compara lado a lado, y usa overlay/diferencia visual si las herramientas lo permiten.
4. Revisa geometría antes que decoración: estructura, posición, tamaño, padding, tipografía, color, bordes/sombras, imágenes/iconos y navegación.
5. Corrige diferencias materiales y repite hasta que otra iteración no aporte una mejora visible importante.
6. Repite al menos en un teléfono pequeño y uno grande; verifica teclado, scroll, textos/nombres largos y estados loading/empty/error pertinentes.

Si no hay dispositivo o no se puede alcanzar la pantalla, completa las verificaciones estáticas y de widgets disponibles, y declara exactamente qué comparación visual faltó. Nunca conviertas una compilación exitosa en una afirmación de igualdad visual.

## Criterio de cierre

La tarea termina cuando la referencia está reproducida con fidelidad razonable, la funcionalidad y navegación siguen operativas, no hay nuevos errores relevantes de analyzer/tests, no hay overflows conocidos, los estados y responsive están cubiertos, y la comparación visual se realizó cuando el entorno lo permitió.
