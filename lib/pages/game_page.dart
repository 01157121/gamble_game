import 'package:flutter/material.dart';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key, required this.title});

  final String title;

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with TickerProviderStateMixin {
  int _balance = 100;
  double _bet = 10;
  late AnimationController _balanceAnimController;
  late AnimationController _gambleAnimController;
  late Animation<int> _balanceAnimation;
  late int _displayBalance;
  late AnimationController _characterAnimController;
  late AnimationController _reactionAnimController;
  String _displayedText = '';
  String _fullText = '正是偉大的魔法師才能看出1%的可能性';
  int _textIndex = 0;
  bool _isTyping = false;
  bool _showBubble = true;
  String _characterImage = 'assets/images/say.png';
  final AudioPlayer _soundPlayer = AudioPlayer();  // 用於打字音效
  final AudioPlayer _effectPlayer = AudioPlayer(); // 用於遊戲音效

  @override
  void initState() {
    super.initState();
    _displayBalance = _balance;
    
    _balanceAnimController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _gambleAnimController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _characterAnimController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _reactionAnimController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _balanceAnimation = IntTween(
      begin: _displayBalance,
      end: _displayBalance,
    ).animate(CurvedAnimation(
      parent: _balanceAnimController,
      curve: Curves.easeInOut,
    ));

    _startTypingAnimation();
  }

  @override
  void dispose() {
    _balanceAnimController.dispose();
    _gambleAnimController.dispose();
    _characterAnimController.dispose();
    _reactionAnimController.dispose();
    _soundPlayer.dispose();
    _effectPlayer.dispose();
    _isTyping = false;
    super.dispose();
  }

  void _startTypingAnimation() {
    _isTyping = true;
    _textIndex = 0;
    _displayedText = '';
    _typeNextCharacter();
  }

  void _typeNextCharacter() {
    if (!mounted || !_isTyping) return;
    
    setState(() {
      if (_textIndex < _fullText.length) {
        _displayedText = _fullText.substring(0, _textIndex + 1);
        _textIndex++;
        if (_textIndex == 1) { // 只在第一個字時播放音效
          _soundPlayer.play(AssetSource('sound/saying.mp3'));
        }
        Future.delayed(const Duration(milliseconds: 100), _typeNextCharacter);
      } else {
        _isTyping = false;
        // 等待3秒後重新開始動畫
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            _startTypingAnimation();
          }
        });
      }
    });
  }

  void _animateBalance(int newBalance) {
    _balanceAnimation = IntTween(
      begin: _displayBalance,
      end: newBalance,
    ).animate(CurvedAnimation(
      parent: _balanceAnimController,
      curve: Curves.easeOut,
    ))..addListener(() {
      setState(() {
        _displayBalance = _balanceAnimation.value;
      });
    });
    _balanceAnimController.forward(from: 0);
  }

  void _resetGame() {
    setState(() {
      _balance = 100;
      _bet = 10;
      _displayBalance = _balance;
    });
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/cry.png',
                height: 100,
                width: 100,
              ),
              const SizedBox(height: 20),
              const Text(
                'Game Over',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text('You lost all your money!'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Play Again'),
              onPressed: () {
                Navigator.of(context).pop();
                _resetGame();
              },
            ),
            TextButton(
              child: const Text('Back to Home'),
              onPressed: () {
                Navigator.of(context).pop(); // 關閉對話框
                Navigator.of(context).pop(); // 返回主頁面
              },
            ),
          ],
        );
      },
    );
  }

  void _showReaction(bool isWin) async {
    setState(() {
      _showBubble = false;
      _characterImage = isWin ? 'assets/images/fwin.png' : 'assets/images/1.jpg';
    });

    await _reactionAnimController.forward();
    _reactionAnimController.reset();

    setState(() {
      _characterImage = 'assets/images/say.png';
      _showBubble = true;
    });
  }

  void _gamble() async {
    if (_balance >= _bet) {
      final bool win = Random().nextBool();
      _gambleAnimController.forward(from: 0);

      // 播放揭曉音效
      await _effectPlayer.play(AssetSource('sound/sound.mp3'));
      
      await Future.delayed(const Duration(milliseconds: 2000));
      
      setState(() {
        if (win) {
          _balance += _bet.toInt();
          _showReaction(true);
          _effectPlayer.play(AssetSource('sound/win.mp3'));
        } else {
          _balance -= _bet.toInt();
          _showReaction(false);
          _effectPlayer.play(AssetSource('sound/lose.mp3'));
          if (_balance <= 0) {
            _balance = 0;
            Future.delayed(const Duration(milliseconds: 800), _showGameOverDialog);
          }
        }
        _animateBalance(_balance);
      });
      
      await _gambleAnimController.forward(from: 0.7);
    }
  }

  void _updateBet(double localPosition, double maxWidth) {
    if (_balance <= 0) return;
    final double percentage = (localPosition / maxWidth).clamp(0.0, 1.0);
    setState(() {
      _bet = (percentage * _balance).clamp(1, _balance.toDouble());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.purple.withOpacity(0.3),
                  Colors.blue.withOpacity(0.3),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          Center(
            child: Card(
              elevation: 12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    AnimatedBuilder(
                      animation: _gambleAnimController,
                      builder: (context, child) {
                        return ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              Colors.purple,
                              Colors.blue,
                              Colors.purple,
                            ],
                            stops: [0.0, _gambleAnimController.value, 1.0],
                          ).createShader(bounds),
                          child: Text(
                            'Your balance: \$$_displayBalance',
                            style: TextStyle(
                              fontFamily: 'manga',  // 英文使用 manga
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: _gambleAnimController.value * 4,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 40),
                    Text(
                      'Bet amount: \$${_bet.toInt()}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onHorizontalDragUpdate: (details) {
                        _updateBet(details.localPosition.dx, 280);
                      },
                      onTapDown: (details) {
                        _updateBet(details.localPosition.dx, 280);
                      },
                      child: Container(
                        height: 50,  // 增加高度使其更明顯
                        width: 280,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: Colors.purple.withOpacity(0.5),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purple.withOpacity(0.2),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: AnimatedBuilder(
                            animation: _gambleAnimController,
                            builder: (context, child) {
                              return LinearProgressIndicator(
                                value: _balance > 0 ? _bet / max(_balance.toDouble(), 1) : 0,
                                backgroundColor: Colors.purple.withOpacity(0.1),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  HSLColor.fromAHSL(
                                    1.0,
                                    (_gambleAnimController.value * 360).toDouble(),
                                    0.8,
                                    0.5,
                                  ).toColor().withOpacity(0.7),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 8,
                      ),
                      onPressed: _gambleAnimController.isAnimating ? null : _gamble,
                      child: AnimatedBuilder(
                        animation: _gambleAnimController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: 1.0 + _gambleAnimController.value * 0.15,
                            child: const Text(
                              'GAMBLE',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            bottom: 40, // 調整位置往上
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AnimatedBuilder(
                  animation: _characterAnimController,
                  builder: (context, child) {
                    double scale = 1.0;
                    if (_reactionAnimController.isAnimating) {
                      scale = 1.0 + sin(_reactionAnimController.value * 4 * pi) * 0.2;
                    } else {
                      scale = 1.0;
                    }
                    
                    return Transform.scale(
                      scale: scale,
                      child: Transform.translate(
                        offset: Offset(0, sin(_characterAnimController.value * 2 * pi) * 5),
                        child: Image.asset(
                          _characterImage,
                          height: 150,
                        ),
                      ),
                    );
                  },
                ),
                if (_showBubble) CustomPaint(
                  painter: SpeechBubblePainter(
                    color: Colors.white,
                    shadowColor: Colors.black.withOpacity(0.2),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(left: 20, bottom: 20),
                    padding: const EdgeInsets.all(15),
                    constraints: const BoxConstraints(maxWidth: 250),
                    child: Text(
                      _displayedText,
                      style: const TextStyle(
                        fontFamily: 'boutique',  // 中文對話使用 boutique
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 添加自定義對話框繪製器
class SpeechBubblePainter extends CustomPainter {
  final Color color;
  final Color shadowColor;

  SpeechBubblePainter({
    required this.color,
    required this.shadowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint shadowPaint = Paint()
      ..color = shadowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final Paint bubblePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(20, 0)
      ..lineTo(size.width - 20, 0)
      ..quadraticBezierTo(size.width, 0, size.width, 20)
      ..lineTo(size.width, size.height - 20)
      ..quadraticBezierTo(size.width, size.height, size.width - 20, size.height)
      ..lineTo(40, size.height)
      ..quadraticBezierTo(30, size.height, 20, size.height - 10)
      ..lineTo(0, size.height - 30)
      ..lineTo(20, size.height - 20)
      ..lineTo(20, 20)
      ..quadraticBezierTo(20, 0, 40, 0);

    // 繪製陰影
    canvas.drawPath(path, shadowPaint);
    // 繪製對話框
    canvas.drawPath(path, bubblePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
