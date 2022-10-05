import 'dart:async';
import 'dart:collection';

class PathFinder<T> {
  /// Grid must be 2d array with [T] cells
  ///
  /// Example <int>:
  /// [4,0,0,1],
  /// [0,0,0,1],
  /// [0,1,0,1],
  /// [0,5,0,1];
  ///
  /// Example <Map>:
  /// [{t:"a"},{t:"b"},{t:"a"},{t:"b"}],
  /// [{t:"a"},{t:"b"},{t:"a"},{t:"b"}],
  /// [{t:"a"},{t:"b"},{t:"a"},{t:"b"}],
  /// [{t:"a"},{t:"b"},{t:"a"},{t:"b"}];
  final List<List<T>> grid;

  /// Config of [T] cells
  final GridCellConfig<T> config;

  /// Subscribe to the [Stream] to get a percentage of the progress of the path found
  Stream<int> get progress => _pathFinderProgressStream.stream;

  /// Duration between iterations of the path search (for tests)
  final Duration delay;

  /// optional, if need id in results
  final String? id;

  ShortestPathModel<T>? _shortestPathModel;

  late List<List<T>> _processGrid;
  late PathFinderProgressStream _pathFinderProgressStream;
  late PathNode _start;
  late PathNode _finish;
  late int _countUnvisited;

  /// Use this constructor when Start and Finish cells aren't in the grid
  PathFinder.withoutStartAndFinish(
      {required this.config,
      required this.grid,
      this.id,
      this.delay = const Duration(microseconds: 0)}) {
    _checkGridCells(checkFinishCell: true, checkStartCell: true);
    var start = _getFirstNode(config.start);
    var finish = _getFirstNode(config.goal);
    _setProcessGrid();
    _setLates(start: start, finish: finish);
  }

  /// Use this constructor when Start and Finish cells are in the grid
  PathFinder(
      {required this.config,
      required this.grid,
      this.id,
      required PathNode start,
      required PathNode goal,
      this.delay = const Duration(microseconds: 0)}) {
    _checkGridCells();
    _setProcessGrid();
    _addStartAndFinishCellToProcessGrid(start, goal);
    _setLates(start: start, finish: goal);
  }

  void _setLates({required PathNode start, required PathNode finish}) {
    _start = start;
    _finish = finish;
    _countUnvisited = _countAllCells(config.unvisited);
    _pathFinderProgressStream = PathFinderProgressStream();
  }

  void _addStartAndFinishCellToProcessGrid(PathNode start, PathNode finish) {
    _updateGridCell(start, config.start);
    _updateGridCell(finish, config.goal);
  }

  void _setProcessGrid() {
    _processGrid = [
      for (var sublist in grid) [...sublist]
    ];
  }

  PathNode _getFirstNode(T cell) {
    for (var x = 0; x < grid.length; x++) {
      for (var y = 0; y < grid[x].length; y++) {
        if (grid[x][y] == cell) {
          return PathNode(x, y);
        }
      }
    }

    throw Exception('node not found in grid');
  }

  Future<ShortestPathModel<T>> get getShortestPath async {
    if (_shortestPathModel != null) {
      return _shortestPathModel!;
    } else {
      _shortestPathModel = await _calculateShortestPath;
      return _shortestPathModel!;
    }
  }

  /// used BFS Algorithm
  Future<ShortestPathModel<T>> get _calculateShortestPath async {
    var startGraph = PathNodeWithStep(_start.x, _start.y, 1);
    var queueToCheck = Queue<PathNodeWithStep>()..add(startGraph);
    List<PathNodeWithStep> graphs = [startGraph];

    while (queueToCheck.isNotEmpty) {
      var currPath = queueToCheck.removeFirst();
      await Future.delayed(delay);
      _pathFinderProgressStream.updateProgressPercents(
          _countUnvisited, _countAllCells(config.visited));
      for (var direction in Directions.values) {
        var newPath = PathNodeWithStep(currPath.x + direction.dx,
            currPath.y + direction.dy, currPath.step + 1);

        if (_isInsideBorders(newPath) && _isUnvisited(newPath)) {
          _updateGridCell(newPath, config.visited);
          queueToCheck.add(newPath);
          graphs.add(newPath);
        }

        if (newPath == _finish) {
          graphs.add(newPath);

          return _findTheShortestPathOnTheGraphs(graphs);
        }
      }
    }

    throw Exception("path not found");
  }

  void _updateGridCell(PathNode node, T cell) {
    var c = _processGrid[node.x][node.y];
    if (c == config.unvisited || c == config.visited) {
      _processGrid[node.x][node.y] = cell;
    }
  }

  int _countAllCells(T cell) {
    return _processGrid
        .reduce((acc, arr) => [...acc, ...arr])
        .where((e) => e == cell)
        .toList()
        .length;
  }

  bool _isUnvisited(PathNodeWithStep newPath) =>
      _processGrid[newPath.x][newPath.y] == config.unvisited;

  bool _isInsideBorders(PathNode newPath) =>
      0 <= newPath.x &&
      newPath.x < _processGrid.length &&
      0 <= newPath.y &&
      newPath.y < _processGrid[0].length;

  ShortestPathModel<T> _findTheShortestPathOnTheGraphs(
      List<PathNodeWithStep> graphs) {
    var curStep = graphs.firstWhere((p) => p == _finish);
    List<PathNode> shortestPath = [];
    do {
      if (curStep != _finish) {
        _updateGridCell(curStep, config.shortestPath);
        shortestPath.add(curStep);
      }

      var nextStepPathes =
          graphs.where((p) => p.step == curStep.step - 1).toList();
      curStep = _getNextShortestStep(nextStepPathes, curStep);
    } while (curStep != _start);

    _pathFinderProgressStream.pathIsFoundAheadOfTime();

    return ShortestPathModel(
      id: id,
      start: _start,
      goal: _finish,
      grid: grid,
      gridWithAllSteps: _processGrid,
      path: shortestPath.reversed.toList(),
      config: config,
    );
  }

  PathNodeWithStep _getNextShortestStep(
          List<PathNodeWithStep> nextStepPathes, PathNodeWithStep curPath) =>
      nextStepPathes.firstWhere((p) {
        bool testResult = false;
        for (var direction in Directions.values) {
          if (curPath.x + direction.dx == p.x &&
              curPath.y + direction.dy == p.y) {
            testResult = true;
            break;
          }
        }
        return testResult;
      });

  static void printGrid<T>(List<List<T>> grid) {
    for (var gr in grid) {
      print(gr);
    }
    print('');
  }

  void _checkGridCells(
      {bool checkStartCell = false, bool checkFinishCell = false}) {
    int startCells = 0;
    int finishCells = 0;

    for (var row in grid) {
      for (var cell in row) {
        if (cell == config.start) {
          startCells++;
        } else if (cell == config.goal) {
          finishCells++;
        } else if (cell == config.wall || cell == config.unvisited) {
          continue;
        } else if (cell == config.visited) {
          throw Exception(
              'visited cell - "$cell", should not be in the incoming grid');
        } else if (cell == config.shortestPath) {
          throw Exception(
              'shortestPath cell - "$cell", should not be in the incoming grid');
        } else {
          throw Exception('$cell is not found in gridCellConfig');
        }
      }
    }

    if (checkStartCell && startCells != 1) {
      throw Exception(
          'expected to find 1 start cell but found $startCells cells');
    } else if (!checkStartCell && startCells != 0) {
      throw Exception(
          'expected to find 0 start cell but found $startCells cells');
    }
    if (checkFinishCell && finishCells != 1) {
      throw Exception(
          'expected to find 1 finish cell but found $finishCells cells');
    } else if (!checkFinishCell && finishCells != 0) {
      throw Exception(
          'expected to find 0 finish cell but found $finishCells cells');
    }
  }

  void dispose() {}
}

/// Everywhere [T] in [GridCellConfig] must have qnique value, which coincides with the values in the grid

/// Example <int>:
/// GridCellConfig(
///   start: 4,
///   finish: 5,
///   shortestPath: 3,
///   unvisited: 0,
///   visited: 2,
///   wall: 1,
/// )
/// Example <Map>:
/// GridCellConfig(
///   start: {t:"a"},
///   finish: {t:"b"},
///   shortestPath: {t:"c"},
///   unvisited: {t:"d"},
///   visited: {t:"e"},
///   wall: {t:"f"},
/// )
class GridCellConfig<T> {
  final T start;
  final T goal;
  final T wall;
  final T unvisited;
  final T visited;
  final T shortestPath;

  GridCellConfig({
    required this.start,
    required this.goal,
    required this.wall,
    required this.unvisited,
    required this.visited,
    required this.shortestPath,
  });
}

class PathFinderProgressStream {
  final _controller = StreamController<int>();

  Stream<int> get stream => _controller.stream;

  void updateProgressPercents(int countUnvisited, int countVisited) {
    int donePercent = countVisited * 100 ~/ countUnvisited;
    _doUpdate(donePercent);
  }

  void pathIsFoundAheadOfTime() => _doUpdate(100);

  void _doUpdate(int percent) {
    if (!_controller.isClosed) {
      _sendFoundPathPercent(percent);
      _checkToCloseStream(percent);
    }
  }

  void _checkToCloseStream(int percent) {
    if (percent == 100 && !_controller.isClosed) {
      _controller.close();
    }
  }

  void _sendFoundPathPercent(int percent) {
    _controller.add(percent);
  }
}

class ShortestPathModel<T> {
  final String? id;
  final PathNode start;
  final PathNode goal;
  final List<PathNode> path;

  /// Original grid without steps
  final List<List<T>> grid;
  final List<List<T>> gridWithAllSteps;
  final GridCellConfig config;

  ShortestPathModel({
    this.id,
    required this.start,
    required this.goal,
    required this.path,
    required this.grid,
    required this.gridWithAllSteps,
    required this.config,
  });
}

class PathNodeWithStep extends PathNode {
  final int step;

  PathNodeWithStep(int dx, int dy, this.step) : super(dx, dy);

  @override
  String toString() => '($x,$y,$step)';
}

class PathNode {
  final int x;
  final int y;

  PathNode(this.x, this.y);

  PathNode.fromMap(Map<String, int> map)
      : x = map['x']!,
        y = map['y']!;

  Map<String, int> get toMap {
    return {'x': x, 'y': y};
  }

  @override
  String toString() => '($x,$y)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is PathNode && other.x == x && other.y == y;
  }

  @override
  int get hashCode => "$x$y".hashCode;
}

enum Directions {
  left(0, -1),
  rigth(0, 1),
  top(-1, 0),
  bottom(1, 0),
  leftTop(-1, -1),
  rigthTop(-1, 1),
  leftBottom(1, -1),
  rigthBottom(1, 1);

  final int dx;
  final int dy;

  const Directions(this.dx, this.dy);
}
