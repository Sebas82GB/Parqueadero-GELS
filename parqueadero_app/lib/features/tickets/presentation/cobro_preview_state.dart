import '../../../core/network/api_exception.dart';
import '../domain/cobro_preview.dart';

class CobroPreviewState {
  const CobroPreviewState({
    this.isLoading = false,
    this.preview,
    this.error,
    this.esTerminal = false,
  });

  final bool isLoading;
  final CobroPreview? preview;
  final AppException? error;

  /// El ticket ya no está ABIERTO (lo cerró/anuló otro operador) o dejó de
  /// existir: seguir reintentando cada 30s no tiene sentido, así que el
  /// notifier cancela el timer y deja este flag en true.
  final bool esTerminal;

  CobroPreviewState copyWith({
    bool? isLoading,
    CobroPreview? preview,
    bool clearError = false,
    AppException? error,
    bool? esTerminal,
  }) {
    return CobroPreviewState(
      isLoading: isLoading ?? this.isLoading,
      preview: preview ?? this.preview,
      error: clearError ? null : (error ?? this.error),
      esTerminal: esTerminal ?? this.esTerminal,
    );
  }
}
