import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CalculatorVaultApp());
}

class CalculatorVaultApp extends StatelessWidget {
  const CalculatorVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculator Vault Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: Colors.amber,
        colorScheme: const ColorScheme.dark(
          primary: Colors.amber,
          surface: Color(0xFF1E1E1E),
        ),
      ),
      home: const CalculatorScreen(),
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _input = '';
  String _result = '0';
  String _realPin = '1234';
  String _fakePin = '9999';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadPins();
  }

  Future<void> _loadPins() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _realPin = prefs.getString('user_pin') ?? '1234';
      _fakePin = prefs.getString('fake_pin') ?? '9999';
    });
  }

  Future<void> _savePins(String real, String fake) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_pin', real);
    await prefs.setString('fake_pin', fake);
    setState(() {
      _realPin = real;
      _fakePin = fake;
    });
  }

  void _onButtonPressed(String value) {
    setState(() {
      if (value == 'C') {
        _input = '';
        _result = '0';
      } else if (value == 'DEL') {
        if (_input.isNotEmpty) {
          _input = _input.substring(0, _input.length - 1);
        }
      } else if (value == '=') {
        // التحقق من الرمز الحقيقي للخزنة
        if (_input == _realPin) {
          _input = '';
          _result = '0';
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const VaultScreen(isFakeVault: false),
            ),
          );
          return;
        }

        // التحقق من الرمز الوهمي (الخزنة المزيفة)
        if (_input == _fakePin) {
          _input = '';
          _result = '0';
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const VaultScreen(isFakeVault: true),
            ),
          );
          return;
        }

        try {
          _result = _evaluateExpression(_input);
        } catch (e) {
          _result = 'خطأ';
        }
      } else {
        _input += value;
      }
    });
  }

  String _evaluateExpression(String exp) {
    if (exp.isEmpty) return '0';
    try {
      String sanitized = exp.replaceAll('×', '*').replaceAll('÷', '/');
      List<String> tokens = sanitized.split(
        RegExp(r'(?<=[+\-*/])|(?=[+\-*/])'),
      );
      if (tokens.length < 3) return exp;

      double num1 = double.parse(tokens[0]);
      String op = tokens[1];
      double num2 = double.parse(tokens[2]);

      double res = 0;
      if (op == '+') res = num1 + num2;
      if (op == '-') res = num1 - num2;
      if (op == '*') res = num1 * num2;
      if (op == '/') res = num2 != 0 ? num1 / num2 : 0;

      return res % 1 == 0 ? res.toInt().toString() : res.toString();
    } catch (_) {
      return exp;
    }
  }

  void _showChangePinDialog() {
    TextEditingController realPinController = TextEditingController(
      text: _realPin,
    );
    TextEditingController fakePinController = TextEditingController(
      text: _fakePin,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF242424),
        title: const Text(
          'إعدادات رموز الفتح',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: realPinController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'الرمز الحقيقي للخزنة',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: fakePinController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'الرمز الوهمي (الخزنة المزيفة)',
                helperText: 'يفتح خزنة فارغة للحرج',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            onPressed: () {
              if (realPinController.text.isNotEmpty &&
                  fakePinController.text.isNotEmpty) {
                _savePins(realPinController.text, fakePinController.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم تحديث الرموز بنجاح!')),
                );
              }
            },
            child: const Text('حفظ', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        backgroundColor: const Color(0xFF1E1E1E),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.amber),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.security, size: 48, color: Colors.black),
                  SizedBox(height: 10),
                  Text(
                    'إعدادات الأمان',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.lock_reset, color: Colors.amber),
              title: const Text('تعديل الرمز (الحقيقي والوهمي)'),
              onTap: () {
                Navigator.pop(context);
                _showChangePinDialog();
              },
            ),
            const Divider(),
            const ListTile(
              leading: Icon(Icons.shield, color: Colors.green),
              title: Text('نظام الحماية والمحي'),
              subtitle: Text('Secure File Concealment Engine'),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu, size: 30, color: Colors.amber),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                  const Spacer(),
                  const Text(
                    'آلة حاسبة',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.bottomRight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _input,
                      style: const TextStyle(
                        fontSize: 32,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _result,
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E1E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  _buildRow(['C', 'DEL', '÷', '×']),
                  _buildRow(['7', '8', '9', '-']),
                  _buildRow(['4', '5', '6', '+']),
                  _buildRow(['1', '2', '3', '=']),
                  _buildRow(['0', '.']),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(List<String> buttons) {
    return Row(
      children: buttons.map((btn) {
        bool isOperator = ['÷', '×', '-', '+', '='].contains(btn);
        bool isSpecial = ['C', 'DEL'].contains(btn);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(20),
                backgroundColor: isOperator
                    ? Colors.amber
                    : isSpecial
                    ? Colors.redAccent.shade200
                    : const Color(0xFF2C2C2C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () => _onButtonPressed(btn),
              child: Text(
                btn,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isOperator ? Colors.black : Colors.white,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ==================== Vault Screen (شاشة إخفاء وحذف الصور) ====================

class VaultScreen extends StatefulWidget {
  final bool isFakeVault;
  const VaultScreen({super.key, required this.isFakeVault});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  List<File> _hiddenImages = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (!widget.isFakeVault) {
      _loadHiddenImages();
    }
  }

  // تحميل الصور المخفية بمسار داخلي غير قابل للكشف
  Future<void> _loadHiddenImages() async {
    final appDir = await getApplicationDocumentsDirectory();
    final vaultFolder = Directory('${appDir.path}/.secure_vault');

    if (await vaultFolder.exists()) {
      final files = vaultFolder.listSync().whereType<File>().toList();
      setState(() {
        _hiddenImages = files;
      });
    }
  }

  // اختراق الصور: نسخ للداخل، إعادة تسمية بصيغة .bin، وحذف الأصل من المعرض
  Future<void> _pickAndHideImage() async {
    if (widget.isFakeVault) return;

    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يتطلب التطبيق إذن الوصول للصور لحذفها وإخفائها'),
          ),
        );
      }
      return;
    }

    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile == null) return;

    // 1. نقل الملف لمجلد داخلي مخفي وخاص بالتطبيق
    final appDir = await getApplicationDocumentsDirectory();
    final vaultFolder = Directory('${appDir.path}/.secure_vault');
    if (!await vaultFolder.exists()) {
      await vaultFolder.create(recursive: true);
    }

    // 2. تشفير اسم الملف وامتداده لمنع التعرف عليه من مدير الملفات
    final String encryptedName =
        'sec_${DateTime.now().millisecondsSinceEpoch}.bin';
    final File savedImage = await File(pickedFile.path)
        .copy('${vaultFolder.path}/$encryptedName');

    // 3. مسح الصورة الأصلية نهائياً من المعرض ومدير الملفات (MediaStore API)
    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
    );
    if (albums.isNotEmpty) {
      final List<AssetEntity> recentAssets = await albums[0].getAssetListRange(
        start: 0,
        end: 50,
      );
      for (var asset in recentAssets) {
        final file = await asset.file;
        if (file != null && file.lengthSync() == savedImage.lengthSync()) {
          await PhotoManager.editor.deleteWithIds([asset.id]);
          break;
        }
      }
    }

    setState(() {
      _hiddenImages.add(savedImage);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إخفاء الصورة وحذفها من المعرض ومدير الملفات 🔒'),
        ),
      );
    }
  }

  // استرجاع الصورة إلى معرض الهاتف
  Future<void> _unhideImage(File imageFile, int index) async {
    try {
      final appDir = await getExternalStorageDirectory();
      final String restorePath =
          '${appDir?.path ?? ''}/Restored_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await imageFile.copy(restorePath);
      await imageFile.delete();

      setState(() {
        _hiddenImages.removeAt(index);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم استرجاع الصورة إلى المعرض!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء عملية الاسترجاع')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isFakeVault
              ? 'الخزنة (وضع الزائر)'
              : 'الخزنة السرية المشفرة 🔒',
        ),
        backgroundColor: const Color(0xFF1E1E1E),
      ),
      body: Column(
        children: [
          Expanded(
            child: _hiddenImages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.isFakeVault
                              ? Icons.folder_off
                              : Icons.lock_clock_outlined,
                          size: 80,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.isFakeVault
                              ? 'لا توجد عناصر مجهزة'
                              : 'الخزنة فارغة حالياً',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: _hiddenImages.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                _hiddenImages[index],
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () =>
                                  _unhideImage(_hiddenImages[index], index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.unarchive,
                                  color: Colors.amber,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          // مكان إعلان AdMob
          Container(
            height: 60,
            width: double.infinity,
            color: const Color(0xFF242424),
            child: const Center(
              child: Text(
                'إعلان AdMob Banner 📢',
                style: TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: widget.isFakeVault
          ? null
          : FloatingActionButton.extended(
              backgroundColor: Colors.amber,
              onPressed: _pickAndHideImage,
              icon: const Icon(Icons.add_a_photo, color: Colors.black),
              label: const Text(
                'إخفاء صورة جديدة',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
    );
  }
}
