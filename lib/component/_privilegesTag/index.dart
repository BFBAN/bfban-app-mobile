import 'package:bfban/utils/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

class PrivilegesTagWidget extends StatefulWidget {
  List<dynamic>? data;

  PrivilegesTagWidget({
    Key? key,
    this.data,
  }) : super(key: key);

  @override
  State<PrivilegesTagWidget> createState() => _PrivilegesTagWidgetState();
}

class _PrivilegesTagWidgetState extends State<PrivilegesTagWidget> {
  final ProviderUtil _providerUtil = ProviderUtil();

  List? privileges = [
    {"value": "normal"}
  ];

  @override
  void initState() {
    super.initState();
    dynamic originalPrivilege = _providerUtil.ofApp(context).conf.data.privilege!;

    if (originalPrivilege["child"] != null && widget.data!.isNotEmpty) {
      List privilegeArray = List.from(originalPrivilege!["child"]).where((i) {
        return widget.data!.isEmpty ? originalPrivilege.contains(i["value"]) : widget.data!.contains(i["value"]);
      }).toList();

      setState(() {
        privileges = privilegeArray;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      runSpacing: 5,
      spacing: 5,
      children: privileges!.isNotEmpty
          ? privileges!.map<Widget>((i) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  border: Border.all(color: Theme.of(context).dividerTheme.color!),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  FlutterI18n.translate(context, "basic.privilege.${i["value"]}"),
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).hintColor,
                  ),
                ),
              );
            }).toList()
          : [],
    );
  }
}
