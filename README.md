# HomeHandover

> **«Todo lo que necesitas saber de esta casa»**

![Android](https://img.shields.io/badge/Android-Offline--First-B45309)
![Flutter](https://img.shields.io/badge/Flutter-Material%203-blue)
![Zero Telemetry](https://img.shields.io/badge/Telemetr%C3%ADa-0%25-success)

**HomeHandover** es un manual de vivienda **100 % offline** pensado para inquilinos, huéspedes, familiares o compradores: organiza llaves de paso, cuadro eléctrico, caldera, electrodomésticos y mantenimiento periódico por estancias, con acceso rápido a urgencias y paquete exportable.

---

## Características principales

- **Organización por vivienda y estancias**: crea fichas claras con ubicación exacta, resumen y pasos numerados.
- **Filtro rápido de urgencias**: destaca con un toque las fichas críticas (agua, gas, electricidad).
- **Tareas periódicas**: seguimiento local de mantenimiento recurrente.
- **Exportación PDF y ZIP verificable**: genera un manual imprimible en PDF o un archivo ZIP con `manual.html`, `manual.json` y `manifest.sha256`.
- **IA opcional BYOK (gratuita)**: desactivada por defecto; ayuda a redactar fichas claras a partir de notas rápidas tras revisión previa del texto.

---

## Privacidad y política de gratuidad

- Sin cuentas obligatorias, sin nube y sin telemetría.
- Persistencia local en SQLite.
- Claves API opcionales cifradas en **Android Keystore** con política de coste cero estricto y revisión previa antes de enviar datos.

---

## Instalación y compilación local

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

---

## Documentación adicional

- Licencias de terceros: [DEPENDENCIES.md](DEPENDENCIES.md)
- Guía de contribución: [CONTRIBUTING.md](CONTRIBUTING.md)
