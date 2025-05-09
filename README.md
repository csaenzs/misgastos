# 📱 Gastos Compartidos

Aplicación móvil para la gestión de gastos compartidos, desarrollada en **Flutter 3.19.5** con almacenamiento **local usando Hive**.  
Ideal para controlar gastos, registrar ingresos, establecer presupuestos por categoría y visualizar informes, todo **sin necesidad de conexión a internet**.

---

## 🚀 Funcionalidades Principales

- ✅ Registro de **gastos** e **ingresos** con categorías personalizables.
- ✅ Control de **presupuestos mensuales por categoría**.
- ✅ Indicadores visuales de control de gasto: 🟢 Dentro del presupuesto, 🟠 Cerca del límite, 🔴 Presupuesto superado.
- ✅ Informes diarios y mensuales.
- ✅ **Soporte multimoneda** (COP configurado por defecto).
- ✅ Almacenamiento completamente local con **Hive** (ideal para uso offline).
- ✅ Limpieza automática de datos antiguos y normalización de claves en Hive.

---

## 📦 Tecnologías Utilizadas

| Tecnología     | Versión                |
|----------------|------------------------|
| Flutter        | 3.19.5                 |
| Dart           | 3.x.x                  |
| Hive           | ^2.0.5                 |
| Hive Flutter   | ^1.1.0                 |
| intl           | ^0.18.1                |
| scoped_model   | ^2.0.0-nullsafety.0    |
| table_calendar | ^3.0.0                  |

---

## 📲 Instalación Rápida

```bash
git clone https://github.com/<TU_USUARIO>/<NOMBRE_REPO>.git
cd <NOMBRE_REPO>
flutter pub get
flutter run


📅 Últimas Actualizaciones
🚀 Migración completa de Firebase a Hive (funcionalidad 100% offline).

📊 Corrección y normalización en la gestión de presupuestos mensuales.

💾 Implementación de migración automática de claves mal formateadas en Hive.

📈 Mejoras en el informe diario y mensual de ingresos y gastos.

🎨 Mejora de la interfaz visual con indicadores gráficos de estado presupuestal.

👨‍💻 Desarrollador
Cristian Saenz

📧 Contacto: csaenz.0414@gmail.com

📝 Licencia
Este proyecto está bajo la licencia MIT.
Puedes usarlo, modificarlo y distribuirlo libremente, siempre citando al autor original.