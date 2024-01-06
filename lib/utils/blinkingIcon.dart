import 'package:flutter/material.dart';



class BlinkingIcon extends StatefulWidget {
  final bool _isDeviceCompatible;
  BlinkingIcon(this._isDeviceCompatible);

  @override
  _BlinkingIconState createState() => _BlinkingIconState();
}



class _BlinkingIconState extends State<BlinkingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: Duration(seconds: 1))
          ..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animationController,
      child: Icon(
                Icons.car_repair,
                size: 50,
                color: widget._isDeviceCompatible
                    ? Colors.black.withOpacity(0.1)
                    : Colors.red.withOpacity(0.5),
              ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
