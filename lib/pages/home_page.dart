import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../main.dart';
import 'processing_page.dart';
import 'results_list_page.dart';
import '../utils/utils.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _formKey = GlobalKey<FormState>();
  bool buttonIsActive = true;
  String validURL = '';

  get label => Column(
        children: const [
          SizedBox(
            height: 20,
          ),
          Text('Set valid API base url in order to continue'),
          SizedBox(
            height: 20,
          ),
        ],
      );
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appbar,
      body: body,
    );
  }

  Widget get body {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            label,
            textField,
            const Spacer(),
            button,
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget get appbar {
    return AppBar(
      title: const Text('Home Screen'),
      leading: IconButton(
        icon: const Icon(Icons.history),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ResultsListPage(
                repository: GlobalProvider.of(context).resultsRepository,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget get button {
    return ElevatedButton(
      onPressed: onPressed,
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all<Color>(
          buttonIsActive ? Colors.blue : Colors.grey[500]!,
        ),
      ),
      child: const Text('Start counting process'),
    );
  }

  void onPressed() {
    if (buttonIsActive && _formKey.currentState!.validate()) {
      Utils.pushSnackBar(context, 'Processing Data Request');
      _formKey.currentState!.save();

      buttonToggle(false);
      getDataForProcessing(validURL).then(
        (value) {
          if (value != null) {
            Navigator.of(context)
                .push(MaterialPageRoute(
                    builder: (context) => ProcessingPage(data: value.data)))
                .then((value) => buttonToggle(true));
          } else {
            Utils.pushSnackBar(context, 'Server Error');
          }
        },
      );
    }
  }

  void buttonToggle(bool isActive) {
    setState(() {
      buttonIsActive = isActive;
    });
  }

  TextFormField get textField => TextFormField(
        initialValue:
            GlobalProvider.of(context).sharedPreferences.getString('baseURL'),
        decoration: const InputDecoration(
          icon: Icon(Icons.sync_alt_outlined),
          labelText: 'URL *',
        ),
        onSaved: (String? value) {
          if (value != null) {
            saveURLonDevice(value);
            validURL = value;
          }
        },
        validator: _validateMyInput,
      );

  void saveURLonDevice(String value) =>
      GlobalProvider.of(context).sharedPreferences.setString('baseURL', value);

  String? _validateMyInput(String? value) {
    String pattern =
        r'(http|https)://[\w-]+(\.[\w-]+)+([\w.,@?^=%&amp;:/~+#-]*[\w@?^=%&amp;/~+#-])?';
    RegExp regex = RegExp(pattern);
    return value != null && !regex.hasMatch(value) ? 'Enter Valid URL' : null;
  }

  Future<DataForProcessingResponse?> getDataForProcessing(
      String validURL) async {
    var client = http.Client();

    DataForProcessingResponse? result;

    try {
      var uri = Uri.parse(validURL);
      var response = await client.get(uri);

      var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));

      return DataForProcessingResponse.fromJson(decodedResponse);
    } catch (_) {
    } finally {
      client.close();
    }
    return result;
  }
}

class DataForProcessingResponse {
  final bool error;
  final String message;
  final List<FieldData> data;

  DataForProcessingResponse(this.error, this.message, this.data);

  DataForProcessingResponse.fromJson(Map<String, dynamic> json)
      : error = json['error'] as bool,
        message = json['message'] as String,
        data = (json['data'] as List<dynamic>)
            .map((e) => FieldData.fromJson(e))
            .toList();
}

class FieldData {
  final String id;
  final List<String> field;
  final Map<String, int> start;
  final Map<String, int> end;

  FieldData(this.id, this.field, this.start, this.end);

  @override
  FieldData.fromJson(Map<String, dynamic> json)
      : id = json['id'] as String,
        field =
            (json['field'] as List<dynamic>).map((e) => e.toString()).toList(),
        start = (json['start'] as Map<String, dynamic>)
            .map((key, value) => MapEntry(key, value)),
        end = (json['end'] as Map<String, dynamic>)
            .map((key, value) => MapEntry(key, value));
}
