import 'package:bfban/component/_empty/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_elui_plugin/_load/index.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../constants/api.dart';
import '../../data/index.dart';
import '../../utils/index.dart';
import '../../widgets/detail/appeal_card.dart';
import '../../widgets/detail/cheat_reports_card.dart';
import '../../widgets/detail/cheat_user_cheaters_card.dart';
import '../../widgets/detail/history_name_card.dart';
import '../../widgets/detail/judgement_card.dart';

class TimeLine extends StatefulWidget {
  final PlayerStatus playerStatus;

  const TimeLine({
    Key? key,
    required this.playerStatus,
  }) : super(key: key);

  @override
  State<TimeLine> createState() => TimeLineState();
}

class TimeLineState extends State<TimeLine> with AutomaticKeepAliveClientMixin {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  ScrollController scrollController = ScrollController();

  /// 时间轴
  PlayerTimelineStatus playerTimelineStatus = PlayerTimelineStatus(
    total: 0,
    pageNumber: 1,
    list: [],
    load: false,
    parame: PlayerTimelineParame(
      skip: 0,
      limit: 20,
      personaId: "",
    ),
  );

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    playerTimelineStatus.parame.personaId = widget.playerStatus.data!.toMap["originPersonaId"];

    // 滚动视图初始
    scrollController.addListener(() {
      if (scrollController.position.pixels == scrollController.position.maxScrollExtent) {
        _getMore();
      }
    });

    getTimeline();

    super.initState();
  }

  /// [Response]
  /// 获取时间轴
  Future getTimeline() async {
    if (playerTimelineStatus.load!) return;

    // Future.delayed(const Duration(seconds: 0), () {
    //   _refreshIndicatorKey.currentState!.show();
    // });

    setState(() {
      playerTimelineStatus.load = true;
    });

    Response result = await Http.request(
      Config.httpHost["player_timeline"],
      parame: playerTimelineStatus.parame.toMap,
      method: Http.GET,
    );

    if (result.data["success"] == 1) {
      Map d = result.data["data"];

      setState(() {
        if (playerTimelineStatus.parame.skip! <= 0) {
          playerTimelineStatus.list = d["result"];
          _onMergeHistoryName();
        } else {
          if (d["result"].isNotEmpty && playerTimelineStatus.parame.skip! <= playerTimelineStatus.parame.limit!) {
            playerTimelineStatus.list?.add({
              "pageTip": true,
              "pageIndex": playerTimelineStatus.pageNumber!,
            });
            playerTimelineStatus.pageNumber = playerTimelineStatus.pageNumber! + 1;
            _onMergeHistoryName();
          }

          // 追加数据
          if (d["result"].isNotEmpty) {
            playerTimelineStatus.list!.addAll(d["result"]);
            playerTimelineStatus.list!.add({
              "pageTip": true,
              "pageIndex": playerTimelineStatus.pageNumber!,
            });
            playerTimelineStatus.pageNumber = playerTimelineStatus.pageNumber! + 1;
            _onMergeHistoryName();
          }
        }
        playerTimelineStatus.total = d["total"];
      });
    }

    setState(() {
      playerTimelineStatus.load = false;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// [Event]
  /// 合并时间轴历史名称
  void _onMergeHistoryName() {
    List? timelineList = List.from(playerTimelineStatus.list!);
    List? history = widget.playerStatus.data!.history;

    if (timelineList.isEmpty) return;

    // 处理历史名称，放置对应对应位置
    for (int hisrotyIndex = 0; hisrotyIndex < history!.length; hisrotyIndex++) {
      num nameHistoryTime = DateTime.parse(history[hisrotyIndex]["fromTime"]).millisecondsSinceEpoch;
      num prevNameTimeListTime = 0;
      num nameTimeListTime = 0;

      for (int timeLineIndex = 0; timeLineIndex < timelineList.length; timeLineIndex++) {
        if (timeLineIndex > 0 && timelineList[timeLineIndex - 1].containsKey("createTime")) {
          prevNameTimeListTime = DateTime.parse(timelineList[timeLineIndex - 1]["createTime"]).millisecondsSinceEpoch;
        }
        nameTimeListTime = timelineList[timeLineIndex]["createTime"] != null ? DateTime.parse(timelineList[timeLineIndex]["createTime"]).millisecondsSinceEpoch : 0;

        // 历史名称的记录大于1，history内表示举报提交时初始名称，不应当放进timeline中
        // 索引自身历史修改日期位置，放入timeline中
        if (hisrotyIndex >= 1 && timelineList[timeLineIndex]["type"] != "historyUsername" && nameHistoryTime >= prevNameTimeListTime && nameHistoryTime <= nameTimeListTime) {
          timelineList.insert(timeLineIndex, {
            "type": "historyUsername",
            "beforeUsername": history[hisrotyIndex - 1]["originName"],
            "nextUsername": history[hisrotyIndex]["originName"],
            "fromTime": history[hisrotyIndex]["fromTime"],
          });
          break;
        } else if (hisrotyIndex >= 1 && hisrotyIndex == history.length - 1 && timelineList[timeLineIndex]["type"] != 'historyUsername' && nameHistoryTime >= nameTimeListTime) {
          timelineList.add({
            "type": "historyUsername",
            "beforeUsername": history[hisrotyIndex - 1]["originName"],
            "nextUsername": history[hisrotyIndex]["originName"],
            "fromTime": history[hisrotyIndex]["fromTime"],
          });
          break;
        }
      }
    }

    setState(() {
      playerTimelineStatus.list = timelineList;
    });
  }

  /// [Event]
  /// 评论内回复
  void _onReplySucceed(value) async {
    if (value == null) {
      return;
    }
    scrollController.jumpTo(scrollController.position.maxScrollExtent);
  }

  /// [Event]
  /// 作弊玩家时间轴 刷新
  Future<void> _onRefreshTimeline() async {
    playerTimelineStatus.parame.resetPage();
    await getTimeline();
  }

  /// [Event]
  /// 下拉加载
  Future<void> _getMore() async {
    playerTimelineStatus.parame.nextPage(count: playerTimelineStatus.parame.limit!);
    await getTimeline();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(
      key: _refreshIndicatorKey,
      edgeOffset: MediaQuery.of(context).padding.top,
      onRefresh: _onRefreshTimeline,
      child: ListView(
        controller: scrollController,
        children: playerTimelineStatus.list!.isNotEmpty
            ? playerTimelineStatus.list!.asMap().entries.map((data) {
                int index = data.key;
                num maxDataCount = playerTimelineStatus.list!.length;

                if (data.key < playerTimelineStatus.list!.length) {
                  var timeLineItem = data.value;

                  // 分页提示
                  if (timeLineItem["pageTip"] != null) {
                    return Column(
                      children: [
                        if (index > 0 && index < playerTimelineStatus.list!.length - 1) const Divider(height: 1),
                        Row(
                          children: [
                            if (index > 0 && index < playerTimelineStatus.list!.length - 1)
                              Container(
                                margin: const EdgeInsets.only(left: 29, right: 28),
                                width: 2,
                                height: 35,
                              ),
                            Center(
                              child: Wrap(
                                children: [
                                  const Icon(Icons.tag, size: 17),
                                  Text(
                                    FlutterI18n.translate(context, "app.home.paging", translationParams: {"num": "${timeLineItem["pageIndex"]}"}),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Theme.of(context).textTheme.bodyMedium?.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      ],
                    );
                  }

                  switch (timeLineItem["type"]) {
                    case "reply":
                      // 回复
                      return CheatUserCheatersCard(
                        onReplySucceed: _onReplySucceed,
                      )
                        ..maxDataCount = maxDataCount
                        ..data = timeLineItem
                        ..index = index + 1;
                    case "report":
                      // 举报卡片
                      return CheatReportsCard(
                        onReplySucceed: _onReplySucceed,
                      )
                        ..maxDataCount = maxDataCount
                        ..data = timeLineItem
                        ..index = index + 1;
                    case "judgement":
                      // 举报
                      return JudgementCard()
                        ..maxDataCount = maxDataCount
                        ..data = timeLineItem
                        ..index = index + 1;
                    case "banAppeal":
                      // 申诉
                      return AppealCard(
                        onReplySucceed: _onReplySucceed,
                      )
                        ..maxDataCount = maxDataCount
                        ..data = timeLineItem
                        ..index = index + 1;
                    case "historyUsername":
                      return HistoryNameCard()
                        ..maxDataCount = maxDataCount
                        ..data = timeLineItem
                        ..index = index + 1;
                  }
                }

                return Container();
              }).toList()
            : [
                playerTimelineStatus.load!
                    ? Container(
                        margin: const EdgeInsets.only(top: 30),
                        child: ELuiLoadComponent(
                          type: "line",
                          lineWidth: 3,
                          color: Theme.of(context).textTheme.displayMedium!.color!,
                          size: 28,
                        ),
                      )
                    : const EmptyWidget(),
              ],
      ),
    );
  }
}
