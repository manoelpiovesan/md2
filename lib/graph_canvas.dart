import 'package:flutter/material.dart';
import 'graph_painter.dart';
import 'models.dart';

/// Widget responsável por exibir o canvas interativo do grafo e capturar eventos do usuário.
class GraphCanvas extends StatelessWidget {
  /// Grafo a ser exibido.
  final Graph graph;
  /// Id do vértice selecionado, se houver.
  final int? selectedVertexId;
  /// Callback para toque simples.
  final void Function(Offset) onTap;
  /// Callback para long press.
  final void Function(Offset) onLongPress;
  /// Callback para início de arrasto.
  final void Function(Offset) onPanStart;
  /// Callback para atualização de arrasto.
  final void Function(Offset) onPanUpdate;
  /// Callback para fim de arrasto.
  final VoidCallback onPanEnd;

  /// Cria um GraphCanvas para interação com o grafo.
  const GraphCanvas({
    super.key,
    required this.graph,
    required this.selectedVertexId,
    required this.onTap,
    required this.onLongPress,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: (details) => onTap(details.localPosition),
      onLongPressStart: (details) => onLongPress(details.localPosition),
      onPanStart: (details) => onPanStart(details.localPosition),
      onPanUpdate: (details) => onPanUpdate(details.localPosition),
      onPanEnd: (_) => onPanEnd(),
      child: CustomPaint(
        painter: GraphPainter(
          graph: graph,
          selectedVertexId: selectedVertexId,
        ),
        child: const SizedBox(width: double.infinity, height: double.infinity),
      ),
    );
  }
}
