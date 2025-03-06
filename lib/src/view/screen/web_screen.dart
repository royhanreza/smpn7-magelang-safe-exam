import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:get/get.dart';
import 'package:safe_exam/src/view/screen/exam_screen.dart';
import 'package:safe_exam/src/view/widget/custom_status_bar.dart';
import 'package:safe_exam/utils/screen_pinning.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class WebScreen extends StatefulWidget {
  const WebScreen({super.key, required this.url});

  final String url;

  @override
  _WebScreenState createState() => _WebScreenState();
}

class _WebScreenState extends State<WebScreen> {
  static const platform = MethodChannel('screen_pinning');
  final AudioPlayer _audioPlayer = AudioPlayer();
  late final WebViewController _controller;
  int _webLoadingProgress = 0;
  bool _isEditing = false;
  String _finishCode = "";
  final String _realFinishCode = "saptacendekia";
  final TextEditingController _textController = TextEditingController();
  Widget _pageTitle = Container();
  Timer? _timer;
  bool _isOverlayShown = false;
  late final VolumeController _volumeController;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _volumeController = VolumeController.instance;

    FlutterOverlayWindow.overlayListener.listen((event) {
      print("Flutter overlay window: $event");
      if (event == "finish") {
        // Lakukan inisialisasi yang diperlukan untuk overlay
        // _playFinishSound();
      }
    });

    // _enableProtection();
    // print('monitoring dijalankan');

    // ScreenPinningHelper.startMonitoring(context);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!await ScreenPinningHelper.isPinned()) {
        debugPrint("Aplikasi telah di-unpin lewat timer!");
        if (!_isOverlayShown) {
          if (Platform.isAndroid) {
            // SystemNavigator.pop();
            if (await FlutterOverlayWindow.isActive()) return;
            setState(() {
              _isOverlayShown = true;
            });
            await FlutterOverlayWindow.showOverlay(
              enableDrag: false,
              overlayTitle: "Keluar Aplikasi",
              overlayContent: 'Keluar Aplikasi',
              flag: OverlayFlag.focusPointer,
              visibility: NotificationVisibility.visibilityPublic,
              positionGravity: PositionGravity.auto,
              height: WindowSize.matchParent,
              width: WindowSize.matchParent,
              startPosition: const OverlayPosition(0, 0),
            );
            await FlutterOverlayWindow.shareData("initialize");
          }
        } else {
          SystemNavigator.pop();
        }
      }
    });

    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);
    // #enddocregion platform_features

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _webLoadingProgress = progress;
            });
            debugPrint('WebView is loading (progress : $progress%)');
          },
          onPageStarted: (String url) {
            debugPrint('Page started loading: $url');
          },
          onPageFinished: (String url) {
            debugPrint('Page finished loading: $url');
            setState(() {
              _webLoadingProgress = 0;
            });
            setAppBarTitle();
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('''
Page resource error:
  code: ${error.errorCode}
  description: ${error.description}
  errorType: ${error.errorType}
  isForMainFrame: ${error.isForMainFrame}
          ''');
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('https://www.youtube.com/')) {
              debugPrint('blocking navigation to ${request.url}');
              return NavigationDecision.prevent;
            }
            debugPrint('allowing navigation to ${request.url}');
            return NavigationDecision.navigate;
          },
          onHttpError: (HttpResponseError error) {
            debugPrint('Error occurred on page: ${error.response?.statusCode}');
          },
          onUrlChange: (UrlChange change) {
            debugPrint('url change to ${change.url}');
          },
          onHttpAuthRequest: (HttpAuthRequest request) {
            // openDialog(request);
            debugPrint(request.toString());
          },
        ),
      )
      ..addJavaScriptChannel(
        'Toaster',
        onMessageReceived: (JavaScriptMessage message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message.message)),
          );
        },
      )
      ..loadRequest(Uri.parse(widget.url));

    // setBackgroundColor is not currently supported on macOS.
    if (kIsWeb || !Platform.isMacOS) {
      controller.setBackgroundColor(const Color(0x80000000));
    }

    // #docregion platform_features
    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }
    // #enddocregion platform_features

    _controller = controller;
  }

  Future<void> _enableProtection() async {
    try {
      await platform.invokeMethod('enableProtection');
    } catch (e) {
      print("Error enabling protection: $e");
    }
  }

  Future<void> _disableProtection() async {
    try {
      await platform.invokeMethod('disableProtection');
    } catch (e) {
      print("Error disabling protection: $e");
    }
  }

  void _playFinishSound() async {
    await _volumeController.setVolume(1.0);
    await _audioPlayer.play(AssetSource('sounds/finish_sound.mp3'));
  }

  void setAppBarTitle() {
    setState(() {
      _pageTitle = FutureBuilder(
        future: _controller.getTitle(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Text("${snapshot.data}");
          } else {
            return const Text("Loading");
          }
        },
      );
    });
  }

  void _onConfirmFinishCode() {
    if (_finishCode == _realFinishCode) {
      _playFinishSound();
      Get.off(const ExamScreen());
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Kata kunci salah')));
    }
  }

  @override
  void dispose() {
    // _audioPlayer.dispose();
    // print("Monitoring dihentikan...");
    // ScreenPinningHelper.stopMonitoring();
    // _disableProtection();
    // _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: _isEditing
            ? Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: "Ketik \"$_realFinishCode\" untuk keluar",
                        border: InputBorder.none,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _finishCode = value;
                        });
                      },
                      // style: TextStyle(color: Colors.white),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isEditing = false;
                      });
                    },
                    icon: const Icon(Icons.cancel, color: Colors.grey),
                  ),
                  IconButton(
                    onPressed: () {
                      // setState(() {
                      //   _isEditing = false;
                      // });
                      _onConfirmFinishCode();
                    },
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                  ),
                ],
              )
            : null,
        automaticallyImplyLeading: false,
        actions: _isEditing
            ? []
            : [
                NavigationControls(webViewController: _controller),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                      _textController.text = "";
                    });
                  },
                  icon: const Icon(Icons.check_circle, color: Colors.green),
                ),
              ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              width: MediaQuery.of(context).size.width *
                  (_webLoadingProgress / 100),
              height: 3,
              color: Colors.blue,
            ),
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: CustomStatusBar(),
          ),
        ],
      ),
    );
  }
}

class NavigationControls extends StatelessWidget {
  const NavigationControls({super.key, required this.webViewController});

  final WebViewController webViewController;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            size: 18,
          ),
          onPressed: () async {
            if (await webViewController.canGoBack()) {
              await webViewController.goBack();
            } else {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No back history item')),
                );
              }
            }
          },
        ),
        IconButton(
          icon: const Icon(
            Icons.arrow_forward_ios,
            size: 18,
          ),
          onPressed: () async {
            if (await webViewController.canGoForward()) {
              await webViewController.goForward();
            } else {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No forward history item')),
                );
              }
            }
          },
        ),
        IconButton(
          icon: const Icon(
            Icons.replay,
            size: 18,
          ),
          onPressed: () => webViewController.reload(),
        ),
      ],
    );
  }
}
