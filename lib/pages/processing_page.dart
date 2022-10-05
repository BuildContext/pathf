import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_finder/utils/utils.dart';

import 'home_page.dart';
import '../utils/path_finder_bfs.dart';
import '../main.dart';

class ProcessingPage extends StatefulWidget {
  final List<FieldData> data;
  const ProcessingPage({Key? key, required this.data}) : super(key: key);

  @override
  State<ProcessingPage> createState() => _ProcessingPageState();
}

class _ProcessingPageState extends State<ProcessingPage>
    with TickerProviderStateMixin {
  late AnimationController controller;

  late Future<List<ShortestPathModel<String>>> shortestPath;

  var isSent = false;

  @override
  void initState() {
    controller = AnimationController(
      value: 0.0,
      vsync: this,
    )..addListener(() {
        setState(() {});
      });
    shortestPath = _calculatePath(widget.data);
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Processing Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            const SizedBox(
              height: 20,
            ),
            Text(
              controller.value < 1
                  ? "Calculating the shortest path, please wait"
                  : 'All calculations has finished, you can send your results to server',
              style: Theme.of(context).textTheme.headline6,
            ),
            const SizedBox(
              height: 20,
            ),
            Text(
              '${(controller.value * 100).round().toString()}%',
              style: const TextStyle(fontSize: 25),
            ),
            const SizedBox(
              height: 20,
            ),
            CircularProgressIndicator(
              value: controller.value,
              strokeWidth: 4,
            ),
            const Spacer(),
            _sendButton
          ],
        ),
      ),
    );
  }

  Widget get _sendButton => FutureBuilder<List<ShortestPathModel<String>>>(
        future: shortestPath,
        builder: ((context, snapshot) {
          var isActive = snapshot.data != null;

          return ElevatedButton(
            onPressed: () {
              if (isActive && !isSent) {
                _sendResultsToServer(snapshot.data!);
                setState(() {
                  isSent = true;
                });
              }
            },
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all<Color>(
                isActive && !isSent ? Colors.blue : Colors.grey[500]!,
              ),
            ),
            child: isActive
                ? const Text('Send results to server')
                : const Text('Waiting results'),
          );
        }),
      );

  Future<List<ShortestPathModel<String>>> _calculatePath(
      List<FieldData> data) async {
    List<ShortestPathModel<String>> result = [];
    for (var i = 0; i < data.length; i++) {
      var grid = data[i].field.map((e) => [...e.characters]).toList();
      var start = PathNode.fromMap(data[i].start);
      var goal = PathNode.fromMap(data[i].end);
      var id = data[i].id;

      var pf = PathFinder(
        grid: grid,
        id: id,
        config: GridCellConfig(
          start: 'S',
          shortestPath: '*',
          unvisited: '.',
          visited: '#',
          wall: 'X',
          goal: 'F',
        ),
        start: start,
        goal: goal,
        delay: const Duration(milliseconds: 1),
      );
      pf.progress.listen((event) {
        controller.value =
            ((100 * (i) / data.length) + event / data.length) / 100;
      });
      result.add(await pf.getShortestPath);
    }

    return result;
  }

  void _sendResultsToServer(List<ShortestPathModel<String>> shortestPath) =>
      {_sendRequest(shortestPath).then(handleResponse)};

  void handleResponse(ResultResponse? resultResponse) {
    if (resultResponse != null &&
        !resultResponse.error &&
        resultResponse.message == 'OK') {
      Utils.pushSnackBar(context, "Sucsess");
      shortestPath.then((value) =>
          GlobalProvider.of(context).resultsRepository.addResults(value));
    } else {
      var err = resultResponse != null ? ':${resultResponse.message}' : '';
      Utils.pushSnackBar(context, "Server error$err");
    }
  }

  Future<ResultResponse?> _sendRequest(
      List<ShortestPathModel<String>> value) async {
    var reqestBody = jsonEncode(SendResultingRequest().toJson(value));

    var client = http.Client();

    ResultResponse? result;

    try {
      var validURL =
          GlobalProvider.of(context).sharedPreferences.getString('baseURL');
      var uri = Uri.parse(validURL!);
      var response = await client.post(uri, body: reqestBody, headers: {
        "content-type": "application/json",
      });

      var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));

      result = ResultResponse.fromJson(decodedResponse);
    } catch (_) {
    } finally {
      client.close();
    }
    return result;
  }
}

class SendResultingRequest {
  List<Map<String, dynamic>> toJson(List<ShortestPathModel<String>> value) =>
      value
          .map(
            (e) => {
              "id": e.id,
              "result": {
                "steps": _stepsToMap(e),
                "path": Utils.pathToString(e),
              }
            },
          )
          .toList();

  List<Map<String, int>> _stepsToMap(ShortestPathModel<String> value) {
    var first = {'x': value.start.x, 'y': value.start.y};
    var middle = value.path.map((e) => {'x': e.x, 'y': e.y});
    var last = {'x': value.goal.x, 'y': value.goal.y};

    return [first, ...middle, last];
  }
}

class ResultData {
  final List<Result> result;
  ResultData(this.result);
  ResultData.fromJson(Map<String, dynamic> json)
      : result = (json['result'] as List<dynamic>)
            .map((e) => Result.fromJson(e))
            .toList();
}

class ResultResponse {
  final bool error;
  final String message;
  final List<Result> data;

  ResultResponse(this.error, this.message, this.data);

  ResultResponse.fromJson(Map<String, dynamic> json)
      : error = json['error'] as bool,
        message = json['message'] as String,
        data = (json['data'] as List<dynamic>)
            .map((e) => Result.fromJson(e))
            .toList();
}

class Result {
  final String id;
  final bool correct;

  Result(this.id, this.correct);

  Result.fromJson(Map<String, dynamic> json)
      : id = json['id'] as String,
        correct = json['correct'] as bool;
}
