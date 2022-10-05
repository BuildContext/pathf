import 'package:flutter/material.dart';
import 'package:path_finder/main.dart';
import 'package:path_finder/pages/preview_result_page.dart';
import 'package:path_finder/utils/utils.dart';

class ResultsListPage extends StatelessWidget {
  final ResultsRepository repository;
  const ResultsListPage({Key? key, required this.repository}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Results List Page'),
      ),
      body: ListView.separated(
        itemBuilder: ((_, i) {
          var model = repository.results[i];
          var itemText = Utils.pathToString(model);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: (() {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => PreviewResultPage(previewModel: model),
                ),
              );
            }),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                  child: Text(
                itemText,
                style: const TextStyle(fontSize: 20),
              )),
            ),
          );
        }),
        separatorBuilder: ((context, index) {
          return const Divider();
        }),
        itemCount: repository.results.length,
      ),
    );
  }
}
