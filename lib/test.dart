import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class IncomingCall extends StatefulWidget {
  const IncomingCall({Key? key}) : super(key: key);

  @override
  State<IncomingCall> createState() => _IncomingCallState();
}

class _IncomingCallState extends State<IncomingCall>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
    );
    //_startAnimation();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.blue,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 60, bottom: 20),
              child: Text("Test",
                  style: TextStyle(color: Colors.white, fontSize: 20, decorationStyle: TextDecorationStyle.wavy)),
            ),
            SizedBox(
              height: 250,
              width: 250,
              child: Stack(
                children: [
                  SpinKitPulse(
                    color: Colors.white,
                    size: 250,
                    controller: AnimationController(
                        vsync: this,
                        duration:
                        const Duration(milliseconds: 1500)),
                  ),
                  const Center(
                    child: SizedBox(
                      width: 180,
                      height: 180,
                      child: CircleAvatar(
                        backgroundImage:
                            NetworkImage('https://picsum.photos/id/237/200/250'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Text("Name: abcxyz",
                style: TextStyle(color: Colors.white, fontSize: 25)),
            const Padding(
              padding: EdgeInsets.all(10),
              child: Text("Incoming call",
                  style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
            Expanded(
              child: Container(
                alignment: AlignmentDirectional.bottomEnd,
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 60, horizontal: 40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            child: Center(
                              child: RawMaterialButton(
                                onPressed: () {},
                                elevation: 2.0,
                                fillColor: Colors.red,
                                child: Icon(
                                  Icons.call_end,
                                  size: 35.0,
                                  color: Colors.white,
                                ),
                                padding: EdgeInsets.all(15.0),
                                shape: CircleBorder(),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(5),
                            child: Text(
                              "Decline",
                              style: TextStyle(color: Colors.white, fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 60, horizontal: 40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            child: Stack(
                              children: <Widget>[
                                SpinKitPulse(
                                  color: Colors.white,
                                  size: 120,
                                  controller: AnimationController(
                                      vsync: this,
                                      duration:
                                          const Duration(milliseconds: 1500)),
                                ),
                                Center(
                                  child: RawMaterialButton(
                                    onPressed: () {
                                    },
                                    elevation: 2.0,
                                    fillColor: Colors.green,
                                    padding: const EdgeInsets.all(15.0),
                                    shape: const CircleBorder(),
                                    child: const Icon(
                                      Icons.call,
                                      size: 35.0,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(5),
                            child: Text(
                              "Accept",
                              style: TextStyle(color: Colors.white, fontSize: 15),
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class SpritePainter extends CustomPainter {
  final Animation<double> _animation;

  SpritePainter(this._animation) : super(repaint: _animation);

  void circle(Canvas canvas, Rect rect, double value) {
    double opacity = (1.0 - (value / 4.0)).clamp(0.0, 1.0);
    Color color = Color.fromRGBO(0, 117, 194, opacity);

    double size = rect.width / 2;
    double area = size * size;
    double radius = sqrt(area * value / 4);

    final Paint paint = Paint()..color = color;
    canvas.drawCircle(rect.center, radius, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    Rect rect = Rect.fromLTRB(0.0, 0.0, size.width, size.height);

    for (int wave = 3; wave >= 0; wave--) {
      circle(canvas, rect, wave + _animation.value);
    }
  }

  @override
  bool shouldRepaint(SpritePainter oldDelegate) {
    return true;
  }
}
