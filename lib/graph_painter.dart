import 'package:flutter/material.dart';
import 'models.dart';

/// Responsável por desenhar o grafo na tela, incluindo vértices, arestas e destaques.
class GraphPainter extends CustomPainter {
  /// Grafo a ser desenhado.
  final Graph graph;
  /// Raio dos vértices.
  final double vertexRadius;
  /// Id do vértice selecionado, se houver.
  final int? selectedVertexId;

  /// Cria um GraphPainter para desenhar o grafo.
  GraphPainter({required this.graph, this.vertexRadius = 24, this.selectedVertexId});

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    for (final edge in graph.edges) {
      final from = graph.vertices.firstWhere((v) => v.id == edge.from);
      final to = graph.vertices.firstWhere((v) => v.id == edge.to);
      final isPath = edge.state == EdgeState.path;
      final edgeColor = isPath
          ? Colors.orangeAccent.shade200
          : Colors.orange.shade400;
      final edgeWidth = isPath ? 6.0 : 2.5;
      final edgePaintPath = Paint()
        ..color = edgeColor
        ..strokeWidth = edgeWidth
        ..style = PaintingStyle.stroke;
      canvas.drawLine(from.position, to.position, edgePaintPath);
      if (edge.weight != null) {
        final mid = Offset(
          (from.position.dx + to.position.dx) / 2,
          (from.position.dy + to.position.dy) / 2,
        );
        textPainter.text = TextSpan(
          text: edge.weight!.toStringAsFixed(1),
          style: TextStyle(
            color: isPath ? Colors.orangeAccent.shade200 : Colors.orange.shade700,
            fontSize: 16,
            fontWeight: isPath ? FontWeight.bold : FontWeight.normal,
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          mid - Offset(textPainter.width / 2, textPainter.height / 2),
        );
      }
      if (edge.directed) {
        final dir = (to.position - from.position).direction;
        final arrowLen = 16.0;
        final arrowAngle = 0.4;
        final arrowP1 = to.position - Offset.fromDirection(dir + arrowAngle, arrowLen);
        final arrowP2 = to.position - Offset.fromDirection(dir - arrowAngle, arrowLen);
        canvas.drawLine(to.position, arrowP1, edgePaintPath);
        canvas.drawLine(to.position, arrowP2, edgePaintPath);
      }
    }

    for (final vertex in graph.vertices) {
      Color color;
      if (vertex.id == selectedVertexId) {
        color = Colors.redAccent;
      } else {
        switch (vertex.state) {
          case VertexState.visited:
            color = Colors.lightGreenAccent.shade400;
            break;
          case VertexState.waiting:
            color = Colors.amberAccent.shade200;
            break;
          case VertexState.finished:
            color = Colors.lightBlueAccent.shade200;
            break;
          default:
            color = Colors.blueGrey.shade200;
        }
      }
      final paint = Paint()..color = color;
      canvas.drawCircle(vertex.position, vertexRadius, paint);
      if (vertex.id == selectedVertexId) {
        final borderPaint = Paint()
          ..color = Colors.red
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4;
        canvas.drawCircle(vertex.position, vertexRadius + 3, borderPaint);
      }
      textPainter.text = TextSpan(
        text: vertex.id.toString(),
        style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        vertex.position - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant GraphPainter oldDelegate) {
    return true;
  }
}
