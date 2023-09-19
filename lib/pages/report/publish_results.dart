import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../router/router.dart';

enum PublishResultsType { error, success }

class PublishResultsPage extends StatefulWidget {
  final String? type;
  List types = ["error", "success"];

  PublishResultsPage({
    Key? key,
    this.type = "success",
  }) : super(key: key);

  @override
  _PublishResultsPageState createState() => _PublishResultsPageState();
}

class _PublishResultsPageState extends State<PublishResultsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text(FlutterI18n.translate(context, "report.info.reportHacker")),
      ),
      body: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        child: IndexedStack(
          index: widget.types.indexOf(widget.type),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_sharp,
                  size: FontSize.larger.value,
                  color: Theme.of(context).colorScheme.error,
                ),
                Text(
                  FlutterI18n.translate(context, "report.messages.failureTitle"),
                  style: TextStyle(fontSize: FontSize.xxLarge.value),
                  textAlign: TextAlign.center,
                ),
                Text(
                  FlutterI18n.translate(context, "report.messages.failureSubtitle"),
                  style: TextStyle(fontSize: FontSize.small.value),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 50),
                MaterialButton(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  color: Theme.of(context).colorScheme.primary,
                  elevation: 0,
                  onPressed: () {
                    Navigator.pop(context, "continue");
                  },
                  child: Text(FlutterI18n.translate(context, "report.button.continue")),
                ),
                const SizedBox(height: 20),
                MaterialButton(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  color: Theme.of(context).colorScheme.secondary,
                  elevation: 0,
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(FlutterI18n.translate(context, "basic.button.prev")),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: FontSize.larger.value,
                  color: Theme.of(context).colorScheme.primary,
                ),
                Text(
                  FlutterI18n.translate(context, "report.messages.successTitle"),
                  style: TextStyle(fontSize: FontSize.xxLarge.value),
                  textAlign: TextAlign.center,
                ),
                Text(
                  FlutterI18n.translate(context, "report.messages.successSubtitle"),
                  style: TextStyle(fontSize: FontSize.small.value),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 50),
                MaterialButton(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  color: Theme.of(context).colorScheme.primary,
                  elevation: 0,
                  onPressed: () {
                    Navigator.of(context).pop();
                    String data = jsonEncode({"originName": ""});
                    Navigator.of(context).popAndPushNamed('/report/$data');
                  },
                  child: Text(FlutterI18n.translate(context, "report.button.continue")),
                ),
                const SizedBox(height: 20),
                MaterialButton(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  color: Theme.of(context).colorScheme.secondary,
                  elevation: 0,
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(context, "/", (route) => false);
                  },
                  child: Text(FlutterI18n.translate(context, "app.signin.panel.cancelButton")),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
