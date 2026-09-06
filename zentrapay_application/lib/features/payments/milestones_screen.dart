import 'package:flutter/material.dart';
import 'package:zentrapay_application/features/home/repository/cache_homeData.dart';
import 'package:zentrapay_application/features/zbanking/repository/cache_zbankingData.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/main.dart';

// "Goals" are ZBank Lite savings accounts — there's no separate goals
// concept backend-side, this screen is just a savings-focused view.
class MilestonesScreen extends StatefulWidget {
  const MilestonesScreen({super.key});

  @override
  State<MilestonesScreen> createState() => _MilestonesScreenState();
}

class _MilestonesScreenState extends State<MilestonesScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> goals = [];

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals({bool forceRefresh = false}) async {
    setState(() => isLoading = true);
    try {
      // The wallet currency backs the "new goal" currencyCode, so load
      // wallets first to make [WalletsRepository.instance.defaultWallet]
      // available (the first caller triggers the GET).
      await WalletsRepository.instance.ensureLoaded();
      await SavingsRepository.instance.ensureLoaded(forceRefresh: forceRefresh);
      final accounts = SavingsRepository.instance.data ?? [];
      // "Goals" are just ZBank Lite savings accounts — there's no separate
      // goals concept backend-side (API_CONTRACT §13). Each account maps to
      // one goal; 'icon'/'autoSave' are filled so _buildGoalCard renders
      // without null derefs.
      goals = accounts
          .map(
            (s) => {
              'id': s.savingsId,
              'name': s.savingsName,
              'saved': s.balance,
              'target': s.targetAmount ?? 0.0,
              'currencyCode': s.currencyCode,
              'status': s.status,
              'icon': Icons.savings,
              'autoSave': false,
            },
          )
          .toList();
    } catch (_) {
      // Keep an empty list on failure rather than fabricating goals.
      goals = [];
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _showCreateGoalDialog() async {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final targetController = TextEditingController();

    final created = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New savings goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Goal name'),
            ),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Initial deposit (GHS)',
              ),
            ),
            TextField(
              controller: targetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Target amount (optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (created != true || nameController.text.trim().isEmpty) return;

    final initialDeposit = amountController.text.trim();
    final targetAmount = targetController.text.trim();
    final currencyCode =
        WalletsRepository.instance.defaultWallet?.currencyCode ?? 'GHS';
    try {
      await SavingsRepository.instance.create(
        savingsName: nameController.text.trim(),
        currencyCode: currencyCode,
        initialDeposit: initialDeposit,
        targetAmount: targetAmount.isEmpty ? null : targetAmount,
        targetDate: null,
        description: '',
      );
      // The repository already applied the create() response into its
      // cache; re-derive the local `goals` view from it (no refetch).
      _loadGoals();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not create goal. Try again.')),
        );
      }
    }
  }

  double get _totalSaved =>
      goals.fold(0.0, (sum, g) => sum + (g['saved'] as double));

  double get _topGoalProgress {
    if (goals.isEmpty) return 0;
    final top = goals.first;
    final target = top['target'] as double;
    if (target == 0) return 0;
    return ((top['saved'] as double) / target).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.gray50,
      appBar: AppBar(
        backgroundColor: AppColors.main,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "The Milestones",
          style: TextStyle(color: AppColors.primary, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeaderSection(),
            const SizedBox(height: 20),
            _buildGoalsList(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.main, AppColors.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "The Milestones",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const Text(
                    "Target Your Targets",
                    style: TextStyle(fontSize: 14, color: AppColors.primary),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "GHS ${_totalSaved.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const Text(
                    "Saved",
                    style: TextStyle(fontSize: 12, color: AppColors.primary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 30),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 180,
                height: 180,
                child: CircularProgressIndicator(
                  value: _topGoalProgress,
                  strokeWidth: 12,
                  backgroundColor: AppColors.primary.withAlpha(50),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.green,
                  ),
                ),
              ),
              Column(
                children: [
                  Text(
                    "${(_topGoalProgress * 100).toStringAsFixed(1)}%",
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    goals.isEmpty ? "No goals yet" : goals.first['name'],
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _showCreateGoalDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "+ New",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Save",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
          bottom: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "You set goals",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textBlack,
            ),
          ),
          const SizedBox(height: 16),
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (goals.isEmpty)
            const Text(
              "No savings goals yet — tap + New to start one.",
              style: TextStyle(fontSize: 13, color: AppColors.textBlack),
            )
          else
            ...goals.map((goal) => _buildGoalCard(goal)),
        ],
      ),
    );
  }

  Widget _buildGoalCard(Map<String, dynamic> goal) {
    final progress = goal['saved'] / goal['target'];
    final percentage = (progress * 100).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGrey.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.main.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(goal['icon'], color: AppColors.main, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal['name'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textBlack,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Auto-save: ${goal['autoSave'] ? 'Enabled' : 'Disabled'}",
                      style: TextStyle(fontSize: 12, color: AppColors.green),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.close,
                  color: AppColors.textBlack,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "GHS ${goal['target'].toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textBlack,
                ),
              ),
              Text(
                "$percentage% of Goal",
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.lightGrey,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.green),
            minHeight: 6,
          ),
        ],
      ),
    );
  }
}
