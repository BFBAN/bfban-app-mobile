/// 清理数据
library;

import 'package:bfban/component/_empty/index.dart';
import 'package:bfban/constants/api.dart';
import 'package:flutter/material.dart';

import 'package:bfban/utils/index.dart';

import 'package:flutter_elui_plugin/_cell/cell.dart';
import 'package:flutter_elui_plugin/_input/index.dart';
import 'package:flutter_elui_plugin/_tag/tag.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../component/_refresh/index.dart';

class DestockPage extends StatefulWidget {
  const DestockPage({super.key});

  @override
  DestockPageState createState() => DestockPageState();
}

class DestockPageState extends State<DestockPage> {
  final TextEditingController _searchController = TextEditingController(text: "");

  final FileManagement _fileManagement = FileManagement();

  String destockEnvValue = "all";

  String destockByteValue = "0";

  final DestockStatus _destockStatus = DestockStatus(list: []);

  /// 列表
  final GlobalKey<RefreshState> _refreshKey = GlobalKey<RefreshState>();

  Storage storage = Storage();

  bool selectAll = false;

  @override
  void initState() {
    super.initState();

    _getLocalAll();

    _searchController.addListener(() {
      setState(() {});
    });
  }

  /// [Event]
  /// 获取所有持久数据
  Future _getLocalAll() async {
    List<DestockItemData> list = [];

    storage.getAll().then((storageAll) {
      for (var i in storageAll) {
        DestockItemData destockItemData = DestockItemData();
        destockItemData.setName(i["key"]);
        destockItemData.setValue(i["value"]);
        list.add(destockItemData);
      }

      setState(() {
        _destockStatus.list = list;
      });

      _refreshKey.currentState?.controller.finishRefresh();
      _refreshKey.currentState?.controller.resetFooter();
    });
  }

  /// [Event]
  /// 删除记录
  _removeLocal(DestockItemData e) async {
    String key = e.fullName.split(":")[1];
    await storage.remove(key);
    _getLocalAll();
  }

  /// [Event]
  /// 删除勾选记录
  _removeSelectLocal() {
    // 全选
    if (_destockStatus.list!.length == _destockStatus.list!.where((element) => element.check).length) _removeAllLocal();

    // 单独
    for (var i in _destockStatus.list!) {
      setState(() {
        if (i.check) _removeLocal(i);
      });
    }

    _getLocalAll();
  }

  /// [Event]
  /// 删除所有
  _removeAllLocal() {
    storage.removeAll();
  }

  /// [Data]
  /// 可视列表
  List<DestockItemData> get _getList {
    return _destockStatus.list!
        .where((element) {
          if (destockByteValue == '0') return true;
          return destockByteValue.isNotEmpty && double.parse(destockByteValue) > element.value.toString().length;
        })
        .where((element) {
          if (_searchController.text.isEmpty) return true;
          return _searchController.text.isNotEmpty && element.key!.contains(_searchController.text);
        })
        .where((element) => destockEnvValue == 'all' ? true : destockEnvValue.isNotEmpty && element.env!.contains(destockEnvValue))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(FlutterI18n.translate(context, "app.setting.cleanManagement.title")),
        actions: [
          if (_destockStatus.list!.where((i) => i.check).isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _removeSelectLocal(),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: Size(0, 50),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9),
            child: Row(
              children: [
                Checkbox(
                  value: selectAll,
                  onChanged: (value) {
                    setState(() {
                      selectAll = value!;
                      for (var i in _destockStatus.list!) {
                        i.check = value;
                      }
                    });
                  },
                ),
                VerticalDivider(),
                Flexible(
                  flex: 1,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton(
                      isExpanded: true,
                      dropdownColor: Theme.of(context).bottomAppBarTheme.color,
                      onChanged: (value) {
                        setState(() {
                          destockEnvValue = value.toString();
                        });
                      },
                      value: destockEnvValue,
                      icon: Icon(Icons.filter_alt_outlined),
                      items: ['all', 'development', 'production'].map<DropdownMenuItem<String>>((i) {
                        return DropdownMenuItem(
                          value: i.toString(),
                          child: Text(i.toString()),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 10, child: VerticalDivider()),
                Flexible(
                  flex: 1,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton(
                      isExpanded: true,
                      dropdownColor: Theme.of(context).bottomAppBarTheme.color,
                      onChanged: (value) {
                        setState(() {
                          destockByteValue = value.toString();
                        });
                      },
                      value: destockByteValue,
                      icon: Icon(Icons.filter_alt_outlined),
                      items: [0, 10.0, 600.0, 1000.0].map<DropdownMenuItem<String>>((i) {
                        return DropdownMenuItem(
                          value: i.toString(),
                          child: Text(_fileManagement.onUnitConversion(i).toString()),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Refresh(
        key: _refreshKey,
        onRefresh: _getLocalAll,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Flexible(
              flex: 1,
              child: _getList.isEmpty
                  ? EmptyWidget()
                  : ListView.separated(
                      itemCount: _getList.length,
                      separatorBuilder: (context, index) => Divider(),
                      itemBuilder: (BuildContext context, int index) {
                        var e = _getList[index];

                        return ListTile(
                          isThreeLine: true,
                          leading: Checkbox(
                            value: e.check,
                            visualDensity: VisualDensity.compact,
                            onChanged: (value) {
                              setState(() {
                                e.check = value!;
                              });
                            },
                          ),
                          title: Text("${e.key}"),
                          subtitle: Wrap(
                            spacing: 5,
                            runSpacing: 5,
                            children: [
                              Text(e.fullName),
                              EluiTagComponent(
                                size: EluiTagSize.no2,
                                color: EluiTagType.primary,
                                value: "${e.byes}",
                                onTap: null,
                              ),
                              EluiTagComponent(
                                size: EluiTagSize.no2,
                                color: EluiTagType.primary,
                                value: e.appName,
                                onTap: () {},
                              ),
                              EluiTagComponent(
                                size: EluiTagSize.no2,
                                color: EluiTagType.succeed,
                                value: e.env,
                                onTap: () {},
                              ),
                            ],
                          ),
                          trailing: TextButton(
                            onPressed: () => _removeLocal(e),
                            child: const Icon(Icons.delete),
                          ),
                        );

                        return Row(
                          children: [
                            Checkbox(
                              value: e.check,
                              visualDensity: VisualDensity.compact,
                              onChanged: (value) {
                                setState(() {
                                  e.check = value!;
                                });
                              },
                            ),
                            Expanded(
                              flex: 1,
                              child: SelectionArea(
                                child: EluiCellComponent(
                                  title: "${e.key}",
                                  label: e.fullName,
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                            TextButton(
                              onPressed: () => _removeLocal(e),
                              child: const Icon(Icons.delete),
                            ),
                            const SizedBox(width: 5),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class DestockStatus {
  List<DestockItemData>? list;

  DestockStatus({this.list});
}

class DestockItemData {
  FileManagement _fileManagement = FileManagement();

  bool check;
  String? env;
  String? appName;
  String? key;
  dynamic value;
  String byes;
  String fullName = "";

  DestockItemData({
    this.check = false,
    this.env,
    this.appName,
    this.key,
    this.value,
    this.byes = "-",
  });

  setName(String value) {
    List<String> a = value.split(":");
    List envAndAppName = a[0].split(".");
    String key = a[1];

    fullName = value;
    env = envAndAppName[1];
    appName = envAndAppName[0];
    this.key = key.replaceAll(".", " ").toUpperCase();
  }

  setValue(dynamic value) {
    this.value = value;
    byes = _fileManagement.onUnitConversion(this.value.toString().length);
  }
}
