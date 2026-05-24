import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../navigation/nav_config.dart';
import '../theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';

class MobileShell extends StatelessWidget {
  const MobileShell({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.floatingActionButton,
    this.showBack = false,
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final navItems = filteredNavItems(user.role);
    final unread = context.watch<NotificationProvider>().unreadCount;

    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        leading: showBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              )
            : null,
        title: Text(title),
        actions: [
          if (actions != null) ...actions!,
          IconButton(
            icon: Badge(
              isLabelVisible: unread > 0,
              backgroundColor: AppColors.primary,
              label: Text('$unread', style: const TextStyle(fontSize: 10)),
              child: const Icon(Icons.notifications_outlined),
            ),
            onPressed: () => context.push('/notifications'),
          ),
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(ctx).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: _AppDrawer(user: user, navItems: navItems),
      body: child,
      floatingActionButton: floatingActionButton,
    );
  }
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer({required this.user, required this.navItems});

  final dynamic user;
  final List<NavItem> navItems;

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final picture = user.profileImageUrl as String?;
    final imageUrl = picture != null && picture.isNotEmpty
        ? ApiClient.imageUrl(picture)
        : null;

    return Drawer(
      child: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.local_fire_department,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tekeraheza',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            'Your Energy Store',
                            style: GoogleFonts.outfit(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white,
                      backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                          ? NetworkImage(imageUrl)
                          : null,
                      child: imageUrl == null || imageUrl.isEmpty
                          ? Text(
                              '${user.firstName.toString().substring(0, 1)}${user.lastName.toString().substring(0, 1)}',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${user.firstName} ${user.lastName}',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            user.role.value.replaceAll('_', ' '),
                            style: GoogleFonts.outfit(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    for (final item in navItems) ...[
                      if (item.subItems.isEmpty)
                        _DrawerTile(
                          icon: item.icon,
                          label: item.label,
                          onTap: () {
                            Navigator.pop(context);
                            context.go(item.route);
                          },
                        )
                      else
                        Theme(
                          data: Theme.of(context).copyWith(
                            dividerColor: Colors.transparent,
                          ),
                          child: ExpansionTile(
                            iconColor: Colors.white,
                            collapsedIconColor: Colors.white70,
                            title: Text(
                              item.label,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            leading: Icon(item.icon, color: Colors.white),
                            children: item.subItems
                                .map(
                                  (sub) => _DrawerTile(
                                    icon: sub.icon,
                                    label: sub.label,
                                    dense: true,
                                    onTap: () {
                                      Navigator.pop(context);
                                      context.go(sub.route);
                                    },
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.white),
                title: Text(
                  'Logout',
                  style: GoogleFonts.outfit(color: Colors.white),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await auth.logout();
                  if (context.mounted) context.go('/login');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.dense = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: dense,
      leading: Icon(icon, color: Colors.white, size: dense ? 20 : 22),
      title: Text(
        label,
        style: GoogleFonts.outfit(
          color: dense ? Colors.white70 : Colors.white,
          fontSize: dense ? 13 : 15,
        ),
      ),
      onTap: onTap,
    );
  }
}
