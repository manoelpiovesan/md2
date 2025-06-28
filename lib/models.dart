import 'dart:ui';

class Vertex {
  final int id;
  Offset position;
  VertexState state;

  Vertex({required this.id, required this.position, this.state = VertexState.normal});
}

enum VertexState { normal, visited, waiting, finished }

enum EdgeState { normal, path }

class Edge {
  final int from;
  final int to;
  double? weight;
  bool directed;
  EdgeState state;
  Edge({required this.from, required this.to, this.weight, this.directed = false, this.state = EdgeState.normal});
}

class Graph {
  final List<Vertex> vertices = [];
  final List<Edge> edges = [];
  bool directed;

  Graph({this.directed = false});

  void addVertex(Offset position) {
    int id = vertices.isEmpty ? 0 : vertices.last.id + 1;
    vertices.add(Vertex(id: id, position: position));
  }

  void removeVertex(int id) {
    vertices.removeWhere((v) => v.id == id);
    edges.removeWhere((e) => e.from == id || e.to == id);
  }

  void moveVertex(int id, Offset newPosition) {
    final v = vertices.firstWhere((v) => v.id == id);
    v.position = newPosition;
  }

  void addEdge(int from, int to, {double? weight}) {
    if (!edges.any((e) => e.from == from && e.to == to && e.directed == directed)) {
      edges.add(Edge(from: from, to: to, weight: weight, directed: directed));
    }
  }

  void removeEdge(int from, int to) {
    edges.removeWhere((e) => e.from == from && e.to == to);
  }

  void toggleDirected() {
    directed = !directed;
    for (var e in edges) {
      e.directed = directed;
    }
  }

  // Algoritmos de grafos
  List<int> bfs(int startId) {
    final visited = <int>[];
    final queue = <int>[];
    queue.add(startId);
    final seen = <int>{startId};
    while (queue.isNotEmpty) {
      final v = queue.removeAt(0);
      visited.add(v);
      final neighbors = edges.where((e) => e.from == v).map((e) => e.to).toList();
      if (!directed) {
        neighbors.addAll(edges.where((e) => e.to == v).map((e) => e.from));
      }
      for (final n in neighbors) {
        if (!seen.contains(n)) {
          queue.add(n);
          seen.add(n);
        }
      }
    }
    return visited;
  }

  List<int> dfs(int startId) {
    final visited = <int>[];
    final stack = <int>[];
    final seen = <int>{};
    stack.add(startId);
    while (stack.isNotEmpty) {
      final v = stack.removeLast();
      if (!seen.contains(v)) {
        visited.add(v);
        seen.add(v);
        final neighbors = edges.where((e) => e.from == v).map((e) => e.to).toList();
        if (!directed) {
          neighbors.addAll(edges.where((e) => e.to == v).map((e) => e.from));
        }
        for (final n in neighbors.reversed) {
          if (!seen.contains(n)) {
            stack.add(n);
          }
        }
      }
    }
    return visited;
  }

  Map<int, double> dijkstra(int startId) {
    final dist = <int, double>{};
    final visited = <int>{};
    for (final v in vertices) {
      dist[v.id] = double.infinity;
    }
    dist[startId] = 0;
    while (visited.length < vertices.length) {
      int? u;
      double minDist = double.infinity;
      for (final v in vertices) {
        if (!visited.contains(v.id) && dist[v.id]! < minDist) {
          minDist = dist[v.id]!;
          u = v.id;
        }
      }
      if (u == null) break;
      visited.add(u);
      final neighbors = edges.where((e) => e.from == u).toList();
      if (!directed) {
        neighbors.addAll(edges.where((e) => e.to == u).map((e) => Edge(from: e.to, to: e.from, weight: e.weight, directed: e.directed)));
      }
      for (final e in neighbors) {
        final alt = dist[u]! + (e.weight ?? 1.0);
        if (alt < dist[e.to]!) {
          dist[e.to] = alt;
        }
      }
    }
    return dist;
  }

  // Detecta ciclos fechados (retorna lista de ciclos, cada ciclo é uma lista de ids de vértices)
  List<List<int>> findCycles() {
    List<List<int>> cycles = [];
    Set<int> visited = {};
    void dfs(int v, int parent, List<int> path) {
      visited.add(v);
      path.add(v);
      for (final e in edges.where((e) => e.from == v || (!directed && e.to == v))) {
        int u = e.from == v ? e.to : e.from;
        if (u == parent) continue;
        if (path.contains(u)) {
          // Encontrou ciclo
          int idx = path.indexOf(u);
          cycles.add(path.sublist(idx));
        } else {
          dfs(u, v, List<int>.from(path));
        }
      }
    }
    for (final v in vertices) {
      if (!visited.contains(v.id)) {
        dfs(v.id, -1, []);
      }
    }
    // Remove ciclos duplicados (mesmo conjunto de vértices)
    final unique = <String, List<int>>{};
    for (final c in cycles) {
      final sorted = List<int>.from(c)..sort();
      unique[sorted.join(",")] = c;
    }
    return unique.values.toList();
  }
}
