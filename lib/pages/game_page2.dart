import 'package:flutter/material.dart';
import 'dart:math';

class GamePage2 extends StatefulWidget {
  const GamePage2({super.key, required this.title});

  final String title;

  @override
  State<GamePage2> createState() => _GamePage2State();
}

class _GamePage2State extends State<GamePage2> with TickerProviderStateMixin {
  int _balance = 100;
  double _bet = 10;
  late AnimationController _balanceAnimController;
  late AnimationController _gambleAnimController;
  late AnimationController _cardAnimController;
  late AnimationController _characterAnimController;
  late AnimationController _reactionAnimController;
  late Animation<int> _balanceAnimation;
  late int _displayBalance;
  List<Map<String, dynamic>> _doorCards = []; // 修改：改為存儲完整牌面信息
  Map<String, dynamic>? _playerCard; // 修改：改為存儲完整牌面信息
  bool _isRevealed = false;
  final List<String> _suits = ['hearts', 'diamonds', 'clubs', 'spades'];
  String _currentSuit = 'hearts'; // 新增：當前花色
  List<Map<String, dynamic>> _deck = []; // 新增：完整牌組
  bool _showBubble = true;
  String _characterImage = 'assets/images/ssay.png'; // 更改預設圖片
  String _displayedText = '';
  String _fullText = '這把，會贏喔!';
  int _textIndex = 0;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _displayBalance = _balance;
    _setupAnimations();
    _initializeDeck();
    _initializeCards(); // New method call instead of _shuffleDoorCards
    _startTypingAnimation();
  }

  void _setupAnimations() {
    _balanceAnimController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _gambleAnimController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _cardAnimController = AnimationController(
      duration: const Duration(milliseconds: 1500),
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
  }

  void _initializeDeck() {
    _deck = [];
    for (String suit in _suits) {
      for (int i = 1; i <= 13; i++) {
        _deck.add({'number': i, 'suit': suit});
      }
    }
  }

  void _initializeCards() {
    _initializeDeck();
    _deck.shuffle();
    var drawnCards = _deck.take(3).toList();
    
    if (drawnCards[0]['number'] > drawnCards[1]['number']) {
      final temp = drawnCards[0];
      drawnCards[0] = drawnCards[1];
      drawnCards[1] = temp;
    }
    
    setState(() {
      _doorCards = [drawnCards[0], drawnCards[1]];
      _playerCard = drawnCards[2];
      _isRevealed = false;
    });
  }

  void _updateBet(double localPosition, double maxWidth) {
    if (_balance <= 0) return;
    final double percentage = (localPosition / maxWidth).clamp(0.0, 1.0);
    setState(() {
      _bet = (percentage * _balance).clamp(1, _balance.toDouble());
    });
  }

  void _animateBalance(int newBalance) {
    _balanceAnimation = IntTween(
      begin: _displayBalance,
      end: newBalance,
    ).animate(CurvedAnimation(
      parent: _balanceAnimController,
      curve: Curves.easeInOut,
    ))..addListener(() {
      setState(() {
        _displayBalance = _balanceAnimation.value;
      });
    });
    _balanceAnimController.forward(from: 0);
  }

  void _shuffleDoorCards() {
    _initializeDeck(); // 重新初始化牌組
    _deck.shuffle(); // 洗牌
    
    // 抽三張牌
    var drawnCards = _deck.take(3).toList();
    
    // 確保前兩張是有序的（小在左大在右）
    if (drawnCards[0]['number'] > drawnCards[1]['number']) {
      // 交換牌的順序
      final temp = drawnCards[0];
      drawnCards[0] = drawnCards[1];
      drawnCards[1] = temp;
    }
    
    // 如果兩張牌點數相同，獎勵翻倍並重新抽牌
    if (drawnCards[0]['number'] == drawnCards[1]['number']) {
      setState(() {
        _balance *= 2;
        _animateBalance(_balance);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lucky! Same numbers! Balance doubled to \$$_balance!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      
      _shuffleDoorCards(); // 重新洗牌
      return;
    }
    
    // 如果兩張牌點數相差為1，重新洗牌
    if (drawnCards[1]['number'] - drawnCards[0]['number'] == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cards too close! Reshuffling...'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 1),
        ),
      );
      
      _shuffleDoorCards();
      return;
    }

    setState(() {
      _doorCards = [drawnCards[0], drawnCards[1]];
      _playerCard = drawnCards[2];
      _isRevealed = false;
      
      if (_bet > _balance) {
        _bet = _balance.toDouble();
      }
    });
  }

  void _gamble() async {
    if (_balance >= _bet) {
      _gambleAnimController.forward(from: 0);
      
      setState(() {
        _isRevealed = false;
      });

      await _cardAnimController.forward(from: 0);
      
      await Future.delayed(const Duration(milliseconds: 1000));
      
      setState(() {
        _isRevealed = true;
      });

      await Future.delayed(const Duration(milliseconds: 1000));

      setState(() {
        bool isWin = false;
        if (_playerCard!['number'] == _doorCards[0]['number'] || 
            _playerCard!['number'] == _doorCards[1]['number']) {
          _balance -= (_bet * 2).toInt();
          isWin = false;
        } else {
          final bool inRange = _playerCard!['number'] > _doorCards[0]['number'] && 
                            _playerCard!['number'] < _doorCards[1]['number'];
          if (inRange) {
            _balance += _bet.toInt();
            isWin = true;
          } else {
            _balance -= _bet.toInt();
            isWin = false;
          }
        }

        // 顯示勝負反應
        _showReaction(isWin);
        
        if (_balance <= 0) {
          _balance = 0;
          Future.delayed(const Duration(milliseconds: 800), _showGameOverDialog);
        }
        _animateBalance(_balance);
        
        if (_bet > _balance) {
          _bet = _balance.toDouble();
        }
      });

      await Future.delayed(const Duration(milliseconds: 1500));
      
      if (_balance > 0) {
        _shuffleDoorCards();
      }

      await _gambleAnimController.forward(from: 0.7);
      _gambleAnimController.reset();
    }
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
                'assets/images/scry.png',
                height: 120, // 調整大小
                width: 120,
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
              child: const Text('Restart'),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _balance = 100;
                  _bet = 10;
                  _animateBalance(_balance);
                  _shuffleDoorCards(); // 重新開始時洗牌
                });
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

  String _getCardImagePath(Map<String, dynamic> card) {
    int number = card['number'];
    String suit = card['suit'];
    String cardName = number.toString();
    
    switch (number) {
      case 1:
        cardName = 'ace';
        break;
      case 11:
        cardName = 'jack';
        break;
      case 12:
        cardName = 'queen';
        break;
      case 13:
        cardName = 'king';
        break;
    }
    
    return 'assets/images/${cardName}_of_$suit.png';
  }

  Widget _buildCard(Map<String, dynamic>? card, {bool isRevealed = true}) {
    return Container(
      width: 80,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.purple, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: isRevealed && card != null
            ? Image.asset(
                _getCardImagePath(card),
                fit: BoxFit.cover,
              )
            : Image.asset(
                'assets/images/back.png',
                fit: BoxFit.cover,
              ),
      ),
    );
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

  void _showReaction(bool isWin) async {
    setState(() {
      _showBubble = false;
      _characterImage = isWin ? 'assets/images/swin.png' : 'assets/images/12.png';
    });

    await _reactionAnimController.forward();
    _reactionAnimController.reset();

    setState(() {
      _characterImage = 'assets/images/ssay.png';
      _showBubble = true;
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
                    Text(
                      'Shoot the Dragon Gate',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade700,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildCard(_doorCards[0]),
                        const SizedBox(width: 20),
                        AnimatedBuilder(
                          animation: _cardAnimController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: 1.0 + _cardAnimController.value * 0.1,
                              child: _buildCard(_playerCard, isRevealed: _isRevealed),
                            );
                          },
                        ),
                        const SizedBox(width: 20),
                        _buildCard(_doorCards[1]),
                      ],
                    ),
                    const SizedBox(height: 40),
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
                        height: 50,
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
                          child: LinearProgressIndicator(
                            value: _balance > 0 ? _bet / max(_balance.toDouble(), 1) : 0,
                            backgroundColor: Colors.purple.withOpacity(0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.purple.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          onPressed: (_bet > _balance) ? null : _gamble, // 只在下注金額超過餘額時禁用
                          child: const Text(
                            'SHOOT',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('New Gate'),
                                content: Text('10% of your balance (\$${(_balance * 0.1).round()}) will be deducted. Continue?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      // 先扣除 10% 金額
                                      int deduction = (_balance * 0.1).round();
                                      setState(() {
                                        _balance -= deduction;
                                        if (_balance < 0) _balance = 0;
                                        _animateBalance(_balance);
                                      });
                                      if (_balance <= 0) {
                                        Future.delayed(
                                          const Duration(milliseconds: 800),
                                          _showGameOverDialog
                                        );
                                      } else {
                                        _shuffleDoorCards();
                                      }
                                    },
                                    child: const Text('Continue'),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: const Text(
                            'NEW GATE',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            bottom: 40,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AnimatedBuilder(
                  animation: _characterAnimController,
                  builder: (context, child) {
                    double scale = 1.0;
                    if (_reactionAnimController.isAnimating) {
                      scale = 1.0 + sin(_reactionAnimController.value * 4 * pi) * 0.2;
                    }
                    
                    return Transform.scale(
                      scale: scale,
                      child: Transform.translate(
                        offset: Offset(0, sin(_characterAnimController.value * 2 * pi) * 5),
                        child: Image.asset(
                          _characterImage,
                          height: 130, // 調整更小
                          fit: BoxFit.contain,
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

  @override
  void dispose() {
    _balanceAnimController.dispose();
    _gambleAnimController.dispose();
    _cardAnimController.dispose();
    _characterAnimController.dispose();
    _reactionAnimController.dispose();
    _isTyping = false;
    super.dispose();
  }
}

class SpeechBubblePainter extends CustomPainter {
  final Color color;
  final Color shadowColor;

  SpeechBubblePainter({required this.color, required this.shadowColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = shadowColor
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(20, 0)
      ..lineTo(size.width - 20, 0)
      ..quadraticBezierTo(size.width, 0, size.width, 20)
      ..lineTo(size.width, size.height - 20)
      ..quadraticBezierTo(size.width, size.height, size.width - 20, size.height)
      ..lineTo(40, size.height)
      ..quadraticBezierTo(20, size.height, 20, size.height - 20)
      ..lineTo(0, size.height - 40)
      ..lineTo(20, size.height - 60)
      ..lineTo(20, 20)
      ..quadraticBezierTo(20, 0, 40, 0);

    canvas.drawPath(path.shift(const Offset(2, 2)), shadowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
