import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'model/accounting_models.dart';
import 'screen/registar.dart';
import 'screen/management.dart';
import 'screen/setting.dart';
import 'screen/serve.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  try {
    await FirebaseAuth.instance.signInAnonymously();
  } catch (e) {
    debugPrint("Firebase Auth Error: $e");
  }
  runApp(const AccountingApp());
}

class AccountingApp extends StatelessWidget {
  const AccountingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '学祭レジアプリ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  final CollectionReference _productsRef = FirebaseFirestore.instance.collection('products');
  final CollectionReference _historyRef = FirebaseFirestore.instance.collection('history');
  final DocumentReference _counterRef = FirebaseFirestore.instance.collection('system').doc('counter');

  // 商品追加メソッド
  Future<void> _addProduct(String name, int price, List<Topping> toppings) async {
    await _productsRef.add({
      'name': name,
      'price': price,
      'toppings': toppings.map((t) => t.toMap()).toList(),
    });
  }

  // 商品削除メソッド
  Future<void> _removeProduct(String id) async {
    await _productsRef.doc(id).delete();
  }

  // 会計確定処理 (整理券番号のループ採番 & 提供状況初期化)
  Future<int> _completeTransaction(List<Product> products) async {
    return FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot counterSnap = await transaction.get(_counterRef);
      int nextNum = 1;
      if (counterSnap.exists) {
        int lastNum = (counterSnap.data() as Map<String, dynamic>)['lastQueueNumber'] ?? 0;
        nextNum = (lastNum % 20) + 1;
      }
      transaction.set(_counterRef, {'lastQueueNumber': nextNum});

      List<String> items = [];
      int total = 0;
      for (var p in products) {
        if (p.currentOrderCount > 0) {
          String detail = '${p.name} x${p.currentOrderCount}';
          total += p.price * p.currentOrderCount;
          for (var t in p.toppings) {
            if (t.currentOrderCount > 0) {
              detail += ' [+${t.name} x${t.currentOrderCount}]';
              total += t.price * t.currentOrderCount;
            }
          }
          items.add(detail);
        }
      }

      if (items.isNotEmpty) {
        await _historyRef.add({
          'timestamp': FieldValue.serverTimestamp(),
          'itemsSummary': items,
          'totalAmount': total,
          'queueNumber': nextNum,
          'isServed': false, // 初期状態は未提供
        });
      }

      return nextNum;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _productsRef.snapshots(),
      builder: (context, productSnapshot) {
        if (!productSnapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final products = productSnapshot.data!.docs.map((doc) => Product.fromFirestore(doc)).toList();

        return StreamBuilder<QuerySnapshot>(
          stream: _historyRef.orderBy('timestamp', descending: true).snapshots(),
          builder: (context, historySnapshot) {
            final history = historySnapshot.hasData
                ? historySnapshot.data!.docs.map((doc) => SaleRecord.fromFirestore(doc)).toList()
                : <SaleRecord>[];

            final List<Widget> screens = [
              RegisterScreen(
                products: products,
                onComplete: _completeTransaction,
              ),
              ServeScreen(
                history: history,
              ),
              SalesHistoryScreen(
                history: history,
                onDelete: (id) => _historyRef.doc(id).delete(),
              ),
              ProductSettingsScreen(
                products: products,
                onAdd: _addProduct,
                onRemove: (index) => _removeProduct(products[index].id),
              ),
            ];

            return Scaffold(
              body: IndexedStack(index: _selectedIndex, children: screens),
              bottomNavigationBar: BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: (index) => setState(() => _selectedIndex = index),
                selectedItemColor: Colors.green.shade700,
                unselectedItemColor: Colors.grey,
                type: BottomNavigationBarType.fixed,
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: 'レジ'),
                  BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: '提供'),
                  BottomNavigationBarItem(icon: Icon(Icons.history), label: '履歴'),
                  BottomNavigationBarItem(icon: Icon(Icons.settings), label: '設定'),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
