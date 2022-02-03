/// 版本

import 'package:flutter/material.dart';
import 'package:flutter_elui_plugin/_cell/cell.dart';
import 'package:flutter_elui_plugin/_tag/tag.dart';
import 'package:flutter_elui_plugin/_tip/index.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:provider/provider.dart';

import '../../constants/api.dart';
import '../../provider/package_provider.dart';
import '../../utils/index.dart';

class AppPackagePage extends StatefulWidget {
  const AppPackagePage({Key? key}) : super(key: key);

  @override
  _AppPackagePageState createState() => _AppPackagePageState();
}

class _AppPackagePageState extends State<AppPackagePage> {
  final UrlUtil _urlUtil = UrlUtil();

  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(translate("setting.versions.title")),
        actions: [
          IconButton(
            onPressed: () {
              _urlUtil.opEnPage(context, "/network");
            },
            icon: const Icon(Icons.electrical_services),
          ),
        ],
      ),
      body: Consumer<PackageProvider>(
        builder: (BuildContext context, data, child) {
          return RefreshIndicator(
            onRefresh: data.getOnlinePackage,
            child: Column(
              children: [
                Card(
                  child: EluiCellComponent(
                    title: translate("setting.versions.currentVersion"),
                    cont: Text(data.currentVersion.toString()),
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                ),
                Card(
                  child: EluiCellComponent(
                    title: translate("setting.versions.newVersion"),
                    label: data.isNewVersion ? translate("setting.versions.newVersionDescribe_new") : translate("setting.versions.newVersionDescribe_old"),
                    theme: EluiCellTheme(labelColor: Theme.of(context).textTheme.subtitle2!.color),
                    islink: true,
                    cont: data.onlineVersion.isNotEmpty ? Text(data.onlineVersion.toString()) : const CircularProgressIndicator(strokeWidth: 2),
                    onTap: () {
                      _urlUtil.onPeUrl(Config.apiHost["web_site"]);
                    },
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                ),
                const SizedBox(height: 10),
                data.list
                        .where((i) {
                          return data.setIssue(i["version"], i["stage"]) == data.currentVersion;
                        })
                        .toList()
                        .isEmpty
                    ? SizedBox(
                        height: 50,
                        child: EluiTipComponent(
                          type: EluiTip.warning,
                          child: Text(translate("setting.versions.superHairVersionTip")),
                        ),
                      )
                    : Container(),
                const SizedBox(height: 10),
                Expanded(
                  flex: 1,
                  child: ListView(
                    children: data.list.map((e) {
                      return ListTile(
                        title: Wrap(
                          runAlignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(e["version"].toString()),
                            const SizedBox(width: 10),
                            EluiTagComponent(
                              value: "${translate("setting.versions.type")}: ${e["stage"].toUpperCase()}",
                              color: EluiTagType.none,
                              size: EluiTagSize.no2,
                              theme: EluiTagTheme(
                                backgroundColor: Theme.of(context).backgroundColor,
                                borderColor: Theme.of(context).backgroundColor,
                              ),
                            ),
                            const SizedBox(width: 10),
                            data.setIssue(e["version"], e["stage"]) == data.currentVersion
                                ? EluiTagComponent(
                                    value: "当前版本",
                                    color: EluiTagType.none,
                                    size: EluiTagSize.no2,
                                    theme: EluiTagTheme(
                                      backgroundColor: Theme.of(context).appBarTheme.backgroundColor!,
                                    ),
                                  )
                                : Container(),
                          ],
                        ),
                        subtitle: Text(e["describe"].toString()),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          _urlUtil.onPeUrl(e["src"]);
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
