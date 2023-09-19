import 'package:flutter/material.dart';

import 'widget/filter_empty_widget.dart';

import 'theme.dart';
import 'class.dart';
import 'actions.dart';
import 'framework.dart';

export 'widget/filter_empty_widget.dart';
export 'widget/filter_radio_list.dart';

/// S 筛选 对外提供
class Filter extends StatefulWidget {
  final Widget? child;
  final List<FilterItemWidget>? slot;
  final int? initialIndex;
  final FilterTheme? theme;
  final Function? onChange;
  final Function? onReset;
  final Function? onShow;
  final Function? onHide;
  final double? minHeight;
  final double? maxHeight;
  final List<Widget>? actions;
  final bool? isMask;
  final Color? maskColor;
  final bool? suckTop;

  const Filter({
    Key? key,
    this.child,
    required this.slot,
    this.initialIndex,
    this.theme,
    this.onChange,
    this.onReset,
    this.onShow,
    this.onHide,
    this.maxHeight = 300,
    this.minHeight = 0,
    this.actions,
    this.isMask = true,
    this.maskColor,
    this.suckTop = false,
  }) : super(key: key);

  @override
  FilterState createState() => FilterState();
}

class FilterState extends State<Filter> {
  final GlobalKey _containerKey = GlobalKey();

  /// 筛选的下标
  int? _selectIndex;

  /// 筛选布局的高度
  double selectHeight = 0;

  /// 面板列表 数据对应
  List<FilterItem> filterItem = [];
  List<GlobalKey<State>> filterItemPanelKey = [];
  List<GlobalKey<_FilterTitleWidgetState>> filterItemKey = [];

  @override
  void initState() {
    _updateWidget();
    super.initState();
  }

  @override
  didUpdateWidget(oldWidget) {
    // 初始展开的面板
    if (widget.initialIndex != null) {
      _selectIndex = widget.initialIndex;
      _onUpdateItemState(true, index: _selectIndex);
    }
    selectHeight = _containerKey.currentContext!.findRenderObject()!.semanticBounds.size.height;
    super.didUpdateWidget(oldWidget);
  }

  @override
  didChangeDependencies() {
    _updateWidget();
    super.didChangeDependencies();
  }

  /// [Event]
  /// 更新试图
  _updateWidget() {
    late int _index = 0;
    filterItem.clear();

    // 生成key，以便通过key操作
    for (var i in widget.slot!) {
      GlobalKey<_FilterTitleWidgetState> titleKey = GlobalKey();

      filterItemKey.add(titleKey);

      filterItem.add(
        FilterItem(
          name: _index.toString(),
          title: FilterTitleWidget(
            title: i.title,
            key: titleKey,
            index: _index++,
            tabCount: filterItem.length,
          )
            ..icon = i.icon!
            ..isIcon = i.isIcon!,
          panel: i.panel,
        ),
      );
    }

    filterItem.asMap().keys.forEach((index) {
      var element = filterItem[index];
      if (element.panel != null) {
        element.panel!
          ..filterAll = filterItem
          ..show = show
          ..hide = hidden;
      }
    });
  }

  /// [Event]
  /// item.title 内部状态更新
  _onUpdateItemState(_is, {index}) {
    for (var key in filterItemKey) {
      // 更新内部状态
      if (key.currentState == null) continue;
      key.currentState!.widget.stateSetter_!(() {
        // 没有对应index（对象）, 则都收起状态
        if (index == null) {
          key.currentState!.showPanel = false;
          // continue;
        }

        key.currentState!.showPanel = !_is ? _is : index == key.currentState!.widget.index;
      });
    }
  }

  /// [Event]
  /// 重置面板
  _onRefreshSelect() {
    widget.onHide != null ? widget.onHide!() : null;

    setState(() {
      _selectIndex = null;
    });
  }

  /// [Event]
  /// 展开对应面板
  _onSelectChange(int index) {
    widget.onShow != null ? widget.onShow!() : null;

    if (_selectIndex == index) {
      _onUpdateItemState(false);
      _onRefreshSelect();
      return;
    }

    setState(() {
      _selectIndex = index;
    });

    _onUpdateItemState(true, index: index);
  }

  /// [Event]
  /// 获取结果
  void _getData() {
    Map values = {};

    filterItem.forEach((element) {
      values[element.panel!.data!.name] = element.panel!.data!.value!;
    });

    widget.onChange != null ? widget.onChange!(values) : null;
  }

  /// [Event]
  /// 展开
  show(String name) {
    // 内部的name未设置是index， 如果设置了应当使用内部的name
    filterItem.asMap().keys.forEach((index) {
      dynamic element = filterItem[index];
      if (element.name == name) {
        // 展开对应面板
        _onSelectChange(index);
      }
    });
  }

  /// [Event]
  /// 收起
  void hidden() {
    _onRefreshSelect();
    _onUpdateItemState(false);
  }

  /// [Event]
  /// 主动更新
  void updataFrom() {
    _getData();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Container(
          margin: EdgeInsets.only(top: widget.suckTop! ? 0 : selectHeight),
          child: widget.child!,
        ),
        // mask
        Visibility(
          visible: widget.isMask! && _selectIndex != null,
          child: Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            child: GestureDetector(
              child: Container(
                color: Theme.of(context).primaryColor.withOpacity(.5),
                width: double.infinity,
                height: double.infinity,
              ),
              onTap: () {
                hidden();
              },
            ),
          ),
        ),
        // 筛选头
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Builder(
            builder: (context) => Container(
              key: _containerKey,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              constraints: BoxConstraints(
                minHeight: selectHeight,
              ),
              color: Theme.of(context).scaffoldBackgroundColor,
              child: ClipRect(
                clipBehavior: Clip.hardEdge,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: filterItem.asMap().keys.map<Widget>((index) {
                    FilterItem item = filterItem[index];
                    return GestureDetector(
                      child: item.title!,
                      onTap: () => _onSelectChange(index),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
        // 内容面板
        Visibility(
          visible: _selectIndex != null,
          maintainState: true,
          maintainAnimation: true,
          child: AnimatedOpacity(
            opacity: _selectIndex != null ? 1.0 : 0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              margin: EdgeInsets.only(top: selectHeight),
              constraints: BoxConstraints(
                maxHeight: widget.maxHeight!,
                minHeight: widget.minHeight!,
              ),
              child: Column(
                children: [
                  // 内容卡槽
                  Flexible(
                    flex: 1,
                    child: Container(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      child: IndexedStack(
                        sizing: StackFit.loose,
                        index: _selectIndex,
                        children: filterItem.asMap().keys.map<Widget>((index) {
                          FilterItem item = filterItem[index];

                          item.panel ??= emptyFilter(
                            child: Container(),
                          );

                          return item.panel!;
                        }).toList(),
                      ),
                    ),
                  ),
                  // 按钮组
                  Container(
                    child: widget.actions == null
                        ? actionsFilterWidget(
                            onChange: () {
                              _getData();
                              hidden();
                            },
                            onReset: () {
                              widget.onReset!();
                            },
                          )
                        : Row(
                            children: widget.actions!,
                          ),
                  )
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// E 筛选 对外提供
/// S 筛选标题 对外使用
class FilterItemWidget extends StatelessWidget {
  final Widget? title;
  final String? name;
  final FilterPanelWidget? panel;
  late FilterIcon? icon = FilterIcon();
  late bool? isIcon = true;

  FilterItemWidget({
    Key? key,
    this.title,
    this.name,
    this.panel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class FilterIcon {
  final IconData? up;
  final IconData? down;
  final Color? color;
  final Color? selectedColor;

  FilterIcon({
    this.up,
    this.down,
    this.color,
    this.selectedColor,
  });
}

/// E 筛选标题 对外使用
/// S 筛选标题 内部使用
class FilterTitleWidget extends StatefulWidget {
  // 标题
  final Widget? title;

  // 展存index
  final int? index;

  final int? tabCount;

  // 内部StateSetter
  StateSetter? stateSetter_;

  late FilterIcon icon;
  late bool isIcon;

  FilterTitleWidget({
    Key? key,
    this.title,
    this.index,
    this.tabCount,
  }) : super(key: key);

  @override
  _FilterTitleWidgetState createState() => _FilterTitleWidgetState();
}

class _FilterTitleWidgetState extends State<FilterTitleWidget> {
  late bool showPanel = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Container(
          margin: const EdgeInsets.only(right: 5),
          constraints: BoxConstraints(maxWidth: (MediaQuery.of(context).size.width / widget.tabCount!) - 30),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                width: 2,
                color: showPanel ? Colors.white : Colors.transparent,
              ),
            ),
          ),
          child: widget.title,
        ),
        widget.isIcon
            ? StatefulBuilder(
                builder: (BuildContext context, StateSetter stateSetter) {
                  widget.stateSetter_ = stateSetter;
                  IconData? up = Icons.keyboard_arrow_up;
                  IconData? down = Icons.keyboard_arrow_down;

                  if (widget.icon.up != null) up = widget.icon.up;
                  if (widget.icon.down != null) up = widget.icon.down;

                  return Container(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(!showPanel ? up : down, size: 13),
                  );
                },
              )
            : const ClipPath(),
      ],
    );
  }
}

/// E 筛选标题 内部使用
