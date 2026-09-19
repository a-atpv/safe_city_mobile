import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/l10n.dart';
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
  bool _isHistoryLocationActive = false;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  RouteInformationProvider? _routeInformationProvider;
  
  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = GoRouter.of(context).routeInformationProvider;
    if (_routeInformationProvider != provider) {
      _routeInformationProvider?.removeListener(_onRouteInformationChanged);
      _routeInformationProvider = provider;
      _routeInformationProvider?.addListener(_onRouteInformationChanged);
      _onRouteInformationChanged();
    }
  }

  @override
  void dispose() {
    _routeInformationProvider?.removeListener(_onRouteInformationChanged);
    super.dispose();
  }
  
  Future<void> _fetchHistory({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    } else {
      setState(() => _error = null);
    }
    
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
        _error = context.l10n.historyLoadFailed;
        _isLoading = false;
      });
    }
  }

  void _triggerTabRefresh() {
    if (_calls.isNotEmpty) {
      _refreshIndicatorKey.currentState?.show();
    } else {
      _fetchHistory();
    }
  }

  void _onRouteInformationChanged() {
    final location = _routeInformationProvider?.value.uri.path ?? '';
    final isHistoryLocation = location.startsWith('/history');

    if (isHistoryLocation && !_isHistoryLocationActive) {
      _isHistoryLocationActive = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _triggerTabRefresh();
      });
    } else if (!isHistoryLocation && _isHistoryLocationActive) {
      _isHistoryLocationActive = false;
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
                context.l10n.historyTitle,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildFilterChip(context.l10n.historyFilterAll, 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip(context.l10n.historyFilterCompleted, 'completed'),
                  const SizedBox(width: 8),
                  _buildFilterChip(context.l10n.historyFilterCancelled, 'cancelled'),
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
                                child: Text(context.l10n.commonRetry),
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
                                    context.l10n.historyEmpty,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              key: _refreshIndicatorKey,
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
    
    final statusText = _statusLabel(status);
    final statusColor = _statusColor(status);
    
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
                        _statusIcon(status),
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
              context.l10n.historyDurationMinutes((durationSeconds / 60).ceil()),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
        ],
      ),
    );
  }
  
  String _statusLabel(String status) {
    final l10n = context.l10n;
    if (status == 'completed') return l10n.historyStatusCompleted;
    if (status.contains('cancelled')) return l10n.historyStatusCancelled;
    if (status == 'offer_sent') return l10n.historyStatusInProgress;
    return status;
  }

  Color _statusColor(String status) {
    if (status == 'completed') return AppColors.success;
    if (status.contains('cancelled')) return AppColors.textSecondary;
    return AppColors.primary;
  }

  IconData _statusIcon(String status) {
    if (status == 'completed') return Icons.check_circle;
    if (status.contains('cancelled')) return Icons.cancel;
    return Icons.timer_outlined;
  }

  /// «18 сентября 2026 г., 14:05» / «2026 ж. 18 қыркүйек, 14:05» /
  /// «September 18, 2026, 14:05» — порядок частей даты у каждого языка свой.
  String _formatDate(DateTime date) {
    final locale = context.l10n.localeName;
    return '${DateFormat.yMMMMd(locale).format(date)}, '
        '${DateFormat.Hm(locale).format(date)}';
  }
}
