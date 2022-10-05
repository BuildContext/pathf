import 'package:flutter/material.dart';
import 'package:path_finder/utils/path_finder_bfs.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var instance = await SharedPreferences.getInstance();
  runApp(
    GlobalProvider(
      sharedPreferences: instance,
      resultsRepository: ResultsRepository(),
      child: const PathFinderApp(),
    ),
  );
}

class PathFinderApp extends StatelessWidget {
  const PathFinderApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Path Finder App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class ResultsRepository {
  final List<ShortestPathModel<String>> _results = [];

  addResults(List<ShortestPathModel<String>> results) =>
      _results.addAll(results);

  List<ShortestPathModel<String>> get results => _results;
}

class GlobalProvider extends InheritedWidget {
  const GlobalProvider({
    super.key,
    required this.sharedPreferences,
    required this.resultsRepository,
    required super.child,
  });
  final ResultsRepository resultsRepository;
  final SharedPreferences sharedPreferences;

  static GlobalProvider of(BuildContext context) {
    final GlobalProvider? result =
        context.dependOnInheritedWidgetOfExactType<GlobalProvider>();
    assert(result != null, 'No GlobalProvider found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(GlobalProvider old) =>
      sharedPreferences != old.sharedPreferences;
}
