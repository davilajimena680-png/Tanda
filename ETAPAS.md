# Tanda Doloreña — Etapas del TDD (versión corregida)

Ciclo de cada ronda: 🔴 ROJO (prueba que falla) → 🟢 VERDE (mínimo código) → 🔵 REFACTOR.

## Preparación

```
flutter create tanda_dolorena      # si empiezas desde cero
cd tanda_dolorena
```

Si abres este .zip ya armado: entra a la carpeta y ejecuta `flutter create .` para generar
las carpetas de plataforma (android, ios...) y luego `flutter pub get`.

Estructura:

```
lib/
  modelos/        participante.dart, tanda.dart, cierre_ronda.dart
  logica/         resultado_aportacion.dart, resultado_cierre.dart, servicio_tanda.dart
  presentation/   tanda_screen.dart
  main.dart
test/
  servicio_tanda_test.dart
```

La lógica vive en Dart puro (sin imports de Flutter). La pantalla es la última capa.

---

## RONDA 1 — Registrar una aportación válida

🔴 **ROJO**: la prueba (en `test/servicio_tanda_test.dart`):

```dart
test('registrar una aportacion valida la agrega a la ronda actual', () {
  final tanda = _crearTandaDePrueba();
  final servicio = ServicioTanda(tanda);

  final resultado = servicio.registrarAportacion('p1');

  expect(resultado, ResultadoAportacion.registrada);
  expect(tanda.aportacionesRondaActual.contains('p1'), true);
});
```

🟢 **VERDE**:

```dart
ResultadoAportacion registrarAportacion(String idParticipante) {
  tanda.aportacionesRondaActual.add(idParticipante);
  return ResultadoAportacion.registrada;
}
```

## RONDA 2 — Rechazar una aportación repetida

🔴 **ROJO**:

```dart
test('un participante no puede aportar dos veces en la misma ronda', () {
  final tanda = _crearTandaDePrueba();
  final servicio = ServicioTanda(tanda);

  servicio.registrarAportacion('p1');
  final segundoIntento = servicio.registrarAportacion('p1');

  expect(segundoIntento, ResultadoAportacion.yaAporto);
});
```

🟢 **VERDE**:

```dart
ResultadoAportacion registrarAportacion(String idParticipante) {
  if (tanda.aportacionesRondaActual.contains(idParticipante)) {
    return ResultadoAportacion.yaAporto;
  }
  tanda.aportacionesRondaActual.add(idParticipante);
  return ResultadoAportacion.registrada;
}
```

## RONDA 3 — Rechazar a quien no es participante

🔴 **ROJO**:

```dart
test('alguien que no pertenece a la tanda no puede aportar', () {
  final tanda = _crearTandaDePrueba();
  final servicio = ServicioTanda(tanda);

  final resultado = servicio.registrarAportacion('desconocido');

  expect(resultado, ResultadoAportacion.participanteInvalido);
});
```

🟢 **VERDE**:

```dart
ResultadoAportacion registrarAportacion(String idParticipante) {
  final esParticipante = tanda.participantes.any((p) => p.id == idParticipante);
  if (!esParticipante) return ResultadoAportacion.participanteInvalido;
  if (tanda.aportacionesRondaActual.contains(idParticipante)) {
    return ResultadoAportacion.yaAporto;
  }
  tanda.aportacionesRondaActual.add(idParticipante);
  return ResultadoAportacion.registrada;
}
```

## RONDA 4 — Detectar cuándo todos ya aportaron

🔴 **ROJO** (2 pruebas):

```dart
test('puedeCerrarRonda es falso si falta algun participante por aportar', () {
  final tanda = _crearTandaDePrueba();
  final servicio = ServicioTanda(tanda);
  servicio.registrarAportacion('p1');
  servicio.registrarAportacion('p2');
  expect(servicio.puedeCerrarRonda(), false);
});

test('puedeCerrarRonda es verdadero cuando todos ya aportaron', () {
  final tanda = _crearTandaDePrueba();
  final servicio = ServicioTanda(tanda);
  servicio.registrarAportacion('p1');
  servicio.registrarAportacion('p2');
  servicio.registrarAportacion('p3');
  expect(servicio.puedeCerrarRonda(), true);
});
```

🟢 **VERDE**:

```dart
bool puedeCerrarRonda() {
  return tanda.participantes
      .every((p) => tanda.aportacionesRondaActual.contains(p.id));
}
```

## RONDA 5 — Cerrar la ronda y entregar el turno

🔴 **ROJO**:

```dart
test('cerrar la ronda entrega el turno al beneficiario y avanza', () {
  final tanda = _crearTandaDePrueba(); // orden: p1, p2, p3
  final servicio = ServicioTanda(tanda);
  servicio.registrarAportacion('p1');
  servicio.registrarAportacion('p2');
  servicio.registrarAportacion('p3');

  final cierre = servicio.cerrarRondaYAvanzar();

  expect(cierre.resultado, ResultadoCierre.rondaCerrada);
  expect(cierre.beneficiario!.id, 'p1');
  expect(tanda.participantes.firstWhere((p) => p.id == 'p1').yaRecibioTurno, true);
  expect(tanda.turnoActual, 1);
  expect(tanda.aportacionesRondaActual.isEmpty, true);
});
```

🟢 **VERDE**:

```dart
CierreRonda cerrarRondaYAvanzar() {
  if (!puedeCerrarRonda()) {
    return CierreRonda(ResultadoCierre.faltanAportaciones, null);
  }
  final idBeneficiario = tanda.ordenTurnos[tanda.turnoActual];
  final beneficiario = tanda.participantes.firstWhere((p) => p.id == idBeneficiario);
  beneficiario.yaRecibioTurno = true;
  tanda.aportacionesRondaActual.clear();
  tanda.turnoActual++;
  return CierreRonda(ResultadoCierre.rondaCerrada, beneficiario);
}
```

El beneficiario sale de `ordenTurnos[turnoActual]`: se respeta el orden acordado.

## RONDA 6 — No cerrar la ronda si faltan aportaciones

🔴 **ROJO**:

```dart
test('no se puede cerrar la ronda si algun participante no ha aportado', () {
  final tanda = _crearTandaDePrueba();
  final servicio = ServicioTanda(tanda);
  servicio.registrarAportacion('p1');
  servicio.registrarAportacion('p2'); // p3 no aporta

  final cierre = servicio.cerrarRondaYAvanzar();

  expect(cierre.resultado, ResultadoCierre.faltanAportaciones);
  expect(cierre.beneficiario, isNull);
  expect(tanda.turnoActual, 0);
});
```

🟢 **VERDE**: no hace falta código nuevo; el `if (!puedeCerrarRonda())` de la Ronda 5 ya lo cubre.
La prueba sigue valiendo: protege la regla contra cambios futuros.

## RONDA 7 — Detectar cuándo la tanda terminó

🔴 **ROJO** (4 pruebas; la cuarta es nueva, corrige un hueco del manual original).

Función auxiliar para no repetir código (y sin la variable `id` sin usar del original):

```dart
void _completarRonda(ServicioTanda servicio, Tanda tanda) {
  for (final p in tanda.participantes) {
    servicio.registrarAportacion(p.id);
  }
  servicio.cerrarRondaYAvanzar();
}
```

```dart
test('haTerminado es falso mientras queden turnos pendientes', () {
  final tanda = _crearTandaDePrueba();
  expect(ServicioTanda(tanda).haTerminado(), false);
});

test('haTerminado es verdadero cuando todos ya recibieron su turno', () {
  final tanda = _crearTandaDePrueba();
  final servicio = ServicioTanda(tanda);
  for (var i = 0; i < 3; i++) { _completarRonda(servicio, tanda); }
  expect(servicio.haTerminado(), true);
});

test('no se puede aportar una vez que la tanda ha terminado', () {
  final tanda = _crearTandaDePrueba();
  final servicio = ServicioTanda(tanda);
  for (var i = 0; i < 3; i++) { _completarRonda(servicio, tanda); }
  expect(servicio.registrarAportacion('p1'), ResultadoAportacion.tandaTerminada);
});

// NUEVA (correccion): cerrar una tanda terminada lanzaba RangeError
test('no se puede cerrar la ronda una vez que la tanda ha terminado', () {
  final tanda = _crearTandaDePrueba();
  final servicio = ServicioTanda(tanda);
  for (var i = 0; i < 3; i++) { _completarRonda(servicio, tanda); }
  final cierre = servicio.cerrarRondaYAvanzar();
  expect(cierre.resultado, ResultadoCierre.tandaYaTermino);
  expect(cierre.beneficiario, isNull);
});
```

🟢 **VERDE**:

```dart
bool haTerminado() => tanda.turnoActual >= tanda.ordenTurnos.length;

ResultadoAportacion registrarAportacion(String idParticipante) {
  if (haTerminado()) return ResultadoAportacion.tandaTerminada;
  final esParticipante = tanda.participantes.any((p) => p.id == idParticipante);
  if (!esParticipante) return ResultadoAportacion.participanteInvalido;
  if (tanda.aportacionesRondaActual.contains(idParticipante)) {
    return ResultadoAportacion.yaAporto;
  }
  tanda.aportacionesRondaActual.add(idParticipante);
  return ResultadoAportacion.registrada;
}

CierreRonda cerrarRondaYAvanzar() {
  if (haTerminado()) return CierreRonda(ResultadoCierre.tandaYaTermino, null); // NUEVO
  if (!puedeCerrarRonda()) {
    return CierreRonda(ResultadoCierre.faltanAportaciones, null);
  }
  // ... igual que en la Ronda 5
}
```

## RONDA 8 — Refactor: nombrar las condiciones como reglas de negocio

🔵 **REFACTOR**: se extraen métodos privados con nombre de negocio (en el manual original solo se
agregaba una variable local).

```dart
bool _esParticipante(String id) => tanda.participantes.any((p) => p.id == id);
bool _yaAporto(String id) => tanda.aportacionesRondaActual.contains(id);

ResultadoAportacion registrarAportacion(String idParticipante) {
  if (haTerminado()) return ResultadoAportacion.tandaTerminada;
  if (!_esParticipante(idParticipante)) return ResultadoAportacion.participanteInvalido;
  if (_yaAporto(idParticipante)) return ResultadoAportacion.yaAporto;

  tanda.aportacionesRondaActual.add(idParticipante);
  return ResultadoAportacion.registrada;
}
```

Corre `flutter test`: las 11 pruebas de las Rondas 1 a 7 siguen en verde. La prueba extra del grupo
"Ronda 8" solo confirma que el orden de las reglas no cambió.

## PRUEBA DE INTEGRACIÓN — Una tanda completa

```dart
test('simulacion completa: 3 vecinas completan una tanda', () {
  final tanda = _crearTandaDePrueba();
  final servicio = ServicioTanda(tanda);
  final beneficiarios = <String>[];

  while (!servicio.haTerminado()) {
    for (final p in tanda.participantes) {
      servicio.registrarAportacion(p.id);
    }
    final cierre = servicio.cerrarRondaYAvanzar();
    beneficiarios.add(cierre.beneficiario!.id);
  }

  expect(beneficiarios, ['p1', 'p2', 'p3']);
  expect(tanda.participantes.every((p) => p.yaRecibioTurno), true);
  expect(servicio.registrarAportacion('p1'), ResultadoAportacion.tandaTerminada);
});
```

## Interfaz animada

`lib/presentation/tanda_screen.dart` (ya incluida). Correcciones respecto al manual:

- `esTurnoActual` ahora es `!terminada && ordenTurnos[turnoActual] == id`, para evitar el
  `RangeError` al cerrar la última ronda.
- El encabezado muestra "¡Tanda terminada!" en vez de "Ronda actual: 5 de 4".
- Los botones se desactivan cuando la tanda termina.
- También se maneja `ResultadoCierre.tandaYaTermino`.
- Concatenaciones reemplazadas por interpolación (`'$a de $b'`).

## Cómo ejecutar

1. `flutter test` → **13 pruebas** en verde (11 de las Rondas 1-7, 1 de la Ronda 8 y 1 de integración).
2. `flutter run`
3. Toca "Aportar" en cada vecino, presiona "Cerrar ronda y entregar turno" y repite hasta
   que los 4 vecinos reciban su turno.

## Checklist

- [ ] Cada regla de negocio tiene su propia prueba
- [ ] El orden de turnos se respeta tal como se definió
- [ ] La tanda rechaza aportaciones y cierres después de terminar
- [ ] `TandaScreen` no decide quién recibe el turno: se lo pregunta a `ServicioTanda`
- [ ] La integración recorre una tanda completa y verifica el orden de beneficiarios

## Retos de extensión

- Orden de turnos al azar (barajado), con prueba de que cada quien recibe turno una sola vez.
- Historial de rondas cerradas (fecha, beneficiario).
- Permitir que alguien "falte" y reponga su aportación en la siguiente ronda.
- Notificaciones locales para avisar a quién le toca aportar.
- Persistir el estado con `shared_preferences`.
