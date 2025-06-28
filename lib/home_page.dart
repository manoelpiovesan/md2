import 'package:flutter/material.dart';
import 'graph_actions.dart';
import 'graph_canvas.dart';
import 'models.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Graph _graph;
  int? _selectedVertexId;
  int? _draggingVertexId;

  String? _algorithm; // 'BFS', 'DFS', 'Dijkstra'
  int? _algoStartId;
  Map<int, double>? _dijkstraResult;
  List<int>? _algoResult;

  int? _dijkstraStartId;
  int? _dijkstraEndId;

  @override
  void initState() {
    super.initState();
    _graph = Graph();
  }

  /// Retorna o id do vértice na posição informada, se houver.
  int? _getVertexAtPosition(Offset pos, {double radius = 28}) {
    for (final v in _graph.vertices) {
      if ((v.position - pos).distance <= radius) {
        return v.id;
      }
    }
    return null;
  }

  /// Exibe um diálogo para inserir o peso da aresta entre dois vértices.
  Future<void> _showEdgeWeightDialog(int from, int to) async {
    double? weight;
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Peso da aresta'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              hintText: 'Peso (opcional, padrão 1)',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  weight = double.tryParse(controller.text);
                }
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    setState(() {
      _graph.addEdge(from, to, weight: weight);
    });
  }

  /// Lida com o toque no canvas, selecionando ou criando vértices/arestas.
  void _handleTap(Offset pos) {
    final tappedId = _getVertexAtPosition(pos);
    setState(() {
      if (tappedId == null) {
        _graph.addVertex(pos);
        _selectedVertexId = null;
      } else {
        if (_selectedVertexId == null) {
          _selectedVertexId = tappedId;
        } else if (_selectedVertexId != tappedId) {
          final from = _selectedVertexId!;
          final to = tappedId;
          _selectedVertexId = null;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showEdgeWeightDialog(from, to);
          });
        } else {
          _selectedVertexId = null;
        }
      }
    });
  }

  /// Lida com long press para remover vértices ou arestas.
  void _handleLongPress(Offset pos) {
    final tappedId = _getVertexAtPosition(pos);
    if (tappedId != null) {
      setState(() {
        _graph.removeVertex(tappedId);
        if (_selectedVertexId == tappedId) {
          _selectedVertexId = null;
        }
      });
      return;
    }
    for (final edge in _graph.edges) {
      final from = _graph.vertices.firstWhere((v) => v.id == edge.from);
      final to = _graph.vertices.firstWhere((v) => v.id == edge.to);
      final distance = _distanceToSegment(pos, from.position, to.position);
      if (distance < 18) {
        setState(() {
          _graph.removeEdge(edge.from, edge.to);
        });
        break;
      }
    }
  }

  /// Exibe diálogo para seleção de origem e destino do Dijkstra.
  Future<void> _showDijkstraDialog() async {
    int? startId;
    int? endId;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Menor caminho (Dijkstra)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: _graph.vertices.isNotEmpty ? _graph.vertices.first.id : null,
                items: _graph.vertices.map((v) => DropdownMenuItem(
                  value: v.id,
                  child: Text('Vértice ${v.id}'),
                )).toList(),
                onChanged: (v) => startId = v,
                decoration: const InputDecoration(labelText: 'Origem'),
              ),
              DropdownButtonFormField<int>(
                value: _graph.vertices.length > 1 ? _graph.vertices.last.id : null,
                items: _graph.vertices.map((v) => DropdownMenuItem(
                  value: v.id,
                  child: Text('Vértice ${v.id}'),
                )).toList(),
                onChanged: (v) => endId = v,
                decoration: const InputDecoration(labelText: 'Destino'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    if (startId != null && endId != null) {
      setState(() {
        _dijkstraStartId = startId;
        _dijkstraEndId = endId;
      });
      await _runDijkstraPath(startId!, endId!);
    }
  }

  /// Executa a animação do menor caminho de Dijkstra entre dois vértices.
  Future<void> _runDijkstraPath(int start, int end) async {
    for (var v in _graph.vertices) {
      v.state = VertexState.normal;
    }
    for (var e in _graph.edges) {
      e.state = EdgeState.normal;
    }
    final dist = _graph.dijkstra(start);
    if (dist[end] == double.infinity) return;
    final pathVertices = <int>[];
    final pathEdges = <Edge>[];
    int? current = end;
    while (current != null && current != start) {
      pathVertices.add(current);
      Edge? prevEdge;
      for (final e in _graph.edges) {
        if (e.to == current && dist[e.from] != null && (dist[e.from]! + (e.weight ?? 1.0) - dist[current]!).abs() < 1e-6) {
          prevEdge = e;
          break;
        }
        if (!e.directed && e.from == current && dist[e.to] != null && (dist[e.to]! + (e.weight ?? 1.0) - dist[current]!).abs() < 1e-6) {
          prevEdge = e;
          break;
        }
      }
      if (prevEdge == null) break;
      pathEdges.add(prevEdge);
      current = prevEdge.from == current ? prevEdge.to : prevEdge.from;
    }
    if (current == start) pathVertices.add(start);
    final reversedVertices = pathVertices.reversed.toList();
    final reversedEdges = pathEdges.reversed.toList();
    for (int i = 0; i < reversedVertices.length; i++) {
      await Future.delayed(const Duration(milliseconds: 350));
      setState(() {
        _graph.vertices.firstWhere((v) => v.id == reversedVertices[i]).state = VertexState.visited;
        if (i > 0 && i - 1 < reversedEdges.length) {
          reversedEdges[i - 1].state = EdgeState.path;
        }
      });
    }
  }

  /// Executa o algoritmo selecionado (BFS, DFS ou Dijkstra) a partir do vértice selecionado.
  Future<void> _runAlgorithm(String algo) async {
    if (_selectedVertexId == null) return;
    setState(() {
      _algorithm = algo;
      _algoStartId = _selectedVertexId;
      _algoResult = null;
      _dijkstraResult = null;
    });
    for (var v in _graph.vertices) {
      v.state = VertexState.normal;
    }
    const delay = Duration(milliseconds: 300);
    if (algo == 'BFS') {
      final order = _graph.bfs(_selectedVertexId!);
      for (final id in order) {
        await Future.delayed(delay);
        setState(() {
          _graph.vertices.firstWhere((v) => v.id == id).state = VertexState.visited;
        });
      }
      setState(() {
        _algoResult = order;
      });
    } else if (algo == 'DFS') {
      final order = _graph.dfs(_selectedVertexId!);
      for (final id in order) {
        await Future.delayed(delay);
        setState(() {
          _graph.vertices.firstWhere((v) => v.id == id).state = VertexState.visited;
        });
      }
      setState(() {
        _algoResult = order;
      });
    } else if (algo == 'Dijkstra') {
      final result = _graph.dijkstra(_selectedVertexId!);
      for (final entry in result.entries) {
        await Future.delayed(delay);
        setState(() {
          _graph.vertices.firstWhere((v) => v.id == entry.key).state = VertexState.visited;
        });
      }
      setState(() {
        _dijkstraResult = result;
      });
    }
  }

  /// Calcula a menor distância de um ponto até um segmento de reta.
  double _distanceToSegment(Offset p, Offset a, Offset b) {
    final ap = p - a;
    final ab = b - a;
    final ab2 = ab.dx * ab.dx + ab.dy * ab.dy;
    final t = ab2 == 0 ? 0 : (ap.dx * ab.dx + ap.dy * ab.dy) / ab2;
    final tClamped = t.clamp(0.0, 1.0);
    final closest = Offset(a.dx + ab.dx * tClamped, a.dy + ab.dy * tClamped);
    return (p - closest).distance;
  }

  /// Exibe um diálogo com os ciclos encontrados no grafo e permite destacá-los.
  Future<void> _showCyclesDialog() async {
    final cycles = _graph.findCycles();
    int? selectedIndex;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Ciclos encontrados'),
              content: SizedBox(
                width: 300,
                child: cycles.isEmpty
                    ? const Text('Nenhum ciclo fechado encontrado.')
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ...List.generate(
                            cycles.length,
                            (i) => ListTile(
                              title: Text(
                                '${cycles[i].join(' → ')} → ${cycles[i].first}',
                              ),
                              leading: Radio<int>(
                                value: i,
                                groupValue: selectedIndex,
                                onChanged: (v) {
                                  setStateDialog(() {
                                    selectedIndex = v;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
                if (cycles.isNotEmpty)
                  TextButton(
                    onPressed: selectedIndex != null
                        ? () {
                            Navigator.of(context).pop();
                            _highlightCycle(cycles[selectedIndex!]);
                          }
                        : null,
                    child: const Text('Destacar ciclo selecionado'),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  /// Destaca visualmente um ciclo no grafo.
  void _highlightCycle(List<int> cycle) async {
    for (var v in _graph.vertices) {
      v.state = VertexState.normal;
    }
    for (var e in _graph.edges) {
      e.state = EdgeState.normal;
    }
    for (int i = 0; i < cycle.length; i++) {
      final from = cycle[i];
      final to = cycle[(i + 1) % cycle.length];
      setState(() {
        _graph.vertices.firstWhere((v) => v.id == from).state = VertexState.visited;
        for (final e in _graph.edges) {
          if ((e.from == from && e.to == to) || (!e.directed && e.from == to && e.to == from)) {
            e.state = EdgeState.path;
          }
        }
      });
      await Future.delayed(const Duration(milliseconds: 350));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Stack(
        children: [
          GraphCanvas(
            graph: _graph,
            selectedVertexId: _selectedVertexId,
            onTap: _handleTap,
            onLongPress: _handleLongPress,
            onPanStart: (pos) {
              final id = _getVertexAtPosition(pos);
              if (id != null) {
                setState(() {
                  _draggingVertexId = id;
                });
              }
            },
            onPanUpdate: (pos) {
              if (_draggingVertexId != null) {
                setState(() {
                  _graph.moveVertex(_draggingVertexId!, pos);
                });
              }
            },
            onPanEnd: () {
              setState(() {
                _draggingVertexId = null;
              });
            },
          ),
          Positioned(
            right: 16,
            top: 16,
            child: GraphActions(
              onBFS: () => _runAlgorithm('BFS'),
              onDFS: () => _runAlgorithm('DFS'),
              onDijkstra: () => _runAlgorithm('Dijkstra'),
              onDijkstraPath: _graph.vertices.length > 1 ? _showDijkstraDialog : null,
              onCycles: _showCyclesDialog,
            ),
          ),
        ],
      ),
    );
  }
}
