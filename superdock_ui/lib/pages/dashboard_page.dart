import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/models/action_history.dart';
import '../core/models/connection_status.dart';
import '../core/models/dock_action.dart';
import '../core/models/process_info.dart';
import '../core/models/system_stats.dart';
import '../core/models/terminal_output.dart';
import '../core/models/workspace.dart';
import '../core/services/api.dart';
import '../core/services/backend_launcher.dart';
import '../core/services/settings_service.dart';
import '../core/services/terminal_stream_service.dart';
import '../core/theme/colors.dart';
import '../core/theme/spacing.dart';
import '../widgets/dock_button.dart';
import '../widgets/glass_card.dart';
import '../widgets/section_title.dart';
import '../widgets/settings_dialog.dart';
import '../widgets/status_card.dart';
import '../widgets/workspace_card.dart';
import '../widgets/workspace_dialog.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _settingsService = SettingsService();
  SuperDockApi _api = SuperDockApi();
  late TerminalStreamService _terminalStream;
  AppSettings _settings = const AppSettings(
    backendUrl: SettingsService.defaultBackendUrl,
  );

  int _selectedNav = 0;
  Timer? _pollTimer;
  StreamSubscription<TerminalOutput>? _terminalSubscription;
  bool _terminalStreamConnected = false;

  ConnectionStatus? _status;
  SystemStats? _systemStats;
  List<ProcessInfo> _processes = [];
  List<ActionHistoryEntry> _history = [];
  TerminalOutput? _terminal;
  List<Workspace> _workspaces = [];
  List<DockAction> _dockActions = [];
  bool _backendConnected = false;
  String? _loadingActionId;
  String? _loadingWorkspaceId;

  @override
  void initState() {
    super.initState();
    _terminalStream = TerminalStreamService(_api);
    _initialize();
  }

  Future<void> _initialize() async {
    final settings = await _settingsService.load();
    if (!mounted) return;

    setState(() {
      _settings = settings;
      _api = SuperDockApi(baseUrl: settings.backendUrl);
      _terminalStream = TerminalStreamService(_api);
    });

    if (settings.autoStartBackend) {
      await BackendLauncher.ensureRunning(
        baseUrl: settings.backendUrl,
        corePath: settings.backendCorePath,
      );
    }

    await _connectTerminalStream();
    await _syncBackendConfig();
    await _loadActions();
    await _loadWorkspaces();
    await _refresh();

    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _refresh());
  }

  Future<void> _connectTerminalStream() async {
    await _terminalSubscription?.cancel();
    _terminalSubscription = null;

    try {
      await _terminalStream.connect();
      _terminalSubscription = _terminalStream.stream.listen((output) {
        if (!mounted) return;
        setState(() {
          _terminal = output;
          _terminalStreamConnected = true;
        });
      });
      if (mounted) setState(() => _terminalStreamConnected = true);
    } catch (_) {
      if (mounted) setState(() => _terminalStreamConnected = false);
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _terminalSubscription?.cancel();
    _terminalStream.dispose();
    super.dispose();
  }

  Future<void> _syncBackendConfig() async {
    final payload = <String, dynamic>{};
    final flutterPath = _settings.flutterProjectPath;
    final gitPath = _settings.gitProjectPath;

    if (flutterPath != null && flutterPath.isNotEmpty) {
      payload['flutterProjectPath'] = flutterPath;
    }
    if (gitPath != null && gitPath.isNotEmpty) {
      payload['gitProjectPath'] = gitPath;
    }
    if (payload.isEmpty) return;

    try {
      await _api.updateConfig(payload);
    } catch (_) {
      // Backend may be offline during startup.
    }
  }

  Future<void> _loadActions() async {
    try {
      final actions = await _api.getActions();
      if (!mounted) return;
      setState(() => _dockActions = actions);
    } catch (error) {
      _showError('Could not load actions: $error');
    }
  }

  Future<void> _loadWorkspaces() async {
    try {
      final workspaces = await _api.getWorkspaces();
      if (!mounted) return;
      setState(() => _workspaces = workspaces);
    } catch (error) {
      _showError('Could not load workspaces: $error');
    }
  }

  Future<void> _refresh() async {
    var statusOk = false;

    try {
      final status = await _api.getStatus();
      statusOk = true;
      if (mounted) setState(() => _status = status);
    } catch (_) {}

    final refreshTasks = <Future<void>>[
      _api.getSystemStats().then((stats) {
        if (mounted) setState(() => _systemStats = stats);
      }),
      _api.getProcesses().then((processes) {
        if (mounted) setState(() => _processes = processes);
      }),
      _api.getHistory().then((history) {
        if (mounted) setState(() => _history = history);
      }),
    ];

    if (!_terminalStreamConnected) {
      refreshTasks.add(
        _api.getTerminal().then((terminal) {
          if (mounted) setState(() => _terminal = terminal);
        }),
      );
    }

    await Future.wait(
      refreshTasks.map(
        (task) => task.catchError((_) {}),
      ),
    );

    if (mounted) {
      setState(() => _backendConnected = statusOk);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.orange,
      ),
    );
  }

  void _showInfo(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _handleDockAction(DockAction action) async {
    if (_loadingActionId != null) return;

    setState(() => _loadingActionId = action.id);
    try {
      await _api.runDockAction(action.id);
    } catch (error) {
      _showError(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loadingActionId = null);
      _refresh();
    }
  }

  Future<void> _handleWorkspaceLaunch(Workspace workspace) async {
    if (_loadingWorkspaceId != null) return;

    setState(() => _loadingWorkspaceId = workspace.id);
    try {
      await _api.launchWorkspace(workspace.id);
    } catch (error) {
      _showError(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loadingWorkspaceId = null);
      _refresh();
    }
  }

  void _launchWorkspaceByIndex(int index) {
    if (index < 0 || index >= _workspaces.length) return;
    _handleWorkspaceLaunch(_workspaces[index]);
  }

  Future<void> _openSettings() async {
    final updated = await showDialog<AppSettings>(
      context: context,
      builder: (context) => SettingsDialog(initialSettings: _settings),
    );

    if (updated == null || !mounted) return;

    final saved = await _settingsService.save(updated);
    setState(() {
      _settings = saved;
      _api = SuperDockApi(baseUrl: saved.backendUrl);
    });

    await _syncBackendConfig();
    await _connectTerminalStream();
    await _loadActions();
    await _loadWorkspaces();
    await _refresh();
    _showInfo('Settings saved.');
  }

  Future<void> _openCreateWorkspace() async {
    final result = await showDialog<Object?>(
      context: context,
      builder: (context) => const WorkspaceDialog(),
    );

    if (result is! WorkspaceFormData || !mounted) return;

    try {
      await _api.createWorkspace(result.toPayload());
      await _loadWorkspaces();
      _showInfo('Workspace created.');
    } catch (error) {
      _showError(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _openEditWorkspace(Workspace workspace) async {
    final apps = workspace.actions
        .where((action) => action['type'] == 'open_app')
        .map((action) => action['name'])
        .join(', ');
    final shell = workspace.actions
        .where((action) => action['type'] == 'shell')
        .map((action) => action['cmd'])
        .join(', ');

    final result = await showDialog<Object?>(
      context: context,
      builder: (context) => WorkspaceDialog(
        isEdit: true,
        workspaceId: workspace.id,
        initialName: workspace.name,
        initialDescription: workspace.description,
        initialShortcut: workspace.shortcut ?? '',
        initialIconKey: workspace.toJson()['icon'] as String? ?? 'grid_view',
        initialColorHex: workspace.accentColorHex,
        initialApps: apps,
        initialShellCommand: shell,
      ),
    );

    if (!mounted || result == null) return;

    if (result == 'delete') {
      try {
        await _api.deleteWorkspace(workspace.id);
        await _loadWorkspaces();
        _showInfo('Workspace deleted.');
      } catch (error) {
        _showError(error.toString().replaceFirst('Exception: ', ''));
      }
      return;
    }

    if (result is! WorkspaceFormData) return;

    try {
      await _api.updateWorkspace(workspace.id, result.toPayload());
      await _loadWorkspaces();
      _showInfo('Workspace updated.');
    } catch (error) {
      _showError(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _showAllProcessesDialog() async {
    List<ProcessInfo> items = _processes;
    try {
      items = await _api.getAllProcesses();
    } catch (_) {}
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 520),
          child: GlassCard(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All Active Processes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: items.isEmpty
                      ? Center(
                          child: Text(
                            'No active processes',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textMuted),
                          ),
                        )
                      : ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.md),
                          itemBuilder: (context, index) {
                            final process = items[index];
                            return Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  size: 14,
                                  color: AppColors.green,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    process.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: AppColors.textPrimary),
                                  ),
                                ),
                                Text(
                                  process.detail,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(color: AppColors.textMuted),
                                ),
                              ],
                            );
                          },
                        ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isAppActive(String? appName) {
    if (appName == null) return false;
    return _processes.any((process) => process.name == appName);
  }

  Map<ShortcutActivator, VoidCallback> get _shortcutBindings {
    return {
      const SingleActivator(LogicalKeyboardKey.digit1, meta: true):
          () => _launchWorkspaceByIndex(0),
      const SingleActivator(LogicalKeyboardKey.digit2, meta: true):
          () => _launchWorkspaceByIndex(1),
      const SingleActivator(LogicalKeyboardKey.digit3, meta: true):
          () => _launchWorkspaceByIndex(2),
      const SingleActivator(LogicalKeyboardKey.digit4, meta: true):
          () => _launchWorkspaceByIndex(3),
    };
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: _shortcutBindings,
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.8, -0.8),
                radius: 1.2,
                colors: [Color(0xFF1A1033), AppColors.background],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  children: [
                    _buildTopNav(context),
                    const SizedBox(height: AppSpacing.xxl),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildMainContent(context)),
                          const SizedBox(width: AppSpacing.xxl),
                          SizedBox(width: 280, child: _buildSidebar(context)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopNav(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppColors.purple, AppColors.blue],
              ).createShader(bounds),
              child: Text(
                'SuperDock',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
              ),
            ),
            Text(
              'Your command center for everything',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
          ],
        ),
        const Spacer(),
        _buildNavPill(context),
        const Spacer(),
        _buildConnectionStatus(context),
        const SizedBox(width: AppSpacing.md),
        _buildSettingsButton(context),
      ],
    );
  }

  Widget _buildNavPill(BuildContext context) {
    const labels = ['Dashboard', 'Workspaces', 'Actions'];
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.xs),
      borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(labels.length, (i) {
          final isActive = _selectedNav == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedNav = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
                border: isActive
                    ? Border.all(color: AppColors.blue.withValues(alpha: 0.6))
                    : null,
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: AppColors.blue.withValues(alpha: 0.2),
                          blurRadius: 12,
                        ),
                      ]
                    : null,
              ),
              child: Text(
                labels[i],
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: isActive
                          ? AppColors.textPrimary
                          : AppColors.navInactive,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildConnectionStatus(BuildContext context) {
    final hostname = _backendConnected
        ? (_status?.hostname ?? 'Connected')
        : 'Disconnected';

    return GlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            hostname,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _backendConnected ? AppColors.green : AppColors.orange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            _backendConnected ? 'Connected' : 'Offline',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: _backendConnected ? AppColors.green : AppColors.orange,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsButton(BuildContext context) {
    return GestureDetector(
      onTap: _openSettings,
      child: GlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        borderRadius: BorderRadius.circular(28),
        child: const Icon(
          Icons.settings_outlined,
          size: 20,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    switch (_selectedNav) {
      case 1:
        return _buildWorkspacesView(context);
      case 2:
        return _buildActionsView(context);
      default:
        return _buildDashboardView(context);
    }
  }

  Widget _buildDashboardView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(icon: Icons.bolt, title: 'Quick Actions'),
              Expanded(child: _buildActionsGrid(crossAxisCount: 5)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(icon: Icons.grid_view, title: 'Workspaces'),
              Expanded(child: _buildWorkspaceRow(includeNewCard: true)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Expanded(
          flex: 3,
          child: Row(
            children: [
              Expanded(flex: 2, child: _buildRecentActions(context)),
              const SizedBox(width: AppSpacing.lg),
              Expanded(flex: 3, child: _buildTerminal(context)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWorkspacesView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(icon: Icons.grid_view, title: 'Workspaces'),
        const SizedBox(height: AppSpacing.lg),
        Expanded(child: _buildWorkspaceRow(includeNewCard: true)),
        const SizedBox(height: AppSpacing.xxl),
        Expanded(child: _buildTerminal(context)),
      ],
    );
  }

  Widget _buildActionsView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(icon: Icons.bolt, title: 'Quick Actions'),
        const SizedBox(height: AppSpacing.lg),
        Expanded(child: _buildActionsGrid(crossAxisCount: 4)),
        const SizedBox(height: AppSpacing.xxl),
        Expanded(child: _buildRecentActions(context)),
      ],
    );
  }

  Widget _buildActionsGrid({required int crossAxisCount}) {
    if (_dockActions.isEmpty) {
      return Center(
        child: Text(
          _backendConnected
              ? 'No actions available'
              : 'Connect to backend to load actions',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
        ),
      );
    }

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.1,
      ),
      itemCount: _dockActions.length,
      itemBuilder: (context, i) {
        final action = _dockActions[i];
        return DockButton(
          title: action.title,
          icon: action.icon,
          status: action.status,
          accentColor: action.accentColor,
          isLoading: _loadingActionId == action.id,
          isActive: _isAppActive(action.appName),
          onTap: () => _handleDockAction(action),
        );
      },
    );
  }

  Widget _buildWorkspaceRow({required bool includeNewCard}) {
    if (_workspaces.isEmpty) {
      return Center(
        child: Text(
          _backendConnected
              ? 'No workspaces available'
              : 'Connect to backend to load workspaces',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
        ),
      );
    }

    final cards = [
      for (final ws in _workspaces)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: GestureDetector(
              onLongPress: () => _openEditWorkspace(ws),
              child: WorkspaceCard(
                title: ws.name,
                description: ws.description,
                icon: ws.icon,
                accentColor: ws.accentColor,
                isLoading: _loadingWorkspaceId == ws.id,
                onLaunch: () => _handleWorkspaceLaunch(ws),
              ),
            ),
          ),
        ),
      if (includeNewCard)
        Expanded(
          child: NewWorkspaceCard(
            onTap: _openCreateWorkspace,
          ),
        ),
    ];

    return Row(children: cards);
  }

  Widget _buildRecentActions(BuildContext context) {
    final items = _history;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Actions',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      'No actions yet',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                  )
                : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, i) {
                      final entry = items[i];
                      return Row(
                        children: [
                          Icon(
                            entry.success
                                ? Icons.check_circle
                                : Icons.error_outline,
                            size: 16,
                            color: entry.success
                                ? AppColors.green
                                : AppColors.orange,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              entry.label,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ),
                          Text(
                            entry.relative,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTerminal(BuildContext context) {
    final lines = _backendConnected
        ? (_terminal?.lines ?? ['No terminal output yet'])
        : ['Backend offline — start superdock-core to see terminal output'];
    final isLive = _terminal?.live ?? false;

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Text(
                  'Terminal Output',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: (isLive ? AppColors.green : AppColors.textMuted)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isLive ? AppColors.green : AppColors.textMuted,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        isLive ? 'Live' : 'Idle',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: isLive
                                  ? AppColors.green
                                  : AppColors.textMuted,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.terminalBackground,
                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
              ),
              child: ListView.builder(
                itemCount: lines.length,
                itemBuilder: (context, i) => Text(
                  lines[i],
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        color: AppColors.terminalText.withValues(alpha: 0.85),
                        height: 1.6,
                      ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final stats = _systemStats;

    return Column(
      children: [
        StatusCard(
          cpu: stats?.cpu ?? 0,
          memory: stats?.memory ?? 0,
          disk: stats?.disk ?? 0,
          uptime: stats?.uptime ?? '—',
          cpuHistory: stats?.sparklines.cpu ?? [],
          memoryHistory: stats?.sparklines.memory ?? [],
          diskHistory: stats?.sparklines.disk ?? [],
        ),
        const SizedBox(height: AppSpacing.lg),
        Expanded(child: _buildProcesses(context)),
        const SizedBox(height: AppSpacing.lg),
        _buildShortcuts(context),
      ],
    );
  }

  Widget _buildProcesses(BuildContext context) {
    final items = _processes;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Active Processes',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      'No active processes',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                  )
                : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, i) {
                      final process = items[i];
                      return Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 14,
                            color: AppColors.green,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              process.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.textPrimary),
                            ),
                          ),
                          Text(
                            process.detail,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          const SizedBox(height: AppSpacing.md),
          GestureDetector(
            onTap: _showAllProcessesDialog,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'View all processes',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcuts(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Shortcuts',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_workspaces.isEmpty)
            Text(
              'No workspace shortcuts loaded',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            )
          else
            for (final ws in _workspaces) ...[
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Text(
                      ws.shortcut ?? '',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      ws.name,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
        ],
      ),
    );
  }
}
