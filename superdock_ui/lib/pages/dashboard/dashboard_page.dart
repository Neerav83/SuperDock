import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:superdock_ui/core/theme/tokens.dart';
import 'package:superdock_ui/pages/dashboard/dashboard_providers.dart';
import 'package:superdock_ui/pages/dashboard/dashboard_widgets.dart';

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

  DashboardInteractions get _interactions => DashboardInteractions(
        setSelectedNav: _controller.setSelectedNav,
        openSettings: () => _controller.openSettings(context),
        showAllProcesses: () => _controller.showAllProcesses(context),
        isAppActive: _controller.isAppActive,
        handleDockAction: (action) =>
            _controller.handleDockAction(context, action),
        openEditAction: (action) => _controller.openEditAction(context, action),
        openCreateAction: () => _controller.openCreateAction(context),
        handleWorkspaceQuickAction: (action) =>
            _controller.handleWorkspaceQuickAction(context, action),
        openEditWorkspaceAction: (action) =>
            _controller.openEditWorkspaceAction(context, action),
        openAddWorkspaceCommand: () =>
            _controller.openAddWorkspaceCommand(context),
        openEditWorkspace: (workspace) =>
            _controller.openEditWorkspace(context, workspace),
        activateWorkspace: (workspace) =>
            _controller.activateWorkspace(context, workspace),
        handleWorkspaceLaunch: (workspace) =>
            _controller.handleWorkspaceLaunch(context, workspace),
        openCreateWorkspace: () => _controller.openCreateWorkspace(context),
      );

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

  Widget _buildMainContent(DashboardState state) {
    switch (state.selectedNav) {
      case 1:
        return DashboardWorkspacesView(
          state: state,
          interactions: _interactions,
          terminalScrollController: _terminalScrollController,
        );
      case 2:
        return DashboardActionsView(
          state: state,
          interactions: _interactions,
        );
      default:
        return DashboardHomeView(
          state: state,
          interactions: _interactions,
          terminalScrollController: _terminalScrollController,
        );
    }
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
    final interactions = _interactions;

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
                    DashboardTopNav(state: state, interactions: interactions),
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
                                    onViewAllProcesses:
                                        interactions.showAllProcesses,
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
