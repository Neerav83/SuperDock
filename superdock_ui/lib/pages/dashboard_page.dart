import 'dart:async';

import 'package:flutter/material.dart';

import '../core/models/action_history.dart';
import '../core/models/connection_status.dart';
import '../core/models/dock_action.dart';
import '../core/models/process_info.dart';
import '../core/models/system_stats.dart';
import '../core/models/terminal_output.dart';
import '../core/models/workspace.dart';
import '../core/services/api.dart';
import '../core/theme/colors.dart';
import '../core/theme/spacing.dart';
import '../widgets/dock_button.dart';
import '../widgets/glass_card.dart';
import '../widgets/section_title.dart';
import '../widgets/status_card.dart';
import '../widgets/workspace_card.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _api = SuperDockApi();
  int _selectedNav = 0;
  Timer? _pollTimer;

  ConnectionStatus? _status;
  SystemStats? _systemStats;
  List<ProcessInfo> _processes = [];
  List<ActionHistoryEntry> _history = [];
  TerminalOutput? _terminal;
  bool _backendConnected = false;
  int? _loadingActionIndex;
  String? _loadingWorkspaceId;

  static const _dockActions = [
    DockAction(
      title: 'VS Code',
      icon: Icons.code,
      status: 'Open',
      accentColor: AppColors.blue,
      appName: 'Visual Studio Code',
    ),
    DockAction(
      title: 'Cursor',
      icon: Icons.auto_awesome,
      status: 'Open',
      accentColor: AppColors.purple,
      appName: 'Cursor',
    ),
    DockAction(
      title: 'Docker',
      icon: Icons.dns,
      status: 'Start',
      accentColor: AppColors.cyan,
      appName: 'Docker',
    ),
    DockAction(
      title: 'Figma',
      icon: Icons.design_services,
      status: 'Open',
      accentColor: AppColors.orange,
      appName: 'Figma',
    ),
    DockAction(
      title: 'Terminal',
      icon: Icons.terminal,
      status: 'Open',
      accentColor: AppColors.green,
      appName: 'Terminal',
    ),
    DockAction(
      title: 'Flutter Run',
      icon: Icons.play_arrow,
      status: 'Run Project',
      accentColor: AppColors.purple,
      shellCommand: 'cd project && flutter run',
    ),
    DockAction(
      title: 'Git Pull',
      icon: Icons.download,
      status: 'Update',
      accentColor: AppColors.orange,
      shellCommand: 'git pull',
    ),
    DockAction(
      title: 'Simulator',
      icon: Icons.phone_iphone,
      status: 'Open',
      accentColor: AppColors.blue,
      appName: 'Simulator',
    ),
    DockAction(
      title: 'Xcode',
      icon: Icons.apple,
      status: 'Open',
      accentColor: AppColors.blue,
      appName: 'Xcode',
    ),
    DockAction(
      title: 'Safari',
      icon: Icons.language,
      status: 'Open',
      accentColor: AppColors.cyan,
      appName: 'Safari',
    ),
  ];

  static const _workspaces = [
    Workspace(
      id: 'flutter-dev',
      title: 'Flutter Dev',
      description: 'VS Code, Simulator, Flutter run',
      icon: Icons.phone_iphone,
      accentColor: AppColors.purple,
      shortcut: '⌘1',
    ),
    Workspace(
      id: 'ai-mode',
      title: 'AI Mode',
      description: 'Cursor, Claude, Terminal',
      icon: Icons.auto_awesome,
      accentColor: AppColors.purple,
      shortcut: '⌘2',
    ),
    Workspace(
      id: 'server-mode',
      title: 'Server Mode',
      description: 'Docker, Terminal, API logs',
      icon: Icons.storage,
      accentColor: AppColors.blue,
      shortcut: '⌘3',
    ),
    Workspace(
      id: 'design-mode',
      title: 'Design Mode',
      description: 'Figma, Safari, Preview',
      icon: Icons.brush,
      accentColor: AppColors.orange,
      shortcut: '⌘4',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _refresh();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _refresh());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final results = await Future.wait([
        _api.getStatus(),
        _api.getSystemStats(),
        _api.getProcesses(),
        _api.getHistory(),
        _api.getTerminal(),
      ]);

      if (!mounted) return;
      setState(() {
        _backendConnected = true;
        _status = results[0] as ConnectionStatus;
        _systemStats = results[1] as SystemStats;
        _processes = results[2] as List<ProcessInfo>;
        _history = results[3] as List<ActionHistoryEntry>;
        _terminal = results[4] as TerminalOutput;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _backendConnected = false);
    }
  }

  Future<void> _handleDockAction(DockAction action, int index) async {
    if (_loadingActionIndex != null) return;

    setState(() => _loadingActionIndex = index);
    try {
      if (action.appName != null) {
        await _api.openApp(action.appName!);
      } else if (action.shellCommand != null) {
        await _api.runShell(action.shellCommand!);
      }
    } catch (_) {
      // Refresh will show failure in history/terminal.
    } finally {
      if (mounted) setState(() => _loadingActionIndex = null);
      _refresh();
    }
  }

  Future<void> _handleWorkspaceLaunch(Workspace workspace) async {
    if (_loadingWorkspaceId != null) return;

    setState(() => _loadingWorkspaceId = workspace.id);
    try {
      await _api.launchWorkspace(workspace.id);
    } catch (_) {
      // Refresh will show failure in history/terminal.
    } finally {
      if (mounted) setState(() => _loadingWorkspaceId = null);
      _refresh();
    }
  }

  bool _isAppActive(String? appName) {
    if (appName == null) return false;
    return _processes.any((process) => process.name == appName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
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
    final hostname = _status?.hostname ?? 'Disconnected';
    final connected = _backendConnected;

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
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: connected ? AppColors.green : AppColors.orange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            connected ? 'Connected' : 'Offline',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: connected ? AppColors.green : AppColors.orange,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsButton(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: BorderRadius.circular(28),
      child: Icon(
        Icons.settings_outlined,
        size: 20,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(icon: Icons.bolt, title: 'Quick Actions'),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
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
                      isLoading: _loadingActionIndex == i,
                      isActive: _isAppActive(action.appName),
                      onTap: () => _handleDockAction(action, i),
                    );
                  },
                ),
              ),
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
              Expanded(
                child: Row(
                  children: [
                    for (final ws in _workspaces)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.md),
                          child: WorkspaceCard(
                            title: ws.title,
                            description: ws.description,
                            icon: ws.icon,
                            accentColor: ws.accentColor,
                            isLoading: _loadingWorkspaceId == ws.id,
                            onLaunch: () => _handleWorkspaceLaunch(ws),
                          ),
                        ),
                      ),
                    const Expanded(child: NewWorkspaceCard()),
                  ],
                ),
              ),
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

  Widget _buildRecentActions(BuildContext context) {
    final items = _history;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Actions',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
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
    final lines = _terminal?.lines ?? ['Connecting to backend...'];
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
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
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
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
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
                          Icon(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'View all processes',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: AppColors.textMuted),
              ),
              Icon(Icons.chevron_right, size: 16, color: AppColors.textMuted),
            ],
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
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.lg),
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
                Text(
                  ws.title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
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
