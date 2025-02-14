import 'package:demo/main.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui';
import '../services/api_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isLoading = false;
  double cardOffset = 0.0;
  final double threshold = 100.0;
  late String _currentWallpaper;
  bool isFormVisible = false; // 控制卡片出现
  bool enableInteraction = false; // 控制表单交互
  double _wallpaperOpacity = 1.0; // 控制渐变
  double _wallpaperScale = 1.0; // 控制缩放

  final List<String> wallpapers = [
    'assets/wallpapers/sample1.jpg',
    'assets/wallpapers/sample2.jpg',
    'assets/wallpapers/sample3.jpg',
    'assets/wallpapers/sample4.jpg',
    'assets/wallpapers/sample5.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _currentWallpaper = randomWallpaper;
  }

  String get randomWallpaper {
    final random = Random();
    return wallpapers[random.nextInt(wallpapers.length)];
  }

  void changeWallpaper() {
    setState(() {
      isFormVisible = false; // 让卡片回到底部
      enableInteraction = false; // 禁用输入交互
      cardOffset = 0.0; // 重置滑动状态
      _wallpaperOpacity = 0.0; // 透明度变为 0，触发渐变
      _wallpaperScale = 1.1; // 轻微放大
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _currentWallpaper = randomWallpaper; // 更新壁纸
      });
    });

    Future.delayed(const Duration(milliseconds: 400), () {
      setState(() {
        _wallpaperOpacity = 1.0; // 渐变回正常
        _wallpaperScale = 1.0; // 缩放回正常
      });
    });
  }

  void showLoginForm() {
    setState(() {
      isFormVisible = true;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        enableInteraction = true;
      });
    });
  }

  void login({bool triggeredBySwipe = false}) async {
    if (!enableInteraction) return;

    final String username = _emailController.text.trim();
    final String password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      showErrorSnackbar('Please fill out all fields');
      isFormVisible = true; // 确保表单可见
      return;
    }

    setState(() {
      isLoading = true;
      if (triggeredBySwipe) {
        isFormVisible = false; // 下滑时隐藏卡片
      }
    });

    try {
      final bool success = await ApiService().login(username, password);
      if (success) {
        Navigator.pushReplacementNamed(context, '/feed');
      } else {
        showErrorSnackbar('Invalid username or password');
        if (triggeredBySwipe) {
          setState(() {
            isFormVisible = true; // 登录失败时，恢复卡片
          });
        }
      }
    } catch (e) {
      showErrorSnackbar('An error occurred: $e');
      if (triggeredBySwipe) {
        setState(() {
          isFormVisible = true; // 登录失败时，恢复卡片
        });
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent, // 让外层透明
        elevation: 0, // 去除阴影
        margin: const EdgeInsets.only(bottom: 10), // 调整底部间距
        content: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              message,
              textAlign: TextAlign.center, // 文本居中
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void animateCardToHide() {
    FocusScope.of(context).unfocus(); // 收起键盘

    setState(() {
      cardOffset = 500; // 让卡片直接滑出屏幕
      isFormVisible = false; // 隐藏表单
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        cardOffset = 0; // 重置偏移，准备下一次登录
      });
    });

    login(triggeredBySwipe: true);
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // **背景图片**
          Positioned.fill(
            child: TweenAnimationBuilder(
              duration: const Duration(milliseconds: 600), // 更长时间，动画更平滑
              tween:
                  Tween<double>(begin: _wallpaperScale, end: _wallpaperScale),
              curve: Curves.easeInOut,
              builder: (context, double scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 400),
                    opacity: _wallpaperOpacity,
                    child: Image.asset(
                      _currentWallpaper,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),

          // **更换壁纸按钮**
          Positioned(
            top: 40,
            right: 20,
            child: Opacity(
              opacity: 0.6,
              child: IconButton(
                icon: const Icon(Icons.image, size: 28, color: Colors.white),
                onPressed: changeWallpaper,
                tooltip: "Change Wallpaper",
              ),
            ),
          ),

          // **底部 Login 按钮**
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 150),
              child: TextButton(
                onPressed: isLoading
                    ? null
                    : () => isFormVisible ? login() : showLoginForm(),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  backgroundColor:
                      isFormVisible ? primaryColor : Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: BorderSide(
                      color: isFormVisible ? primaryColor : Colors.white,
                      width: 3,
                    ),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : Text(
                        "Log In",
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ),

          // **登录卡片（动画从底部滑入）**
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            bottom: isFormVisible ? 260 : -screenHeight * 0.8,
            left: 35,
            right: 35,
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                if (!enableInteraction) return;
                setState(() {
                  cardOffset += details.primaryDelta!;
                });
              },
              onVerticalDragEnd: (details) {
                if (!enableInteraction) return;
                if (cardOffset > threshold) {
                  animateCardToHide(); // 直接隐藏卡片
                } else {
                  setState(() {
                    cardOffset = 0; // 否则回归原位
                  });
                }
              },
              child: Transform.translate(
                offset: Offset(0, cardOffset),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20.0),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                    child: Container(
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(25.0),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1.0,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/tm_logo.png',
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: "Username",
                              filled: true,
                              fillColor: Colors.transparent,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(17), // 设置圆角
                                borderSide: const BorderSide(
                                    color: greyColor), // 默认灰色边框
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(17),
                                borderSide: const BorderSide(
                                    color: greyColor), // 未选中状态
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(17),
                                borderSide: BorderSide(
                                    color: primaryColor,
                                    width: 2), // 选中时变为 primaryColor
                              ),
                            ),
                            enabled: enableInteraction,
                          ),

const SizedBox(height: 20),

                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: "Password",
                              filled: true,
                              fillColor: Colors.transparent,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(17),
                                borderSide:
                                    const BorderSide(color: greyColor),
                              ),
                              enabledBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(17),
                                borderSide:
                                    const BorderSide(color: greyColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(17),
                                borderSide:
                                    BorderSide(color: primaryColor, width: 2),
                              ),
                            ),
                            enabled: enableInteraction,
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/register');
                            },
                            child: const Text(
                              "Don't have an account? Register here",
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
