import 'package:flutter/material.dart';

/// 游戏类型单选
class GameTypeRadioWidget extends StatelessWidget {
  final Widget? child;
  final bool index;
  final bool errorHint;
  final GestureTapCallback? onTap;

  const GameTypeRadioWidget({
    Key? key,
    this.child,
    this.index = false,
    this.errorHint = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
          side: BorderSide(
            color: !errorHint ? Theme.of(context).colorScheme.error : Theme.of(context).dividerTheme.color!,
            width: 1,
          ),
        ),
        elevation: 0,
        color: index ? const Color(0xff364e80) : Theme.of(context).sliderTheme.disabledActiveTickMarkColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          child: child!,
        ),
      ),
    );
  }
}
