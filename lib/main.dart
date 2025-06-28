import 'package:flutter/material.dart';
import 'graph_painter.dart';
import 'models.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(

        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: Colors.orange.shade400,
          secondary: Colors.amberAccent.shade200,
          background: Colors.grey[900]!,
          surface: Colors.blueGrey[900]!,
          onPrimary: Colors.black,
          onSecondary: Colors.black,
          onBackground: Colors.white70,
          onSurface: Colors.white70,
        ),
        scaffoldBackgroundColor: Colors.grey[900],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blueGrey,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          color: Colors.blueGrey[800],
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.orange.shade400,
          foregroundColor: Colors.black,
        ),
        buttonTheme: const ButtonThemeData(
          buttonColor: Colors.orange,
          textTheme: ButtonTextTheme.primary,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.blueGrey[800],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white70),
          bodyMedium: TextStyle(color: Colors.white70),
          titleLarge: TextStyle(color: Colors.white),
        ),
      ),
      home: const MyHomePage(title: 'Gráfos Interativos'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

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

  int? _getVertexAtPosition(Offset pos, {double radius = 28}) {
    for (final v in _graph.vertices) {
      if ((v.position - pos).distance <= radius) {
        return v.id;
      }
    }
    return null;
  }

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

  void _handleTap(Offset pos) {
    final tappedId = _getVertexAtPosition(pos);
    setState(() {
      if (tappedId == null) {
        // Nenhum vértice: adiciona novo
        _graph.addVertex(pos);
        _selectedVertexId = null;
      } else {
        if (_selectedVertexId == null) {
          // Seleciona o primeiro vértice
          _selectedVertexId = tappedId;
        } else if (_selectedVertexId != tappedId) {
          // Seleciona o segundo vértice e cria aresta
          // Dialog para peso da aresta
          final from = _selectedVertexId!;
          final to = tappedId;
          _selectedVertexId = null;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showEdgeWeightDialog(from, to);
          });
        } else {
          // Tocou no mesmo vértice: desseleciona
          _selectedVertexId = null;
        }
      }
    });
  }

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
    // Remover aresta se pressionar próximo a uma
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
                value:
                    _graph.vertices.isNotEmpty
                        ? _graph.vertices.first.id
                        : null,
                items:
                    _graph.vertices
                        .map(
                          (v) => DropdownMenuItem(
                            value: v.id,
                            child: Text('Vértice ${v.id}'),
                          ),
                        )
                        .toList(),
                onChanged: (v) => startId = v,
                decoration: const InputDecoration(labelText: 'Origem'),
              ),
              DropdownButtonFormField<int>(
                value:
                    _graph.vertices.length > 1 ? _graph.vertices.last.id : null,
                items:
                    _graph.vertices
                        .map(
                          (v) => DropdownMenuItem(
                            value: v.id,
                            child: Text('Vértice ${v.id}'),
                          ),
                        )
                        .toList(),
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

  Future<void> _runDijkstraPath(int start, int end) async {
    // Limpa estados visuais
    for (var v in _graph.vertices) {
      v.state = VertexState.normal;
    }
    for (var e in _graph.edges) {
      e.state = EdgeState.normal;
    }
    final dist = _graph.dijkstra(start);
    if (dist[end] == double.infinity) return;
    // Reconstruir caminho do fim ao início
    final pathVertices = <int>[];
    final pathEdges = <Edge>[];
    int? current = end;
    while (current != null && current != start) {
      pathVertices.add(current);
      Edge? prevEdge;
      for (final e in _graph.edges) {
        // Considera direção e peso
        if (e.to == current &&
            dist[e.from] != null &&
            (dist[e.from]! + (e.weight ?? 1.0) - dist[current]!).abs() < 1e-6) {
          prevEdge = e;
          break;
        }
        // Se não direcionado, verifica o outro sentido
        if (!e.directed &&
            e.from == current &&
            dist[e.to] != null &&
            (dist[e.to]! + (e.weight ?? 1.0) - dist[current]!).abs() < 1e-6) {
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
    // Anima vértices e arestas do caminho
    for (int i = 0; i < reversedVertices.length; i++) {
      await Future.delayed(const Duration(milliseconds: 350));
      setState(() {
        _graph.vertices.firstWhere((v) => v.id == reversedVertices[i]).state =
            VertexState.visited;
        if (i > 0 && i - 1 < reversedEdges.length) {
          reversedEdges[i - 1].state = EdgeState.path;
        }
      });
    }
  }

  // Remove delays e await dos algoritmos para não travar a UI ao adicionar vértices
  Future<void> _runAlgorithm(String algo) async {
    if (_selectedVertexId == null) return;
    setState(() {
      _algorithm = algo;
      _algoStartId = _selectedVertexId;
      _algoResult = null;
      _dijkstraResult = null;
    });
    // Limpa estados visuais
    for (var v in _graph.vertices) {
      v.state = VertexState.normal;
    }
    const delay = Duration(milliseconds: 300);
    if (algo == 'BFS') {
      final order = _graph.bfs(_selectedVertexId!);
      for (final id in order) {
        await Future.delayed(delay);
        setState(() {
          _graph.vertices.firstWhere((v) => v.id == id).state =
              VertexState.visited;
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
          _graph.vertices.firstWhere((v) => v.id == id).state =
              VertexState.visited;
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
          _graph.vertices.firstWhere((v) => v.id == entry.key).state =
              VertexState.visited;
        });
      }
      setState(() {
        _dijkstraResult = result;
      });
    }
  }

  /// Calcula a menor distância de um ponto a um segmento de reta.
  double _distanceToSegment(Offset p, Offset a, Offset b) {
    final ap = p - a;
    final ab = b - a;
    final ab2 = ab.dx * ab.dx + ab.dy * ab.dy;
    final t = ab2 == 0 ? 0 : (ap.dx * ab.dx + ap.dy * ab.dy) / ab2;
    final tClamped = t.clamp(0.0, 1.0);
    final closest = Offset(a.dx + ab.dx * tClamped, a.dy + ab.dy * tClamped);
    return (p - closest).distance;
  }

  /// Exibe um diálogo com todos os ciclos encontrados no grafo e permite destacar um ciclo selecionado.
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
                child:
                    cycles.isEmpty
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

  /// Destaca visualmente um ciclo fechado no grafo, animando vértices e arestas do ciclo.
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
          GestureDetector(
            onTapUp: (details) {
              _handleTap(details.localPosition);
            },
            onLongPressStart: (details) {
              _handleLongPress(details.localPosition);
            },
            onPanStart: (details) {
              final id = _getVertexAtPosition(details.localPosition);
              if (id != null) {
                setState(() {
                  _draggingVertexId = id;
                });
              }
            },
            onPanUpdate: (details) {
              if (_draggingVertexId != null) {
                setState(() {
                  _graph.moveVertex(_draggingVertexId!, details.localPosition);
                });
              }
            },
            onPanEnd: (details) {
              setState(() {
                _draggingVertexId = null;
              });
            },
            child: CustomPaint(
              painter: GraphPainter(
                graph: _graph,
                selectedVertexId: _selectedVertexId,
              ),
              child: SizedBox(width: double.infinity, height: double.infinity),
            ),
          ),
          Positioned(
            right: 16,
            top: 16,
            child: Column(
              children: [
                FloatingActionButton.extended(
                  heroTag: 'bfs',
                  onPressed: () => _runAlgorithm('BFS'),
                  label: const Text('BFS'),
                  icon: const Icon(Icons.travel_explore),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.extended(
                  heroTag: 'dfs',
                  onPressed: () => _runAlgorithm('DFS'),
                  label: const Text('DFS'),
                  icon: const Icon(Icons.alt_route),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.extended(
                  heroTag: 'dijkstra',
                  onPressed: () => _runAlgorithm('Dijkstra'),
                  label: const Text('Dijkstra'),
                  icon: const Icon(Icons.route),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.extended(
                  heroTag: 'dijkstra_path',
                  onPressed:
                      _graph.vertices.length > 1 ? _showDijkstraDialog : null,
                  label: const Text('Menor Caminho'),
                  icon: const Icon(Icons.shortcut),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.extended(
                  heroTag: 'cycles',
                  onPressed: _showCyclesDialog,
                  label: const Text('Ciclos'),
                  icon: const Icon(Icons.loop),
                ),
              ],
            ),
          ),
        ],
      ),
      // Removido o FloatingActionButton de alternar direcionamento
    );
  }
}
