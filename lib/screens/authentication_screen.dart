import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../widgets/network_overlay.dart';
import '../mixins/typewriter_mixin.dart';
import '../widgets/typewriter_widget.dart';
import '../widgets/subtitle_widget.dart';
import '../widgets/auth_input_widget.dart';
import '../widgets/auth_toggle_widget.dart';
import 'signup_details_screen.dart';

class AuthenticationScreen extends StatefulWidget {
  const AuthenticationScreen({Key? key}) : super(key: key);

  @override
  State<AuthenticationScreen> createState() => AuthenticationScreenState();
}

class AuthenticationScreenState extends TypewriterMixin<AuthenticationScreen>
    with TickerProviderStateMixin {
  // Typewriter state (inherited from mixin)
  // greetings, visibleText, greetingIndex, etc. are defined in TypewriterMixin

  // Form state
  String _subtitleText = 'Sign in to continue to your chats';
  String _usernameHint = 'Enter email';
  bool _isSignupMode = false;
  bool _showSubtitle = false;

  bool _showForm = false;
  bool _showCancelButton = false;

  // Loading and avatar state
  bool _isLoading = false;
  String? _loadingMessage;
  bool _showUserAvatar = false;
  String _userFirstLetter = '';
  Timer? _verificationTimer;
  final _auth = FirebaseAuth.instance;
  String? _tempPassword;

  // Controllers
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;

  // Animations
  late AnimationController _buttonAnimationController;
  late Animation<Offset> _buttonPositionAnimation;

  @override
  void initState() {
    super.initState();
    _initializeState();
    _initializeAnimations();
    onFadeInsStart = _startSequentialFadeIns;
    startCursorTimer();
    startTypewriter();
  }

  void _initializeState() {
    greetings = ['Welcome', 'Hola', 'Bonjour', 'Hallo', 'こんにちは', 'مرحبا'];
    visibleText = '';
    greetingIndex = 0;
    isDeleting = false;
    initialCycleDone = false;
    showCursor = true;
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
  }

  void _initializeAnimations() {
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _buttonPositionAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1.0, 0),
    ).animate(
      CurvedAnimation(
        parent: _buttonAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _startSequentialFadeIns() async {
    await Future.delayed(const Duration(milliseconds: 350));
    setState(() => _showSubtitle = true);
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() => _showForm = true);
  }

  void _handleSubmit() async {
    if (_usernameController.text.isEmpty) return;

    if (!_showUserAvatar) {
      // First step - collect email
      setState(() {
        _isLoading = true;
        _loadingMessage =
            _isSignupMode ? 'Sending verification...' : 'Proceeding...';
        _buttonAnimationController.forward().then((_) {
          setState(() => _showCancelButton = true);
        });
      });

      // Email Regex Validation
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(_usernameController.text.trim())) {
        setState(() {
          _isLoading = false;
          _loadingMessage = null;
          _buttonAnimationController.reverse();
          _showCancelButton = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid email address')),
          );
        }
        return;
      }

      try {
        if (_isSignupMode) {
          // Signup Flow
          // 1. Ensure we're logged out
          if (_auth.currentUser != null) {
            await _auth.signOut();
          }

          // 2. Create user with temp password
          _tempPassword = _generateTempPassword();
          await _auth
              .createUserWithEmailAndPassword(
                email: _usernameController.text.trim(),
                password: _tempPassword!,
              )
              .timeout(const Duration(seconds: 10));

          // 3. Send verification email
          await _auth.currentUser?.sendEmailVerification();

          // 4. Update loading message and start polling
          if (mounted) {
            setState(() {
              _loadingMessage = 'Verify Email in Inbox';
            });
          }
          _startVerificationPolling();
        } else {
          // Login Flow - Skip email check, go directly to password input
          _proceedToPasswordInput();
        }
      } on TimeoutException catch (_) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _loadingMessage = null;
            _showCancelButton = false;
            _buttonAnimationController.reverse();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Request timed out. Please try again.'),
            ),
          );
        }
      } on FirebaseAuthException catch (e) {
        setState(() {
          _isLoading = false;
          _loadingMessage = null;
          _showCancelButton = false;
          _buttonAnimationController.reverse();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message ?? 'An error occurred')),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          _loadingMessage = null;
          _showCancelButton = false;
          _buttonAnimationController.reverse();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('An unexpected error occurred: $e')),
          );
        }
      }
    } else {
      // Final Submit (Password)
      _handleFinalSubmit();
    }
  }

  String _generateTempPassword() {
    const length = 16;
    const chars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    Random rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(rnd.nextInt(chars.length)),
      ),
    );
  }

  void _startVerificationPolling() {
    _verificationTimer?.cancel();

    // Track polling start time for timeout
    final startTime = DateTime.now();
    const maxPollingDuration = Duration(minutes: 5);
    int pollCount = 0;
    int consecutiveErrors = 0;
    const maxConsecutiveErrors = 5;

    _verificationTimer = Timer.periodic(const Duration(seconds: 3), (
      timer,
    ) async {
      pollCount++;
      final user = _auth.currentUser;

      try {
        await user?.reload();

        // Reset error counter on successful reload
        consecutiveErrors = 0;

        // Check if email is verified
        if (user?.emailVerified ?? false) {
          timer.cancel();
          _proceedToPasswordInput();
          return;
        }

        // Check for timeout (5 minutes)
        if (DateTime.now().difference(startTime) > maxPollingDuration) {
          timer.cancel();
          if (mounted) {
            setState(() {
              _isLoading = false;
              _loadingMessage = null;
              _showCancelButton = false;
              _buttonAnimationController.reverse();
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Verification timeout. Please try again or check your email.',
                ),
                duration: Duration(seconds: 5),
              ),
            );
          }
          return;
        }

        // Update loading message to show progress
        if (mounted && pollCount % 5 == 0) {
          setState(() {
            _loadingMessage = 'Still waiting for verification...';
          });
        }
      } catch (e) {
        debugPrint('Error during verification polling: $e');
        consecutiveErrors++;

        // Stop polling after too many consecutive errors
        if (consecutiveErrors >= maxConsecutiveErrors) {
          timer.cancel();
          if (mounted) {
            setState(() {
              _isLoading = false;
              _loadingMessage = null;
              _showCancelButton = false;
              _buttonAnimationController.reverse();
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Network error. Please check your connection and try again.',
                ),
                duration: Duration(seconds: 5),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
          return;
        }
      }
    });
  }

  void _proceedToPasswordInput() {
    if (!mounted) return;

    // For signup mode, navigate to SignupDetailsScreen
    if (_isSignupMode) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (context) =>
                  SignupDetailsScreen(email: _usernameController.text.trim()),
        ),
      );
      return;
    }

    // For login mode, show password input
    setState(() {
      _isLoading = false;
      _loadingMessage = null;
      _userFirstLetter =
          _usernameController.text.isNotEmpty
              ? _usernameController.text[0].toUpperCase()
              : 'U';
      _showUserAvatar = true;
      _showCancelButton = false;
      _buttonAnimationController.forward();
    });
  }

  void _handleFinalSubmit() async {
    final password = _passwordController.text;
    if (password.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      // Step 1: Sign in with email and password
      final userCredential = await _auth
          .signInWithEmailAndPassword(
            email: _usernameController.text.trim(),
            password: password,
          )
          .timeout(const Duration(seconds: 10));

      final userId = userCredential.user?.uid;
      if (userId == null) {
        throw Exception('Failed to get user ID');
      }

      // Step 2: Check if user profile exists in Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get()
          .timeout(const Duration(seconds: 10));

      if (!userDoc.exists) {
        // Profile doesn't exist - redirect to signup details screen
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(
            '/signup-details',
            arguments: _usernameController.text.trim(),
          );
        }
      }
      // If profile exists, StreamBuilder in AuthStateWrapper will automatically
      // navigate to ChatsScreen
    } on TimeoutException catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request timed out. Please try again.')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Authentication failed')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleCancel() async {
    _verificationTimer?.cancel();

    // If we are in signup mode and have created an account (user is signed in),
    // we should sign them out and optionally try to delete the account
    if (_isSignupMode && _auth.currentUser != null) {
      try {
        // Try to delete the account if it's not verified yet
        if (!(_auth.currentUser?.emailVerified ?? false)) {
          await _auth.currentUser!.delete();
        } else {
          // If somehow verified, just sign out
          await _auth.signOut();
        }
        _tempPassword = null;
      } catch (e) {
        debugPrint("Failed to delete temp user: $e");
        // If deletion fails, at least sign out
        try {
          await _auth.signOut();
        } catch (signOutError) {
          debugPrint("Failed to sign out: $signOutError");
        }
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        _loadingMessage = null;
        _showCancelButton = false;
        _buttonAnimationController.reverse();
      });
    }
  }

  void _handleBackPressed() async {
    // Cancel any ongoing operations
    _verificationTimer?.cancel();

    // Sign out if user is signed in (especially important in signup flow)
    if (_auth.currentUser != null) {
      try {
        await _auth.signOut();
      } catch (e) {
        debugPrint("Failed to sign out on back: $e");
      }
    }

    if (mounted) {
      setState(() {
        _showUserAvatar = false;
        _passwordController.clear();
        _usernameController.clear();
        _buttonAnimationController.reverse();
        _showCancelButton = false;
        _userFirstLetter = '';
        _loadingMessage = null;
        _isLoading = false;
        _tempPassword = null;
      });
    }
  }

  void _handleToggleMode() async {
    // Cancel any ongoing timers
    _verificationTimer?.cancel();

    // Sign out if user is signed in to ensure clean state
    if (_auth.currentUser != null) {
      try {
        await _auth.signOut();
      } catch (e) {
        debugPrint("Failed to sign out on toggle: $e");
      }
    }

    if (mounted) {
      setState(() {
        // Reset UI state
        _showUserAvatar = false;
        _showCancelButton = false;
        _isLoading = false;
        _loadingMessage = null;
        _passwordController.clear();
        _buttonAnimationController.reset();
        _tempPassword = null;

        if (_isSignupMode) {
          _isSignupMode = false;
          _subtitleText = 'Sign in to continue to your chats';
          _usernameHint = 'Enter email';
        } else {
          _isSignupMode = true;
          _subtitleText = 'Enter Your Email to Proceed';
          _usernameHint = 'Enter email';
          _showForm = true;
        }
      });
    }
  }

  @override
  void dispose() {
    typingTimer?.cancel();
    cursorTimer?.cancel();
    _verificationTimer?.cancel();
    _buttonAnimationController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Background is handled by NetworkOverlay (black) or Scaffold default

          // Animated network overlay
          const NetworkOverlay(nodeCount: 50, connectionDistance: 100.0),

          // Foreground content
          SafeArea(
            child: Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28.0,
                      vertical: 24.0,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 24,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Typewriter title
                          TypewriterWidget(
                            visibleText: visibleText,
                            showCursor: showCursor,
                          ),

                          const SizedBox(height: 12),

                          // Subtitle
                          SubtitleWidget(
                            text: _subtitleText,
                            isVisible: _showSubtitle,
                          ),

                          const SizedBox(height: 18),

                          // Input form
                          AuthInputWidget(
                            isVisible: _showForm,
                            showUserAvatar: _showUserAvatar,
                            isLoading: _isLoading,
                            loadingMessage: _loadingMessage,
                            isSignupMode: _isSignupMode,
                            userFirstLetter: _userFirstLetter,
                            usernameHint: _usernameHint,
                            usernameController: _usernameController,
                            passwordController: _passwordController,
                            buttonPositionAnimation: _buttonPositionAnimation,
                            buttonAnimationController:
                                _buttonAnimationController,
                            onSubmit: _handleSubmit,
                            onBackPressed: _handleBackPressed,
                            onCancel: _handleCancel,
                            showCancelButton: _showCancelButton,
                          ),

                          const SizedBox(height: 12),

                          // Signup/Login toggle
                          AuthToggleWidget(
                            isSignupMode: _isSignupMode,
                            onToggle: _handleToggleMode,
                          ),

                          const SizedBox(height: 6),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Logo at bottom center
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Hero(
                tag: 'app_logo',
                child: Image.asset('assets/whisp_logo.png', width: 60),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
