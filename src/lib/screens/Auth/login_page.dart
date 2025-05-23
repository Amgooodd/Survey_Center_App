import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_questionnaire/providers/user_provider.dart';
import 'package:student_questionnaire/screens/AppStart/Welcome_screen.dart';
import '../StudHome/student_home.dart';

class CombinedLogin extends StatefulWidget {
  const CombinedLogin({super.key});

  @override
  _CombinedLoginState createState() => _CombinedLoginState();
}

class _CombinedLoginState extends State<CombinedLogin> {
  final TextEditingController _idController = TextEditingController();
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedId();
    _checkExistingLogin();
  }

  Future<void> _checkExistingLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

    if (isLoggedIn) {
      final userType = prefs.getString('user_type');
      final userId = prefs.getString('user_id');

      if (userType == 'student' && userId != null) {
        final studentGroup =
            prefs.getString('student_group') ?? 'default_group';
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => StudentForm(
              studentId: userId,
              studentGroup: studentGroup,
            ),
          ),
        );
      } else if (userType == 'admin' && userId != null) {
        
        final adminDoc = await FirebaseFirestore.instance
            .collection('admins')
            .doc(userId)
            .get();
        final isSuperAdmin = adminDoc.exists
            ? (adminDoc.data()?['isSuperAdmin'] ?? false)
            : false;

        Navigator.pushReplacementNamed(context, '/firsrforadminn', arguments: {
          'adminId': userId,
          'isSuperAdmin': isSuperAdmin,
        });
      }
    }
  }

  Future<void> _loadSavedId() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString('saved_id');
    if (savedId != null) {
      setState(() {
        _idController.text = savedId;
        _rememberMe = true;
      });
    }
  }

  Future<void> _saveId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('saved_id', id);
    } else {
      await prefs.remove('saved_id');
    }
  }

  void _validateId() async {
    final id = _idController.text.trim();
    if (id.isEmpty) return;

    await _saveId(id);
    final adminDoc = await FirebaseFirestore.instance.collection('admins').doc(id).get();
if (adminDoc.exists) {
  final hasEmail = (adminDoc.data()?['email'] ?? '').isNotEmpty;
  final isEmailVerified = adminDoc.data()?['isEmailVerified'] ?? false;

     if (hasEmail && !isEmailVerified) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PasswordResetPage(adminId: id),
        ),
      );
      return;
    }

    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminLoginPage(
          adminId: id,
          isFirstLogin: !hasEmail,
        ),
      ),
    );
    return;
  }
    final studentDoc =
        await FirebaseFirestore.instance.collection('students').doc(id).get();
    final isStudent = studentDoc.exists;
    if (isStudent) {
      final snapshot =
          await FirebaseFirestore.instance.collection('students').doc(id).get();
      final studentGroup = snapshot.data()?['group'] ?? 'default_group';

      if (_rememberMe) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', true);
        await prefs.setString('user_type', 'student');
        await prefs.setString('user_id', id);
        await prefs.setString('student_group', studentGroup);
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => StudentForm(
            studentId: id,
            studentGroup: studentGroup,
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invalid ID. Please try again.')),
    );
  }

Future<void> _showTutorialAgain() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('dont_show_onboarding'); 
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => FirstImageScreen()),
    );
  }

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 28, 51, 95),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: _showTutorialAgain, 
            tooltip: 'Show Tutorial',
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Enter Your ID',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 28, 51, 95)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _idController,
              decoration: const InputDecoration(
                labelText: 'Enter your ID',
                labelStyle: TextStyle(
                  color: const Color.fromARGB(255, 28, 51, 95),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: const Color.fromARGB(255, 28, 51, 95), width: 2.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: const Color.fromARGB(255, 28, 51, 95), width: 1.0),
                ),
                border: OutlineInputBorder(),
              ),
              onEditingComplete: _validateId,
            ),
            Row(
              children: [
                Checkbox(
                  value: _rememberMe,
                  checkColor: Colors.white,
                  activeColor: Color.fromARGB(255, 28, 51, 95),
                  onChanged: (value) {
                    setState(() {
                      _rememberMe = value ?? false;
                    });
                  },
                ),
                Text(
                  'Remember Me',
                  style: TextStyle(
                    color: const Color.fromARGB(255, 28, 51, 95),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _validateId,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 253, 200, 0),
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child:
                  const Text('Submit', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminLoginPage extends StatefulWidget {
  final String adminId;
  final bool isFirstLogin;

  const AdminLoginPage(
      {required this.adminId, required this.isFirstLogin, super.key});

  @override
  _AdminLoginPageState createState() => _AdminLoginPageState();
}

bool _obscurePassword = true;

class _AdminLoginPageState extends State<AdminLoginPage> {
  final TextEditingController _passwordController = TextEditingController();
  String? _defaultPassword;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    if (widget.isFirstLogin) {
      _fetchDefaultPassword();
    }
  }

  Future<void> _fetchDefaultPassword() async {
    try {
      final adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(widget.adminId)
          .get();
      if (adminDoc.exists) {
        setState(() {
          _defaultPassword = adminDoc.data()?['defaultPassword'] as String?;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching default password: $e')),
      );
    }
  }

  Future<void> _loadSavedCredentials() async {
    if (widget.isFirstLogin) return;

    final prefs = await SharedPreferences.getInstance();
    final savedAdminId = prefs.getString('admin_id');
    final savedPassword = prefs.getString('admin_password');

    if (savedAdminId == widget.adminId && savedPassword != null) {
      setState(() {
        _passwordController.text = savedPassword;
        _rememberMe = true;
      });
    }
  }

  Future<void> _saveCredentials(String password) async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('admin_id', widget.adminId);
      await prefs.setString('admin_password', password);
    } else {
      await prefs.remove('admin_id');
      await prefs.remove('admin_password');
    }
  }

  void _handleLogin() async {
    final input = _passwordController.text.trim();

    if (!widget.isFirstLogin) {
      await _saveCredentials(input);
    }

    if (widget.isFirstLogin) {
      if (_defaultPassword == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Default password not configured')),
        );
        return;
      }

      if (input != _defaultPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wrong default password!')),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PasswordResetPage(adminId: widget.adminId),
        ),
      );
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(widget.adminId)
          .get();

      final email = doc.data()?['email'] as String?;

      
      if (email == null) throw Exception('Email not found in database');

      final userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: input,
      );
      bool isSuperAdmin = doc.data()?['isSuperAdmin'] ?? false;

      if (!userCredential.user!.emailVerified) {
        await FirebaseAuth.instance.signOut();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please verify your email first')),
        );
        return;
      }

      if (_rememberMe) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', true);
        await prefs.setString('user_type', 'admin');
        await prefs.setString('user_id', widget.adminId);
      }

      
      Provider.of<UserProvider>(context, listen: false)
          .setSuperAdmin(isSuperAdmin);

      Navigator.pushReplacementNamed(
        context,
        '/firsrforadminn',
        arguments: {
          'adminId': widget.adminId,
          'isSuperAdmin': isSuperAdmin,
        },
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Authentication error: ${e.message ?? 'Unknown error'}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _handleForgotPassword() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(widget.adminId)
          .get();

      final email = doc.data()?['email'] as String?;
      if (email == null)
        throw Exception('No email associated with this account');

      final maskEmail = _maskEmail(email);

      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset email sent to $maskEmail'),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  String _maskEmail(String email) {
    try {
      final parts = email.split('@');
      if (parts.length != 2) return email;

      final localPart = parts[0];
      final domain = parts[1];

      if (localPart.length <= 3) {
        return '${'*' * localPart.length}@$domain';
      }

      final visiblePart = localPart.substring(0, 3);
      final maskedPart = '*' * (localPart.length - 3);
      return '$visiblePart$maskedPart@$domain';
    } catch (e) {
      return '*****@*****';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Login', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 28, 51, 95),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => CombinedLogin()),
            );
          },
        ),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.isFirstLogin
                  ? 'Enter Default Password'
                  : 'Enter Your Password',
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 28, 51, 95)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText:
                    widget.isFirstLogin ? 'Default Password' : 'Password',
                labelStyle: TextStyle(
                  color: const Color.fromARGB(255, 28, 51, 95),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: const Color.fromARGB(255, 28, 51, 95), width: 2.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: const Color.fromARGB(255, 28, 51, 95), width: 1.0),
                ),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              onSubmitted: (_) => _handleLogin(),
            ),
            if (!widget.isFirstLogin)
              Row(
                children: [
                  Checkbox(
                    checkColor: Colors.white,
                    activeColor: Color.fromARGB(255, 28, 51, 95),
                    value: _rememberMe,
                    onChanged: (value) {
                      setState(() {
                        _rememberMe = value ?? false;
                      });
                    },
                  ),
                  Text('Remember Me'),
                ],
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 253, 200, 0),
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: Text(widget.isFirstLogin ? 'Continue' : 'Login',
                  style: const TextStyle(color: Colors.black)),
            ),
            if (!widget.isFirstLogin)
              TextButton(
                onPressed: _handleForgotPassword,
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: const Color.fromARGB(255, 28, 51, 95),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class PasswordResetPage extends StatefulWidget {
  final String adminId;

  const PasswordResetPage({Key? key, required this.adminId}) : super(key: key);

  @override
  _PasswordResetPageState createState() => _PasswordResetPageState();
}

class _PasswordResetPageState extends State<PasswordResetPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();
  bool _isEmailSent = false;
  bool _isEmailVerified = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  final Color _primaryColor = const Color.fromARGB(255, 28, 51, 95);
  final Color _accentColor = const Color.fromARGB(255, 253, 200, 0);

Future<void> _updateAdminEmail(String email) async {
  try {
    await FirebaseFirestore.instance
        .collection('admins')
        .doc(widget.adminId)
        .update({
          'email': email,
          'isEmailVerified': false, 
        });
  } catch (e) {
    throw Exception('Failed to update admin email');
  }
}
User? _previousUser;
  Future<void> _sendVerificationEmail() async {
    final email = _emailController.text.trim();
    final newPass = _newPassController.text.trim();
    final confirmPass = _confirmPassController.text.trim();

    if (email.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    if (newPass != confirmPass) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match!')),
      );
      return;
    }

   try {
    
    if (_previousUser != null) {
      await _previousUser!.delete();
      _previousUser = null;
    }

    final userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: newPass);
    _previousUser = userCredential.user;

    await _updateAdminEmail(email);
    await userCredential.user!.sendEmailVerification();
    setState(() => _isEmailSent = true);
  } catch (e) {
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${e.toString()}')),
    );
  }
}Future<void> _checkEmailVerification() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  try {
    await user.reload(); 
    if (user.emailVerified) {
      
      await FirebaseFirestore.instance
          .collection('admins')
          .doc(widget.adminId)
          .update({'isEmailVerified': true});

      
      setState(() => _isEmailVerified = true);

      
      await Future.delayed(const Duration(seconds: 2));

      
      Navigator.popUntil(context, (route) => route.isFirst);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email not verified yet. Check your inbox.'),
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}
  @override
void initState() {
  super.initState();
  _checkAdminVerificationStatus();
}

Future<void> _checkAdminVerificationStatus() async {
  final adminDoc = await FirebaseFirestore.instance
      .collection('admins')
      .doc(widget.adminId)
      .get();
  final email = adminDoc.data()?['email'] as String?;
  final isEmailVerified = adminDoc.data()?['isEmailVerified'] ?? false;

  if (email != null && email.isNotEmpty && !isEmailVerified) {
    setState(() {
      _isEmailSent = true;
      _emailController.text = email;
    });
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Account Setup', style: TextStyle(color: Colors.white)),
        backgroundColor: _primaryColor,
        centerTitle: true,
        automaticallyImplyLeading: false, 
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_isEmailSent && !_isEmailVerified)
              _buildSetupForm()
            else if (_isEmailSent && !_isEmailVerified)
              _buildVerificationPending()
            else
              _buildSuccessScreen()
          ],
        ),
      ),
    );
  }

  Widget _buildSetupForm() {
    return Column(
      children: [
        const Text(
          'Create Your Account',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 30),
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            labelStyle: TextStyle(
              color: const Color.fromARGB(255, 28, 51, 95),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                  color: const Color.fromARGB(255, 28, 51, 95), width: 2.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                  color: const Color.fromARGB(255, 28, 51, 95), width: 1.0),
            ),
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.email),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _newPassController,
          obscureText: _obscureNewPassword,
          decoration: InputDecoration(
            labelText: 'New Password',
            labelStyle: TextStyle(
              color: const Color.fromARGB(255, 28, 51, 95),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                  color: const Color.fromARGB(255, 28, 51, 95), width: 2.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                  color: const Color.fromARGB(255, 28, 51, 95), width: 1.0),
            ),
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.lock),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _obscureNewPassword = !_obscureNewPassword;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirmPassController,
          obscureText: _obscureConfirmPassword,
          decoration: InputDecoration(
            labelText: 'Confirm Password',
            labelStyle: TextStyle(
              color: const Color.fromARGB(255, 28, 51, 95),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                  color: const Color.fromARGB(255, 28, 51, 95), width: 2.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                  color: const Color.fromARGB(255, 28, 51, 95), width: 1.0),
            ),
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: _sendVerificationEmail,
          style: ElevatedButton.styleFrom(
            backgroundColor: _accentColor,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            textStyle: const TextStyle(fontSize: 18),
          ),
          child:
              const Text('Verify Email', style: TextStyle(color: Colors.black)),
        ),
      ],
    );
  }

Widget _buildVerificationPending() {
    return Column(
      children: [
        const Icon(
          Icons.mark_email_read,
          size: 80,
          color: Color.fromARGB(255, 253, 200, 0),
        ),
        const SizedBox(height: 20),
        const Text(
          'Check Your Inbox!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'We\'ve sent a verification link to your email address. '
            'Please click the link to verify your account.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: _checkEmailVerification,
          style: ElevatedButton.styleFrom(
            backgroundColor: _accentColor,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            textStyle: const TextStyle(fontSize: 18),
          ),
          child: const Text('I\'ve Verified My Email',
              style: TextStyle(color: Colors.black)),
        ),
        const SizedBox(height: 15),
        TextButton(
  onPressed: () async {
    if (_previousUser != null) {
      try {
        
        await _previousUser!.delete();
        
        
        await FirebaseFirestore.instance
            .collection('admins')
            .doc(widget.adminId)
            .update({
              'email': FieldValue.delete(), 
              'isEmailVerified': false,
            });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting account: $e')),
        );
      }
      _previousUser = null;
    }
    setState(() => _isEmailSent = false);
  },
  child: const Text(
    'Edit Email Address',
    style: TextStyle(color: Color.fromARGB(255, 28, 51, 95)),
  ),
)
      ],
    );
  }

  Widget _buildSuccessScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, size: 100, color: Colors.green),
          const SizedBox(height: 20),
          const Text(
            'Account Verified!',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          CircularProgressIndicator(
            color: _accentColor,
          ),
          const SizedBox(height: 20),
          const Text(
            'Redirecting to login...',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}

Future<void> logout(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  
  
  final bool dontShowOnboarding = prefs.getBool('dont_show_onboarding') ?? false;
  
  
  await prefs.clear();
  
  
  if (dontShowOnboarding) {
    await prefs.setBool('dont_show_onboarding', true);
  }
  
  
  await FirebaseAuth.instance.signOut();

  
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (context) => const CombinedLogin()),
    (route) => false,
  );
}
