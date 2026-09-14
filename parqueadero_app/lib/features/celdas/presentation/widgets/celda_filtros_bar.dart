import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/celda.dart';
import '../celda_list_notifier.dart';

/// Buscador (por código de celda o placa) + chips de filtro por estado/tipo,
/// en reemplazo de los tres dropdowns anteriores. Sin filtro de zona: no
/// tiene un equivalente razonable en una fila de chips (las zonas son texto
/// libre, no un enum chico) — la zona se sigue viendo en el header de cada
/// sección de la grilla.
class CeldaFiltrosBar extends ConsumerWidget {
  const CeldaFiltrosBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          _BuscadorField(),
          SizedBox(height: AppSpacing.sm),
          _ChipsFiltro(),
          SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

class _BuscadorField extends ConsumerWidget {
  const _BuscadorField();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(celdaListNotifierProvider.notifier);
    return TextField(
      onChanged: notifier.setBusquedaFiltro,
      decoration: const InputDecoration(
        isDense: true,
        prefixIcon: Icon(Icons.search, size: 20),
        hintText: 'Buscar placa o celda',
      ),
    );
  }
}

class _ChipsFiltro extends ConsumerWidget {
  const _ChipsFiltro();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // `.select`: el poll de 30s de `CeldaListNotifier` notifica en CADA
    // refresco (`CeldaListState` no implementa `==`), así que observar el
    // estado completo repintaba los 6 ChoiceChip cada medio minuto aunque el
    // filtro no hubiera cambiado. Un `record` sí compara por valor: mientras
    // estado y tipo sigan iguales, Riverpod no notifica.
    final (:estadoFiltro, :tipoFiltro) = ref.watch(
      celdaListNotifierProvider.select(
        (s) => (estadoFiltro: s.estadoFiltro, tipoFiltro: s.tipoFiltro),
      ),
    );
    final notifier = ref.read(celdaListNotifierProvider.notifier);

    Widget chip({required String label, required bool activo, required VoidCallback onTap}) {
      return ChoiceChip(
        label: Text(label),
        selected: activo,
        onSelected: (_) => onTap(),
        backgroundColor: AppColors.concreto,
        selectedColor: AppColors.asfalto,
        side: activo ? BorderSide.none : const BorderSide(color: AppColors.linea, width: 0.5),
        labelStyle: TextStyle(color: activo ? AppColors.demarcacion : AppColors.asfalto),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip(
            label: 'Todas',
            activo: estadoFiltro == null && tipoFiltro == null,
            onTap: () {
              notifier.setEstadoFiltro(null);
              notifier.setTipoFiltro(null);
            },
          ),
          const SizedBox(width: AppSpacing.sm),
          chip(
            label: 'Libres',
            activo: estadoFiltro == EstadoCelda.libre,
            onTap: () {
              final activo = estadoFiltro == EstadoCelda.libre;
              notifier.setEstadoFiltro(activo ? null : EstadoCelda.libre);
              notifier.setTipoFiltro(null);
            },
          ),
          const SizedBox(width: AppSpacing.sm),
          chip(
            label: 'Ocupadas',
            activo: estadoFiltro == EstadoCelda.ocupada,
            onTap: () {
              final activo = estadoFiltro == EstadoCelda.ocupada;
              notifier.setEstadoFiltro(activo ? null : EstadoCelda.ocupada);
              notifier.setTipoFiltro(null);
            },
          ),
          const SizedBox(width: AppSpacing.sm),
          chip(
            label: 'Carro',
            activo: tipoFiltro == TipoVehiculo.carro,
            onTap: () {
              final activo = tipoFiltro == TipoVehiculo.carro;
              notifier.setTipoFiltro(activo ? null : TipoVehiculo.carro);
              notifier.setEstadoFiltro(null);
            },
          ),
          const SizedBox(width: AppSpacing.sm),
          chip(
            label: 'Moto',
            activo: tipoFiltro == TipoVehiculo.moto,
            onTap: () {
              final activo = tipoFiltro == TipoVehiculo.moto;
              notifier.setTipoFiltro(activo ? null : TipoVehiculo.moto);
              notifier.setEstadoFiltro(null);
            },
          ),
          const SizedBox(width: AppSpacing.sm),
          chip(
            label: 'Bicicleta',
            activo: tipoFiltro == TipoVehiculo.bicicleta,
            onTap: () {
              final activo = tipoFiltro == TipoVehiculo.bicicleta;
              notifier.setTipoFiltro(activo ? null : TipoVehiculo.bicicleta);
              notifier.setEstadoFiltro(null);
            },
          ),
        ],
      ),
    );
  }
}
