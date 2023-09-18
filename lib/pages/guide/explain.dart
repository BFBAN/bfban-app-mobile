import 'package:bfban/component/_empty/index.dart';
import 'package:bfban/component/_html/htmlWidget.dart';
import 'package:flutter/material.dart';

import 'package:flutter_elui_plugin/_load/index.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:provider/provider.dart';

import '../../provider/translation_provider.dart';
import '../../utils/http.dart';

class GuideExplainPage extends StatefulWidget {
  const GuideExplainPage({Key? key}) : super(key: key);

  @override
  _ExplainPageState createState() => _ExplainPageState();
}

class _ExplainPageState extends State<GuideExplainPage> with AutomaticKeepAliveClientMixin {
  bool load = false;

  List news = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    getNews();
  }

  /// [Response]
  /// 获取新闻
  getNews() async {
    setState(() {
      load = true;
    });

    Response result = await Http.request(
      "config/news.json",
      httpDioValue: "app_web_site",
      method: Http.GET,
    );

    if (result.data.toString().isNotEmpty) {
      setState(() {
        news = result.data["news"] ??= [];

        for (var element in news) {
          String body = "";
          element["content"].forEach((p) {
            body += "<div>$p</div>";
          });
          element["body"] = body;
        }
      });
    }

    setState(() {
      load = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Consumer<TranslationProvider>(
        builder: (BuildContext context, data, Widget? child) {
          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  bottom: 20,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      FlutterI18n.translate(context, "app.setting.versions.title"),
                      style: const TextStyle(fontSize: 25),
                    ),
                    const SizedBox(width: 10),
                    if (load)
                      ELuiLoadComponent(
                        type: "line",
                        lineWidth: 1,
                        color: Theme.of(context).progressIndicatorTheme.color!,
                        size: 16,
                      ),
                  ],
                ),
              ),
              if (news.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: news.map((i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 35),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    i["username"],
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Opacity(
                                  opacity: .8,
                                  child: Text(i["time"]),
                                )
                              ],
                            ),
                            const SizedBox(height: 5),
                            HtmlWidget(
                              content: i["body"],
                              footerToolBar: false,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                )
              else
                const EmptyWidget()
            ],
          );
        },
      ),
    );
  }
}
