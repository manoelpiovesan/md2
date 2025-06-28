import 'package:flutter/material.dart';

/// Widget de ações rápidas para execução de algoritmos e operações no grafo.
class GraphActions extends StatelessWidget {
  /// Callback para execução do algoritmo BFS.
  final VoidCallback onBFS;
  /// Callback para execução do algoritmo DFS.
  final VoidCallback onDFS;
  /// Callback para execução do algoritmo de Dijkstra.
  final VoidCallback onDijkstra;
  /// Callback para execução do menor caminho de Dijkstra (opcional).
  final VoidCallback? onDijkstraPath;
  /// Callback para detecção de ciclos.
  final VoidCallback onCycles;

  /// Cria um widget de ações para o grafo.
  const GraphActions({
    super.key,
    required this.onBFS,
    required this.onDFS,
    required this.onDijkstra,
    required this.onDijkstraPath,
    required this.onCycles,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FloatingActionButton.extended(
          heroTag: 'bfs',
          onPressed: onBFS,
          label: const Text('BFS'),
          icon: const Icon(Icons.travel_explore),
        ),
        const SizedBox(height: 12),
        FloatingActionButton.extended(
          heroTag: 'dfs',
          onPressed: onDFS,
          label: const Text('DFS'),
          icon: const Icon(Icons.alt_route),
        ),
        const SizedBox(height: 12),
        FloatingActionButton.extended(
          heroTag: 'dijkstra',
          onPressed: onDijkstra,
          label: const Text('Dijkstra'),
          icon: const Icon(Icons.route),
        ),
        const SizedBox(height: 12),
        FloatingActionButton.extended(
          heroTag: 'dijkstra_path',
          onPressed: onDijkstraPath,
          label: const Text('Menor Caminho'),
          icon: const Icon(Icons.shortcut),
        ),
        const SizedBox(height: 12),
        FloatingActionButton.extended(
          heroTag: 'cycles',
          onPressed: onCycles,
          label: const Text('Ciclos'),
          icon: const Icon(Icons.loop),
        ),
      ],
    );
  }
}
