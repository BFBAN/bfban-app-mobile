import 'package:bfban/component/_Time/index.dart';
import 'package:bfban/component/_empty/index.dart';
import 'package:flutter/material.dart';

import 'package:bfban/constants/api.dart';
import 'package:flutter_elui_plugin/elui.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../component/_privilegesTag/index.dart';
import '../../data/index.dart';
import '../../utils/index.dart';
import '../../widgets/index.dart';
import '../not_found/index.dart';

class UserSpacePage extends StatefulWidget {
  // users Db id
  late String? id;

  UserSpacePage({
    Key? key,
    required this.id,
  }) : super(key: key);

  @override
  UserSpacePageState createState() => UserSpacePageState();
}

class UserSpacePageState extends State<UserSpacePage> {
  final UrlUtil _urlUtil = UrlUtil();

  /// 异步
  Future? futureBuilder;

  final ScrollController _scrollController = ScrollController();

  /// 用户信息
  StationUserSpaceStatus userSpaceInfo = StationUserSpaceStatus(
    data: StationUserSpaceData(),
    parame: StationUserSpaceParame(
      id: null,
      limit: 20,
      skip: 0,
    ),
    load: false,
  );

  /// 用户举报列表
  ReportListStatus reportListStatus = ReportListStatus(
    load: false,
    list: [],
    parame: ReportListStatusParame(
      id: null,
      limit: 20,
      skip: 0,
    ),
  );

  bool reportListNextEmpty = false;

  GlobalKey appBarKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        _getMore();
      }
    });

    ready();
  }

  @override
  void dispose() {
    userSpaceInfo.data = StationUserSpaceData();
    super.dispose();
  }

  void ready() async {
    // Update query id
    userSpaceInfo.parame.id = widget.id!;
    reportListStatus.parame.id = int.parse(widget.id!);

    futureBuilder = _getUserSpaceInfo();
  }

  /// [Response]
  /// 获取站内用户数据
  Future _getUserSpaceInfo() async {
    setState(() {
      userSpaceInfo.load = true;
    });

    Response result = await Http.request(
      Config.httpHost["user_info"],
      parame: userSpaceInfo.parame.toMap,
      method: Http.GET,
    );

    if (result.data["success"] == 1) {
      final d = result.data["data"];
      _getSiteUserReports();

      setState(() {
        userSpaceInfo.data.setData(d);
      });
    }

    setState(() {
      userSpaceInfo.load = false;
    });

    return userSpaceInfo.data.toMap;
  }

  /// [Response]
  /// 获取用户举报列表
  Future _getSiteUserReports() async {
    setState(() {
      reportListStatus.load = true;
    });

    Response result = await Http.request(
      Config.httpHost["user_reports"],
      parame: reportListStatus.parame.toMap,
      method: Http.GET,
    );

    if (result.data["success"] == 1) {
      List d = result.data["data"];

      if (!mounted) return;
      setState(() {
        if (d.isEmpty) {
          reportListNextEmpty = true;
        }

        if (d.isNotEmpty) reportListStatus.list = d;
      });
    }

    setState(() {
      reportListStatus.load = false;
    });
  }

  /// [Event]
  /// 作弊玩家信息 刷新
  Future<void> _onRefresh() async {
    setState(() {
      reportListStatus.list = [];
      reportListStatus.parame.resetPage();
    });

    await _getSiteUserReports();
  }

  /// [Event]
  /// 下拉 追加数据
  Future _getMore() async {
    if (reportListStatus.load! && reportListNextEmpty) return;

    reportListStatus.parame.nextPage();
    await _getSiteUserReports();
  }

  /// [Event]
  /// 聊天
  _openMessage(String id) async {
    Map localLoginUserInfo = ProviderUtil().ofUser(context).userinfo;
    if (localLoginUserInfo["userId"].toString() == id) {
      EluiMessageComponent.warning(context)(child: Text(FlutterI18n.translate(context, "account.message.hint.selfTalk")));
      return;
    }

    if (userSpaceInfo.data.attr!.allowDM! == false) {
      EluiMessageComponent.warning(context)(child: Text(FlutterI18n.translate(context, "account.message.hint.taOffChat")));
      return;
    }

    return () {
      _urlUtil.opEnPage(context, "/chat/$id");
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: futureBuilder,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        /// 数据未加载完成时
        switch (snapshot.connectionState) {
          case ConnectionState.done:
            if (snapshot.data == null) {
              return const NotFoundPage();
            }

            return Scaffold(
              extendBodyBehindAppBar: true,
              appBar: AppBar(
                key: appBarKey,
                backgroundColor: Colors.transparent,
                title: snapshot.data["username"] != null
                    ? Column(
                        children: [
                          Text(snapshot.data["username"]),
                          Text(
                            snapshot.data["id"],
                            style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.displayMedium!.color),
                          ),
                        ],
                      )
                    : I18nText("account.title", child: const Text("")),
                centerTitle: true,
                actions: [
                  PopupMenuButton(
                    onSelected: (value) {
                      switch (value) {
                        case 1:
                          _openMessage(userSpaceInfo.data.id.toString());
                          break;
                        case 2:
                          break;
                      }
                    },
                    itemBuilder: (context) {
                      return [
                        PopupMenuItem(
                          value: 1,
                          child: Wrap(
                            children: [
                              const Icon(Icons.message),
                              const SizedBox(width: 10),
                              Text(FlutterI18n.translate(context, "account.message.chat")),
                            ],
                          ),
                        ),
                      ];
                    },
                  ),
                ],
              ),
              body: RefreshIndicator(
                onRefresh: _onRefresh,
                displacement: 120,
                edgeOffset: MediaQuery.of(context).viewInsets.top,
                child: ListView(
                  controller: _scrollController,
                  padding: EdgeInsets.zero,
                  children: <Widget>[
                    Stack(
                      children: [
                        Positioned(
                          child: Opacity(
                            opacity: .3,
                            child: Container(
                              constraints: const BoxConstraints(
                                minHeight: 150,
                                maxHeight: 300,
                              ),
                              width: MediaQuery.of(context).size.width,
                              child: ShaderMask(
                                blendMode: BlendMode.dstIn,
                                shaderCallback: (Rect bounds) {
                                  return const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Colors.black, Colors.transparent],
                                  ).createShader(Rect.fromLTRB(0, 0, bounds.width, bounds.height));
                                },
                                child: (snapshot.data["userAvatar"] != null && snapshot.data["userAvatar"].isNotEmpty)
                                    ? EluiImgComponent(
                                        src: snapshot.data["userAvatar"].toString(),
                                        fit: BoxFit.fitWidth,
                                        width: MediaQuery.of(context).size.width,
                                        height: 350,
                                      )
                                    : Image.asset(
                                        "assets/images/default-player-avatar.jpg",
                                        fit: BoxFit.fitWidth,
                                      ),
                              ),
                            ),
                          ),
                        ),
                        SafeArea(
                          bottom: false,
                          right: false,
                          left: false,
                          child: Container(
                            width: MediaQuery.of(context).size.width,
                            margin: const EdgeInsets.only(
                              top: 20,
                              left: 15,
                              right: 15,
                            ),
                            child: Card(
                              margin: EdgeInsets.zero,
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Wrap(
                                  spacing: 40,
                                  runSpacing: 25,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(50),
                                      child: CircleAvatar(
                                        radius: 30,
                                        child: (snapshot.data["userAvatar"] != null && snapshot.data["userAvatar"].isNotEmpty)
                                            ? Image.network(snapshot.data["userAvatar"])
                                            : Text(
                                                snapshot.data["username"][0].toString().toUpperCase(),
                                                style: const TextStyle(fontSize: 25),
                                              ),
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Opacity(
                                          opacity: .5,
                                          child: Text(
                                            FlutterI18n.translate(context, "account.role"),
                                            style: const TextStyle(fontSize: 20),
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        PrivilegesTagWidget(data: snapshot.data["privilege"]),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Opacity(
                                          opacity: .5,
                                          child: Text(
                                            FlutterI18n.translate(context, "account.joinedAt"),
                                            style: const TextStyle(fontSize: 20),
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        TimeWidget(
                                          data: snapshot.data["joinTime"],
                                          style: const TextStyle(fontSize: 18),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Opacity(
                                          opacity: .5,
                                          child: Text(
                                            FlutterI18n.translate(context, "account.lastOnlineTime"),
                                            style: const TextStyle(fontSize: 20),
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        TimeWidget(
                                          data: snapshot.data["lastOnlineTime"],
                                          style: const TextStyle(fontSize: 18),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Opacity(
                                          opacity: .5,
                                          child: Text(
                                            FlutterI18n.translate(context, "account.reportNum"),
                                            style: const TextStyle(fontSize: 20),
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          snapshot.data["reportnum"].toString(),
                                          style: const TextStyle(fontSize: 18),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // 举报列表
                    if (reportListStatus.list.isNotEmpty)
                      Column(
                        children: reportListStatus.list.map((ReportListPlayerData item) {
                          return CheatListCard(
                            item: item.toMap,
                            isIconHotView: false,
                            isIconCommendView: false,
                            isIconView: false,
                          );
                        }).toList(),
                      )
                    else if (reportListStatus.list.isEmpty && reportListStatus.load!)
                      Container(
                        margin: const EdgeInsets.only(top: 20),
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else
                      const EmptyWidget()
                  ],
                ),
              ),
            );
          default:
            return Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: true,
              ),
              body: const Center(
                child: CircularProgressIndicator(),
              ),
            );
        }
      },
    );
  }
}
