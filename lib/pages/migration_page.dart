import 'package:flutter/material.dart';
import 'package:food_delivery_fbase/components/my_button.dart';
import 'package:food_delivery_fbase/utils/data_migration.dart';

class MigrationPage extends StatefulWidget {
  const MigrationPage({super.key});

  @override
  State<MigrationPage> createState() => _MigrationPageState();
}

class _MigrationPageState extends State<MigrationPage> {
  bool _isLoading = false;
  bool _hasData = false;
  String _status = '';

  @override
  void initState() {
    super.initState();
    _checkDataStatus();
  }

  Future<void> _checkDataStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final hasData = await DataMigration.hasDataInFirestore();
      setState(() {
        _hasData = hasData;
        _status = hasData ? 'Đã có dữ liệu trong Firestore' : 'Chưa có dữ liệu trong Firestore';
      });
    } catch (e) {
      setState(() {
        _status = 'Lỗi khi kiểm tra: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _runMigration() async {
    setState(() {
      _isLoading = true;
      _status = 'Đang migrate dữ liệu...';
    });

    try {
      await DataMigration.migrateHardcodedDataToFirestore();
      setState(() {
        _status = 'Migration hoàn thành!';
        _hasData = true;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Migration thành công!')),
        );
      }
    } catch (e) {
      setState(() {
        _status = 'Lỗi migration: $e';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi migration: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Migration'),
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.storage,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            
            const Text(
              'Data Migration',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            const Text(
              'Chuyển dữ liệu từ hardcoded sang Firebase Firestore',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // Status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _hasData ? Colors.green[50] : Colors.orange[50],
                border: Border.all(
                  color: _hasData ? Colors.green : Colors.orange,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Icon(
                    _hasData ? Icons.check_circle : Icons.warning,
                    color: _hasData ? Colors.green : Colors.orange,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _status,
                    style: TextStyle(
                      color: _hasData ? Colors.green[800] : Colors.orange[800],
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Migration button
            MyButton(
              text: _isLoading ? 'Đang xử lý...' : 'Chạy Migration',
              onTap: _isLoading || _hasData ? null : _runMigration,
            ),
            
            const SizedBox(height: 16),
            
            // Refresh button
            MyButton(
              text: 'Kiểm tra lại',
              onTap: _isLoading ? null : _checkDataStatus,
            ),
            
            const SizedBox(height: 24),
            
            const Text(
              'Lưu ý: Migration chỉ nên chạy một lần. Nếu đã có dữ liệu trong Firestore, không nên chạy lại.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}


