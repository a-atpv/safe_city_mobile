import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/api/api.dart';
import '../../../shared/widgets/widgets.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  List<Map<String, dynamic>> _calls = [];
  bool _isLoading = true;
  String? _error;
  String _filter = 'all';
  
  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }
  
  Future<void> _fetchHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final response = await ApiClient().dio.get('/emergency/history');
      
      if (response.statusCode == 200) {
        setState(() {
          _calls = List<Map<String, dynamic>>.from(response.data['calls']);
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Ошибка загрузки истории';
        _isLoading = false;
      });
    }
  }
  
  List<Map<String, dynamic>> get _filteredCalls {
    if (_filter == 'all') return _calls;
    if (_filter == 'completed') {
      return _calls.where((c) => c['status'] == 'completed').toList();
    }
    if (_filter == 'cancelled') {
      return _calls.where((c) => 
        c['status'] == 'cancelled_by_user' || 
        c['status'] == 'cancelled_by_system'
      ).toList();
    }
    return _calls;
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.backgroundGradient,
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'История вызовов',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildFilterChip('Все', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Завершённые', 'completed'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Отменённые', 'cancelled'),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_error!, style: const TextStyle(color: AppColors.error)),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _fetchHistory,
                                child: const Text('Повторить'),
                              ),
                            ],
                          ),
                        )
                      : _filteredCalls.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.history,
                                    size: 80,
                                    color: AppColors.textSecondary.withAlpha(127),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'История пуста',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _fetchHistory,
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                itemCount: _filteredCalls.length,
                                itemBuilder: (context, index) {
                                  return _buildCallCard(_filteredCalls[index]);
                                },
                              ),
                            ),
            ),
            
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.surfaceBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
  
  Widget _buildCallCard(Map<String, dynamic> call) {
    final status = call['status'] as String;
    final createdAt = DateTime.parse(call['created_at']);
    final durationSeconds = call['duration_seconds'] as int?;
    
    final isCompleted = status == 'completed';
    final isCancelled = status.contains('cancelled');
    
    final statusText = isCompleted ? 'Завершён' : (isCancelled ? 'Отменён' : status);
    final statusColor = isCompleted ? AppColors.success : AppColors.textSecondary;
    
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(createdAt),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(51),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCompleted ? Icons.check_circle : Icons.cancel,
                        color: statusColor,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          if (durationSeconds != null)
            Text(
              '${(durationSeconds / 60).ceil()} мин',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    final months = [
      'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
    ];
    final time = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return '${date.day} ${months[date.month - 1]} ${date.year}, $time';
  }
}
