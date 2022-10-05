import 'package:flutter/material.dart';
import 'package:path_finder/utils/utils.dart';

import '../utils/path_finder_bfs.dart';

class PreviewResultPage extends StatelessWidget {
  final ShortestPathModel<String> previewModel;
  const PreviewResultPage({
    Key? key,
    required this.previewModel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview Screen'),
      ),
      body: Grids(
        previewModel: previewModel,
      ),
    );
  }
}

class Grids extends StatelessWidget {
  final ShortestPathModel<String> previewModel;

  const Grids({
    Key? key,
    required this.previewModel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int rowLength = previewModel.gridWithAllSteps.first.length;
    return CustomScrollView(
      slivers: <Widget>[
        SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: rowLength,
          ),
          delegate: SliverChildBuilderDelegate(
            (_, i) => _buildChildren[i],
            childCount: _buildChildren.length,
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (content, index) {
              var text = Utils.pathToString(previewModel);
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Text(
                    text,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              );
            },
            childCount: 1,
          ),
        ),
      ],
    );
  }

  List<Widget> get _buildChildren {
    List<Widget> result = [];
    int rowLength = previewModel.gridWithAllSteps.first.length;

    for (var x = 0; x < previewModel.gridWithAllSteps.length; x++) {
      for (var y = 0; y < previewModel.gridWithAllSteps[x].length; y++) {
        var colors = _parseColor(
            previewModel.gridWithAllSteps[x][y], previewModel.config);

        result.add(
          Container(
            //padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              border: rowLength < 20
                  ? Border.all(color: Colors.black, width: 1)
                  : null,
              color: colors.cellColor,
            ),
            margin: rowLength < 20 ? const EdgeInsets.all(.5) : null,
            child: Center(
              child: GridTile(
                child: Text(
                  '($x,$y)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textColor,
                    fontSize: _getFS(rowLength),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }
    return result;
  }

  CellColor _parseColor<T>(T cell, GridCellConfig<T> config) {
    if (cell == config.start) {
      return CellColor(const Color(0xFF64FFDA), textColor: Colors.grey[700]!);
    } else if (cell == config.goal) {
      return CellColor(const Color(0xFF009688));
    } else if (cell == config.wall) {
      return CellColor(const Color(0xFF000000));
    } else if (cell == config.shortestPath) {
      return CellColor(const Color(0xFF4CAF50));
    } else {
      return CellColor(const Color(0xFFFFFFFF),
          textColor: const Color(0xFF000000));
    }
  }
}

double _getFS(int rowLength) {
  if (rowLength < 10) {
    return 15.0;
  } else if (rowLength < 15) {
    return 10.0;
  } else {
    return .0;
  }
}

class CellColor {
  final Color cellColor;
  final Color textColor;

  CellColor(
    this.cellColor, {
    this.textColor = Colors.white,
  });
}
