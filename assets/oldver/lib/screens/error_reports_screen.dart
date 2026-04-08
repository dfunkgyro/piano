import 'package:flutter/cupertino.dart';
import '../services/aws_service.dart';

class ErrorReportsScreen extends StatefulWidget {
  const ErrorReportsScreen({super.key});

  @override
  State<ErrorReportsScreen> createState() => _ErrorReportsScreenState();
}

class _ErrorReportsScreenState extends State<ErrorReportsScreen> {
  final AwsService _aws = AwsService.instance;
  bool _loading = true;
  List<Map<String, dynamic>> _errors = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final errors = await _aws.getRecentErrors(limit: 50);
    setState(() {
      _errors = errors;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Crash Reports'),
      ),
      child: SafeArea(
        child: _loading
            ? const Center(child: CupertinoActivityIndicator())
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _errors.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = _errors[index];
                  final message = item['message'] ?? 'Unknown error';
                  final createdAt = item['createdAt'] ?? '';
                  final platform = item['platform'] ?? '';
                  final appVersion = item['appVersion'] ?? '';
                  final stack = (item['stack'] ?? '').toString();
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$createdAt • $platform • $appVersion',
                          style: const TextStyle(
                            fontSize: 12,
                            color: CupertinoColors.systemGrey,
                          ),
                        ),
                        if (stack.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            stack.length > 500
                                ? '${stack.substring(0, 500)}…'
                                : stack,
                            style: const TextStyle(
                              fontSize: 11,
                              color: CupertinoColors.systemGrey2,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
