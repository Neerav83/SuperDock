import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:superdock_ui/core/theme/tokens.dart';
import 'package:superdock_ui/pages/dashboard/dashboard_providers.dart';
import 'package:superdock_ui/pages/dashboard/dashboard_widgets.dart';
import 'package:superdock_ui/widgets/widgets.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  final _terminalScrollController = ScrollController();

  @override
  void dispose() {
    _terminalScrollController.dispose();
    super.dispose();
  }

  void _scrollTerminalToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_terminalScrollController.hasClients) return;
      _terminalScrollController.animateTo(
        _terminalScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
      );
    });
  }

  DashboardController get _controller => ref.read(dashboardControllerProvider);

  void _launchWorkspaceIfEnabled(int index) {
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return;
    _controller.launchWorkspaceByIndex(context, index);
  }

  Map<ShortcutActivator, VoidCallback> _shortcutBindings() {
    return {
      const SingleActivator(LogicalKeyboardKey.digit1, meta: true):
          () => _launchWorkspaceIfEnabled(0),
      const SingleActivator(LogicalKeyboardKey.digit2, meta: true):
          () => _launchWorkspaceIfEnabled(1),
      const SingleActivator(LogicalKeyboardKey.digit3, meta: true):
          () => _launchWorkspaceIfEnabled(2),
      const SingleActivator(LogicalKeyboardKey.digit4, meta: true):
          () => _launchWorkspaceIfEnabled(3),
    };
  }

  Widget _buildQuickActionsHeader(DashboardState state) {
    final workspace = state.activeWorkspace;

    if (workspace != null &&
        workspace.imageUrl != null &&
        workspace.imageUrl!.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Row(
          children: [
            WorkspaceAvatar(
              icon: workspace.icon,
              accentColor: workspace.accentColor,
              imageUrl: workspace.imageUrl,
              size: 32,
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              '${workspace.name} Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
            ),
          ],
        ),
      );
    }

    return SectionTitle(icon: Icons.bolt, title: state.quickActionsTitle);
  }

  Widget _buildAddWorkspaceActionButton({
    required bool compact,
  }) {
    final circleSize = compact ? 32.0 : 48.0;
    final iconSize = compact ? 20.0 : 28.0;

    return GestureDetector(
      onTap: () => _controller.openAddWorkspaceCommand(context),
      child: GlassCard(
        borderColor: AppColors.textMuted.withValues(alpha: 0.35),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: circleSize,
              height: circleSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.textMuted.withValues(alpha: 0.45),
                ),
              ),
              child: Icon(
                Icons.add,
                size: iconSize,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Add',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Text(
              'Command',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsGrid(
    DashboardState state, {
    required double width,
    bool shrinkWrap = false,
    bool compact = false,
  }) {
    if (state.showWorkspaceQuickActions) {
      final actions = state.workspaceQuickActions;
      final columns = Responsive.actionColumns(width, actions.length + 1);
      final tileHeight = Responsive.actionTileHeight(width, compact: compact);

      return GridView.builder(
        shrinkWrap: shrinkWrap,
        physics: shrinkWrap
            ? const NeverScrollableScrollPhysics()
            : const AlwaysScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          mainAxisExtent: tileHeight,
        ),
        itemCount: actions.length + 1,
        itemBuilder: (context, i) {
          if (i == actions.length) {
            return _buildAddWorkspaceActionButton(compact: compact);
          }

          final action = actions[i];
          final loadingKey = '${action.workspace.id}:${action.actionIndex}';
          return DockButton(
            title: action.title,
            icon: action.icon,
            status: action.status,
            accentColor: action.accentColor,
            isLoading: state.loadingWorkspaceActionKey == loadingKey,
            isActive: _controller.isAppActive(action.appName),
            compact: compact,
            onTap: () => _controller.handleWorkspaceQuickAction(context, action),
          );
        },
      );
    }

    if (state.dockActions.isEmpty) {
      return Center(
        child: Text(
          state.backendConnected
              ? 'No actions available'
              : 'Connect to backend to load actions',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
        ),
      );
    }

    final columns = Responsive.actionColumns(width, state.dockActions.length);
    final tileHeight = Responsive.actionTileHeight(width, compact: compact);

    return GridView.builder(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        mainAxisExtent: tileHeight,
      ),
      itemCount: state.dockActions.length,
      itemBuilder: (context, i) {
        final action = state.dockActions[i];
        return GestureDetector(
          onLongPress: () => _controller.openEditAction(context, action),
          child: DockButton(
            title: action.title,
            icon: action.icon,
            status: action.status,
            accentColor: action.accentColor,
            isLoading: state.loadingActionId == action.id,
            isActive: _controller.isAppActive(action.appName),
            compact: compact,
            onTap: () => _controller.handleDockAction(context, action),
          ),
        );
      },
    );
  }

  Widget _buildWorkspaceRow(
    DashboardState state, {
    required bool includeNewCard,
    bool horizontal = false,
  }) {
    if (state.workspaces.isEmpty) {
      return Center(
        child: Text(
          state.backendConnected
              ? 'No workspaces available'
              : 'Connect to backend to load workspaces',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
        ),
      );
    }

    if (horizontal) {
      final cards = <Widget>[
        for (final ws in state.workspaces)
          SizedBox(
            width: 200,
            child: GestureDetector(
              onLongPress: () => _controller.openEditWorkspace(context, ws),
              child: WorkspaceCard(
                title: ws.name,
                description: ws.description,
                icon: ws.icon,
                accentColor: ws.accentColor,
                imageUrl: ws.imageUrl,
                isActive: state.activeWorkspaceId == ws.id,
                isLoading: state.loadingWorkspaceId == ws.id,
                onActivate: () => _controller.activateWorkspace(context, ws),
                onLaunch: () => _controller.handleWorkspaceLaunch(context, ws),
              ),
            ),
          ),
        if (includeNewCard)
          SizedBox(
            width: 200,
            child: NewWorkspaceCard(
              onTap: () => _controller.openCreateWorkspace(context),
            ),
          ),
      ];

      return SizedBox(
        height: 168,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: cards.length,
          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
          itemBuilder: (context, index) => cards[index],
        ),
      );
    }

    final cards = [
      for (final ws in state.workspaces)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: GestureDetector(
              onLongPress: () => _controller.openEditWorkspace(context, ws),
              child: WorkspaceCard(
                title: ws.name,
                description: ws.description,
                icon: ws.icon,
                accentColor: ws.accentColor,
                imageUrl: ws.imageUrl,
                isActive: state.activeWorkspaceId == ws.id,
                isLoading: state.loadingWorkspaceId == ws.id,
                onActivate: () => _controller.activateWorkspace(context, ws),
                onLaunch: () => _controller.handleWorkspaceLaunch(context, ws),
              ),
            ),
          ),
        ),
      if (includeNewCard)
        Expanded(
          child: NewWorkspaceCard(
            onTap: () => _controller.openCreateWorkspace(context),
          ),
        ),
    ];

    return Row(children: cards);
  }

  Widget _buildTopNav(DashboardState state) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = Responsive.isCompactWidth(width) ||
        Responsive.useStackedTopNav(width);

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [AppColors.purple, AppColors.blue],
                      ).createShader(bounds),
                      child: Text(
                        'SuperDock',
                        style:
                            Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildConnectionStatus(state),
              const SizedBox(width: AppSpacing.sm),
              _buildSettingsButton(),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildNavPill(state),
        ],
      );
    }

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
        _buildNavPill(state),
        const Spacer(),
        _buildConnectionStatus(state),
        const SizedBox(width: AppSpacing.md),
        _buildSettingsButton(),
      ],
    );
  }

  Widget _buildNavPill(DashboardState state) {
    const labels = ['Dashboard', 'Workspaces', 'Actions'];
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.xs),
      borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(labels.length, (i) {
          final isActive = state.selectedNav == i;
          return GestureDetector(
            onTap: () => _controller.setSelectedNav(i),
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

  Widget _buildConnectionStatus(DashboardState state) {
    final hostname = state.backendConnected
        ? (state.status?.hostname ?? 'Connected')
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
              color: state.backendConnected ? AppColors.green : AppColors.orange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            state.backendConnected ? 'Connected' : 'Offline',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color:
                      state.backendConnected ? AppColors.green : AppColors.orange,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsButton() {
    return GestureDetector(
      onTap: () => _controller.openSettings(context),
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

  Widget _buildMainContent(DashboardState state) {
    switch (state.selectedNav) {
      case 1:
        return _buildWorkspacesView(state);
      case 2:
        return _buildActionsView(state);
      default:
        return _buildDashboardView(state);
    }
  }

  Widget _buildTerminalPanel(DashboardState state) {
    return DashboardTerminalPanel(
      lines: state.terminal?.lines ?? ['No terminal output yet'],
      isLive: state.terminal?.live ?? false,
      backendConnected: state.backendConnected,
      scrollController: _terminalScrollController,
    );
  }

  Widget _buildDashboardView(DashboardState state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.sizeOf(context).width;
        final compact = Responsive.isCompactWidth(constraints.maxWidth);
        final useScroll = Responsive.useScrollLayout(
          constraints.maxWidth,
          constraints.maxHeight,
        );
        final showSidebar = Responsive.showSidebar(screenWidth);

        if (useScroll) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildQuickActionsHeader(state),
                const SizedBox(height: AppSpacing.md),
                _buildActionsGrid(
                  state,
                  width: constraints.maxWidth,
                  shrinkWrap: true,
                  compact: compact,
                ),
                const SizedBox(height: AppSpacing.xxl),
                const SectionTitle(icon: Icons.grid_view, title: 'Workspaces'),
                const SizedBox(height: AppSpacing.md),
                _buildWorkspaceRow(
                  state,
                  includeNewCard: true,
                  horizontal: true,
                ),
                if (!showSidebar) ...[
                  const SizedBox(height: AppSpacing.xxl),
                  SizedBox(
                    height: 180,
                    child: DashboardRecentActionsPanel(history: state.history),
                  ),
                ],
                const SizedBox(height: AppSpacing.xxl),
                SizedBox(height: 240, child: _buildTerminalPanel(state)),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuickActionsHeader(state),
                  Expanded(
                    child: _buildActionsGrid(
                      state,
                      width: constraints.maxWidth,
                      compact: compact,
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
                    child: _buildWorkspaceRow(state, includeNewCard: true),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  if (showSidebar) ...[
                    Expanded(
                      flex: 2,
                      child: DashboardRecentActionsPanel(history: state.history),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                  ],
                  Expanded(flex: 3, child: _buildTerminalPanel(state)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWorkspacesView(DashboardState state) {
    final compact = Responsive.isCompactWidth(MediaQuery.sizeOf(context).width);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(icon: Icons.grid_view, title: 'Workspaces'),
        const SizedBox(height: AppSpacing.lg),
        compact
            ? _buildWorkspaceRow(state, includeNewCard: true, horizontal: true)
            : Expanded(child: _buildWorkspaceRow(state, includeNewCard: true)),
        const SizedBox(height: AppSpacing.xxl),
        Expanded(child: _buildTerminalPanel(state)),
      ],
    );
  }

  Widget _buildActionsView(DashboardState state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = Responsive.isCompactWidth(constraints.maxWidth);
        final useScroll = Responsive.useScrollLayout(
          constraints.maxWidth,
          constraints.maxHeight,
        );

        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _buildQuickActionsHeader(state)),
                if (!state.showWorkspaceQuickActions)
                  IconButton(
                    onPressed: () => _controller.openCreateAction(context),
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    tooltip: 'Create new action',
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            useScroll
                ? _buildActionsGrid(
                    state,
                    width: constraints.maxWidth,
                    shrinkWrap: true,
                    compact: compact,
                  )
                : Expanded(
                    child: _buildActionsGrid(
                      state,
                      width: constraints.maxWidth,
                      compact: compact,
                    ),
                  ),
            if (!useScroll) ...[
              const SizedBox(height: AppSpacing.xxl),
              Expanded(
                child: DashboardRecentActionsPanel(history: state.history),
              ),
            ],
          ],
        );

        if (useScroll) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                content,
                const SizedBox(height: AppSpacing.xxl),
                SizedBox(
                  height: 200,
                  child: DashboardRecentActionsPanel(history: state.history),
                ),
              ],
            ),
          );
        }

        return content;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardViewProvider);

    ref.listen(
      dashboardViewProvider.select((value) => value.terminal),
      (previous, next) {
        if (next != null) _scrollTerminalToBottom();
      },
    );

    final size = MediaQuery.sizeOf(context);
    final showSidebar = Responsive.showSidebar(size.width);
    final isCompact = Responsive.isCompactWidth(size.width);

    return CallbackShortcuts(
      bindings: _shortcutBindings(),
      child: Focus(
        autofocus: false,
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
                padding:
                    EdgeInsets.all(isCompact ? AppSpacing.lg : AppSpacing.xxl),
                child: Column(
                  children: [
                    _buildTopNav(state),
                    const SizedBox(height: AppSpacing.xxl),
                    Expanded(
                      child: showSidebar
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildMainContent(state)),
                                const SizedBox(width: AppSpacing.xxl),
                                SizedBox(
                                  width: 280,
                                  child: DashboardSidebar(
                                    systemStats: state.systemStats,
                                    processes: state.processes,
                                    workspaces: state.workspaces,
                                    onViewAllProcesses: () =>
                                        _controller.showAllProcesses(context),
                                  ),
                                ),
                              ],
                            )
                          : _buildMainContent(state),
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
}
