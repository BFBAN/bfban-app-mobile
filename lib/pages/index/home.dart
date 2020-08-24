/// 首页
import 'dart:convert';

import 'package:fluro/fluro.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:bfban/router/router.dart';
import 'package:bfban/utils/index.dart';
import 'package:bfban/widgets/index.dart';
import 'package:bfban/widgets/index/screen.dart';

import 'package:flutter/rendering.dart';
import 'package:flutter_plugin_elui/elui.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// 抽屉
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  /// 滚动
  ScrollController _scrollController = ScrollController();

  /// 举报列表
  Map indexData = new Map();

  List indexDataList = new List();

  Map<String, dynamic> cheatersPost = {
    "game": "",
    "status": 100,
    "sort": "updateDatetime",
    "page": 1,
    "tz": "Asia%2FShanghai",
    "limit": 40,
  };

  bool indexPagesState = true;

  @override
  void initState() {
    super.initState();

    this._getIndexList();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        _getMore();
      }
    });
  }

  /// 获取列表
  void _getIndexList() async {
    setState(() {
      indexPagesState = true;
    });

    Response result = await Http.request(
      'api/cheaters/',
      parame: cheatersPost,
      method: Http.GET,
    );

    setState(() {
      if (result.data["error"] == 0) {
        indexData = result.data;

        if (this.cheatersPost["page"] > 1) {
          result.data["data"].forEach((i) {
            indexDataList.add(i);
          });
        } else {
          indexDataList = result.data["data"];
        }
      } else if (result.data["code"] == -2) {
        EluiMessageComponent.error(context)(
          child: Text("\u8bf7\u6c42\u5f02\u5e38\u8bf7\u8054\u7cfb\u5f00\u53d1\u8005"),
        );
      }
    });

    setState(() {
      indexPagesState = false;
    });
  }

  /// 筛选
  void _setScreenData(Map data) {
    print(data);

    setState(() {
      this.cheatersPost.addAll({
        "page": 1,
        "game": data["game"],
        "status": data["status"],
        "sort": data["sort"],
      });

      _scrollController.animateTo(
        0.0,
        duration: Duration(milliseconds: 500),
        curve: Curves.decelerate,
      );
    });

    this._getIndexList();
  }

  /// 发布举报信息
  Future<VoidCallback> _opEnEdit() async {
    dynamic _login = jsonDecode(await Storage.get('com.bfban.login') ?? '{}');

    if (_login != null && ['admin', 'super'].contains(_login["userPrivilege"])) {
      return () {
        Routes.router.navigateTo(
          context,
          '/edit',
          transition: TransitionType.cupertinoFullScreenDialog,
        );
      };
    } else {
      EluiMessageComponent.error(context)(
        child: Text("\u8bf7\u5148\u767b\u5f55\u0042\u0046\u0042\u0041\u004e"),
      );
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: titleSearch(
          theme: titleSearchTheme.black,
        ),
      ),
      drawerScrimColor: Color(0xff111b2b),
      drawer: indexScreen(
        keyname: _scaffoldKey,
        indexData: indexData,
        onSucceed: (Map data) => this._setScreenData(data),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 1,
            child: !indexPagesState
                ? RefreshIndicator(
                    onRefresh: _onRefresh,
                    color: Colors.white,
                    backgroundColor: Colors.yellow,
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: indexDataList.length,
                      itemBuilder: (BuildContext context, int index) {
                        return CheatListCard(
                          item: indexDataList[index],
                          onTap: () {
                            Routes.router.navigateTo(
                              context,
                              '/detail/cheaters/${indexDataList[index]["originUserId"]}',
                              transition: TransitionType.cupertino,
                            );
                          },
                        );
                      },
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Opacity(
                          opacity: 0.8,
                          child: textLoad(
                            value: "BFBAN",
                            fontSize: 30,
                          ),
                        ),
                        Text(
                          "Legion of BAN Coalition",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white38,
                          ),
                        )
                      ],
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(
          Icons.mode_edit,
          color: Colors.black,
          size: 30,
        ),
        tooltip: "\u53d1\u5e03",
        isExtended: true,
        onPressed: _opEnEdit,
        backgroundColor: Colors.yellow,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
    );
  }

  /// 下拉刷新方法,为list重新赋值
  Future<Null> _onRefresh() async {
    await Future.delayed(Duration(seconds: 1), () {
      this._getIndexList();
    });
  }

  /// 上拉加载更多
  Future _getMore() async {
    await Future.delayed(Duration(seconds: 1), () {
      if (indexPagesState) {
        return;
      }

      setState(() {
        this.cheatersPost["page"] += 1;
      });

      this._getIndexList();
    });
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }
}
