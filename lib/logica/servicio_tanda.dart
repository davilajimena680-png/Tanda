import '../modelos/tanda.dart';
import '../modelos/cierre_ronda.dart';
import 'resultado_aportacion.dart';
import 'resultado_cierre.dart';

/// Reglas de negocio de la tanda (Dart puro, sin imports de Flutter).
class ServicioTanda {
  final Tanda tanda;

  ServicioTanda(this.tanda);



  bool haTerminado() => tanda.turnoActual >= tanda.ordenTurnos.length;

  bool _esParticipante(String id) => tanda.participantes.any((p) => p.id == id);

  bool _yaAporto(String id) => tanda.aportacionesRondaActual.contains(id);

  bool puedeCerrarRonda() {
    return tanda.participantes
        .every((p) => tanda.aportacionesRondaActual.contains(p.id));
  }


  ResultadoAportacion registrarAportacion(String idParticipante) {
    if (haTerminado()) return ResultadoAportacion.tandaTerminada;
    if (!_esParticipante(idParticipante)) {
      return ResultadoAportacion.participanteInvalido;
    }
    if (_yaAporto(idParticipante)) return ResultadoAportacion.yaAporto;

    tanda.aportacionesRondaActual.add(idParticipante);
    return ResultadoAportacion.registrada;
  }

  CierreRonda cerrarRondaYAvanzar() {
    if (haTerminado()) return CierreRonda(ResultadoCierre.tandaYaTermino, null);
    if (!puedeCerrarRonda()) {
      return CierreRonda(ResultadoCierre.faltanAportaciones, null);
    }

    final idBeneficiario = tanda.ordenTurnos[tanda.turnoActual];
    final beneficiario =
        tanda.participantes.firstWhere((p) => p.id == idBeneficiario);
    beneficiario.yaRecibioTurno = true;
    tanda.aportacionesRondaActual.clear();
    tanda.turnoActual++;
    return CierreRonda(ResultadoCierre.rondaCerrada, beneficiario);

  
  }
  
}
