import 'dart:async';

import 'package:agora/src/utils/settings.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';

class CallPage extends StatefulWidget {
  final String channelName;
  final ClientRoleType? role;
  final String token;

  const CallPage(
      {Key? key,
      required this.channelName,
      required this.token,
      this.role = ClientRoleType.clientRoleBroadcaster})
      : super(key: key);

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  final _users = <int>[];
  final _infoString = <String>[];
  bool _mute = false;
  bool viewPanel = false;
  bool _isShowing = false;
  bool _isShowToolBar = false;
  final double _defaultHeight = 190;
  final double _defaultWidth = 130;
  final double _sizeIncrease = 10;
  double _height = 190;
  double _width = 130;
  Timer? timer;
  late RtcEngine _engine;

  @override
  void initState() {
    initialize();
    super.initState();
  }

  @override
  void dispose() {
    _users.clear();
    _engine.leaveChannel();
    super.dispose();
  }

  Future<void> initialize() async {
    print("token: ${widget.token}");
    print("channalName: ${widget.channelName}");
    if (appId.isEmpty) {
      setState(() {
        _infoString.add('App_id is misssing');
        _infoString.add('Agora engine is not starting');
      });
      return;
    }
    //init agora engine
    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));
    await _engine.enableVideo();
    await _engine.setClientRole(role: widget.role!);

    //add agora event handler
    _addAgoraHandler();
    VideoEncoderConfiguration configuration = const VideoEncoderConfiguration();
    // configuration.dimensions = VideoDimensions(width: 1920, height: 1080);
    await _engine.setVideoEncoderConfiguration(configuration);
    await _engine.joinChannel(
      token: widget.token,
      channelId: widget.channelName,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  @override
  Widget build(BuildContext context) {
    setState(() {
      open = false;
    });
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agora'),
        centerTitle: true,
        actions: [
          IconButton(
              onPressed: () {
                setState(() {
                  viewPanel = !viewPanel;
                });
              },
              icon: const Icon(Icons.info_outline)),
        ],
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _viewRow(),
          (_isShowToolBar) ? _toolbar() : const SizedBox()
        ],
      ),
    );
  }

  void _addAgoraHandler() {
    _engine.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (connection, elapse) {
      setState(() {
        final info = 'Join channel connection: $connection elapse: $elapse';
        _infoString.add(info);
      });
    }, onUserJoined: (connection, uid, elapse) {
      setState(() {
        final info = 'User joined: $uid';
        _infoString.add(info);
        _users.add(uid);
      });
    }, onUserOffline: (connection, uid, elapse) {
      setState(() {
        final info = 'User offline: $uid';
        _infoString.add(info);
        _users.remove(uid);
      });
    }, onFirstRemoteVideoFrame: (connection, uid, width, height, elapse) {
      setState(() {
        final info = 'First remote video: $uid (${width}x$height)';
        _infoString.add(info);
      });
    }));
  }

  Widget _toolbar() {
    if (widget.role == ClientRoleType.clientRoleAudience) return const SizedBox();
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RawMaterialButton(
                onPressed: () {
                  setState(() {
                    _mute = !_mute;
                  });
                  _engine.muteLocalAudioStream(_mute);
                },
                shape: const CircleBorder(),
                elevation: 2,
                fillColor: _mute ? Colors.blueAccent : Colors.white,
                padding: const EdgeInsets.all(12),
                child: Icon(
                  _mute ? Icons.mic_off : Icons.mic,
                  color: _mute ? Colors.white : Colors.blueAccent,
                  size: 20,
                ),
              ),
              RawMaterialButton(
                onPressed: () => Navigator.pop(context),
                shape: const CircleBorder(),
                elevation: 2,
                fillColor: Colors.red,
                padding: const EdgeInsets.all(15),
                child: const Icon(
                  Icons.call_end,
                  color: Colors.white,
                  size: 35,
                ),
              ),
              RawMaterialButton(
                onPressed: () => _engine.switchCamera(),
                shape: const CircleBorder(),
                elevation: 2,
                fillColor: Colors.white,
                padding: const EdgeInsets.all(12),
                child: const Icon(
                  Icons.switch_camera,
                  color: Colors.blueAccent,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _viewRow() {
    final List<StatefulWidget> list = [];
    // if (widget.role == ClientRole.Broadcaster) {
    //   list.add(const rtc_local_view.SurfaceView());
    // }
    for (var uid in _users) {
      list.add(AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: uid),
          connection: RtcConnection(channelId: widget.channelName),
        ),
      ));
      // list.add(rtc_remote_view.SurfaceView(
      //   uid: uid,
      //   channelId: widget.channelName!,
      // ));
    }

    final views = list;
    final localView = localSurfaceView();
    return Stack(
      children: [
        Column(
          children: List.generate(
              views.length, (index) => Expanded(child: views[index])),
        ),
        localView,
      ],
    );
  }

  Widget localSurfaceView() {
    return GestureDetector(
        onTap: () {
          if (_isShowing) {
            countDownAnimation();
          } else {
            setState(() {
              _isShowToolBar = true;
              _height = _defaultHeight + _sizeIncrease;
              _width = _defaultWidth + _sizeIncrease;
            });
            _isShowing = true;
          }
          countDownAnimation();
        },
        child: AnimatedContainer(
          height: _height,
          width: _width,
          duration: const Duration(milliseconds: 300),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                width: _width,
                height: _height,
                child: AgoraVideoView(
                  controller: VideoViewController(
                    rtcEngine: _engine,
                    canvas: const VideoCanvas(uid: 0),
                  ),
                )),
          ),
        ));
  }

  void countDownAnimation() {
    if (timer != null) timer!.cancel();
    timer = Timer(const Duration(seconds: 5), () {
      setState(() {
        _isShowToolBar = false;
        _height = _defaultHeight;
        _width = _defaultWidth;
      });
      _isShowing = false;
      timer = null;
    });
  }
}
