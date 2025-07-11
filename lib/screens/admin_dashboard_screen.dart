import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/firebase_service.dart';
import '../main.dart';
import 'user_management_screen.dart';
import 'announcements_management_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic> _dashboardStats = {};
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    try {
      _tabController = TabController(length: 5, vsync: this);
      // Add a small delay to ensure everything is properly initialized
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadDashboardStats();
        }
      });
    } catch (e) {
      print('Error initializing admin dashboard: $e');
    }
  }

  @override
  void dispose() {
    try {
      _tabController.dispose();
    } catch (e) {
      print('Error disposing tab controller: $e');
    }
    super.dispose();
  }

  Future<void> _loadDashboardStats() async {
    if (!mounted) return;
    
    setState(() => _isLoadingStats = true);
    try {
      final stats = await FirebaseService.getAdminDashboardStats();
      if (mounted) {
        setState(() {
          _dashboardStats = stats.isNotEmpty ? stats : {
            'totalUsers': 0,
            'pendingUsers': 0,
            'totalAnnouncements': 0,
            'totalEvents': 0,
          };
          _isLoadingStats = false;
        });
      }
    } catch (error) {
      print('Error loading dashboard stats: $error');
      if (mounted) {
        setState(() {
          _dashboardStats = {
            'totalUsers': 0,
            'pendingUsers': 0,
            'totalAnnouncements': 0,
            'totalEvents': 0,
          };
          _isLoadingStats = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load dashboard stats. Using default values.'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadDashboardStats,
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleSignOut() async {
    await FirebaseService.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardPage()),
      );
    }
  }

  void _navigateToUserManagement() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const UserManagementScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  void _navigateToAnnouncementsManagement() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AnnouncementsManagementScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFF8F9FA),
              const Color(0xFFE3F2FD),
              const Color(0xFFF8F9FA),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              _buildStatsCards(),
              _buildTabBar(),
              Expanded(child: _buildTabBarView()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1976D2).withOpacity(0.9),
            const Color(0xFF42A5F5).withOpacity(0.8),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1976D2).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Dashboard',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Manage parish community',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _handleSignOut,
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Sign Out',
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    if (_isLoadingStats) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading dashboard...'),
            ],
          ),
        ),
      );
    }

    // Debug information
    print('Dashboard stats: $_dashboardStats');

    return Padding(
      padding: const EdgeInsets.all(20),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.6, // Slightly more space to prevent overflow
        children: [
          _buildStatCard(
            'Total Users',
            '${_dashboardStats['totalUsers'] ?? 0}',
            Icons.people,
            const Color(0xFF2196F3),
            onTap: () => _navigateToUserManagement(),
          ),
          _buildStatCard(
            'Pending Approval',
            '${_dashboardStats['pendingUsers'] ?? 0}',
            Icons.pending,
            const Color(0xFFFF9800),
          ),
          _buildStatCard(
            'Announcements',
            '${_dashboardStats['totalAnnouncements'] ?? 0}',
            Icons.campaign,
            const Color(0xFF4CAF50),
            onTap: () => _navigateToAnnouncementsManagement(),
          ),
          _buildStatCard(
            'Events',
            '${_dashboardStats['totalEvents'] ?? 0}',
            Icons.event,
            const Color(0xFF9C27B0),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    Widget cardContent = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.9),
            Colors.white.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            FittedBox(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF1976D2),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Pending', icon: Icon(Icons.pending_actions, size: 14)),
          Tab(text: 'Users', icon: Icon(Icons.people, size: 14)),
          Tab(text: 'Dues', icon: Icon(Icons.payment, size: 14)),
          Tab(text: 'Messages', icon: Icon(Icons.message, size: 14)),
          Tab(text: 'Actions', icon: Icon(Icons.settings, size: 14)),
        ],
      ),
    );
  }

  Widget _buildTabBarView() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingApprovalTab(),
          _buildUsersTab(),
          _buildDuesTab(),
          _buildMessagesTab(),
          _buildActionsTab(),
        ],
      ),
    );
  }

  Widget _buildPendingApprovalTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirebaseService.getPendingAccessRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Error Loading Requests',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text('${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final pendingRequests = snapshot.data ?? [];

        if (pendingRequests.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 64, color: Colors.green),
                SizedBox(height: 16),
                Text(
                  'No Pending Requests',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text('All users have been processed'),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: pendingRequests.length,
          itemBuilder: (context, index) {
            try {
              if (index < 0 || index >= pendingRequests.length || pendingRequests.isEmpty) {
                return const SizedBox.shrink();
              }
              final request = pendingRequests[index];
              if (request == null) {
                return const SizedBox.shrink();
              }
              return _buildPendingRequestCard(request);
            } catch (e) {
              print('Error building pending request at index $index: $e');
              return const SizedBox.shrink();
            }
          },
        );
      },
    );
  }

  Widget _buildPendingRequestCard(Map<String, dynamic> request) {
    if (request.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.person_add, color: Colors.orange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request['displayName']?.toString() ?? 'Unknown User',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      request['email']?.toString() ?? '',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Flexible(
                flex: 1,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: request['id'] != null ? () => _approveUser(request['id']) : null,
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                flex: 1,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: request['id'] != null ? () => _rejectUser(request['id']) : null,
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Reject'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirebaseService.getAllUsersAndMembers(),
      builder: (context, snapshot) {
        print('Admin Users Tab - Connection state: ${snapshot.connectionState}');
        print('Admin Users Tab - Has error: ${snapshot.hasError}');
        print('Admin Users Tab - Has data: ${snapshot.hasData}');
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Error Loading Users',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text('${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final users = snapshot.data ?? [];
        print('Admin Users Tab - Received ${users.length} users');

        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'No Users Found',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Text('No registered users yet'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Refresh'),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          itemCount: users.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            try {
              if (index < 0 || index >= users.length || users.isEmpty) {
                return const SizedBox.shrink();
              }
              final user = users[index];
              if (user == null || user.isEmpty) {
                return const SizedBox.shrink();
              }
              return _buildUserCard(user);
            } catch (e) {
              print('Error building user at index $index: $e');
              return const SizedBox.shrink();
            }
          },
        );
      },
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    if (user.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final isApproved = user['isApproved'] ?? false;
    final isActive = user['isActive'] ?? true;
    final userName = user['name']?.toString() ?? user['email']?.toString() ?? 'Unknown';
    final userEmail = user['email']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: isApproved ? Colors.green : Colors.orange,
            child: Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  userEmail,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isApproved ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isApproved ? 'Approved' : 'Pending',
              style: TextStyle(
                color: isApproved ? Colors.green : Colors.orange,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDuesTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirebaseService.getAllUsersAndMembers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Error Loading Members',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text('${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final members = snapshot.data ?? [];

        if (members.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No Members Found',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text('No registered members yet'),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Search and filter bar
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const TextField(
                        decoration: InputDecoration(
                          hintText: 'Search members...',
                          prefixIcon: Icon(Icons.search),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateDueDialog(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Create Due'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
            // Members list
            Expanded(
              child: ListView.builder(
                itemCount: members.length,
                itemBuilder: (context, index) {
                  try {
                    if (index < 0 || index >= members.length || members.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    final member = members[index];
                    if (member == null || member.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return _buildMemberDueCard(member);
                  } catch (e) {
                    print('Error building member card at index $index: $e');
                    return const SizedBox.shrink();
                  }
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMemberDueCard(Map<String, dynamic> member) {
    if (member.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final memberName = member['name']?.toString() ?? member['email']?.toString() ?? 'Unknown';
    final memberEmail = member['email']?.toString() ?? '';
    final memberId = member['id']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF1976D2),
                child: Text(
                  memberName.isNotEmpty ? memberName[0].toUpperCase() : 'U',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      memberName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      memberEmail,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showCreateDueDialogForMember(member),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Due'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Show existing dues for this member
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _getMemberDues(memberId),
            builder: (context, duesSnapshot) {
              if (duesSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }

              final dues = duesSnapshot.data ?? [];
              if (dues.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'No dues assigned',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              return Column(
                children: dues.take(2).map((due) => _buildDueItem(due)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDueItem(Map<String, dynamic> due) {
    final description = due['description']?.toString() ?? 'No description';
    final amount = (due['amount'] as num?)?.toDouble() ?? 0.0;
    final status = due['status']?.toString() ?? 'unpaid';
    final isPaid = status.toLowerCase() == 'paid';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPaid ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPaid ? Colors.green[200]! : Colors.orange[200]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPaid ? Icons.check_circle : Icons.schedule,
            color: isPaid ? Colors.green : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '\$${amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: isPaid ? Colors.green[700] : Colors.orange[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isPaid ? Colors.green : Colors.orange,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isPaid ? 'Paid' : 'Pending',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getMemberDues(String memberId) async {
    try {
      // This is a simplified version - in a real app you'd query the dues collection
      // For now, returning empty list
      return [];
    } catch (e) {
      print('Error getting member dues: $e');
      return [];
    }
  }

  void _showCreateDueDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Due'),
        content: const Text('Select a member first to create a due for them.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showCreateDueDialogForMember(Map<String, dynamic> member) {
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    final dueDateController = TextEditingController();

    // Set default due date to next month
    final nextMonth = DateTime.now().add(const Duration(days: 30));
    dueDateController.text = '${nextMonth.day.toString().padLeft(2, '0')}/${nextMonth.month.toString().padLeft(2, '0')}/${nextMonth.year}';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create Due for ${member['name'] ?? 'Member'}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Monthly Church Dues',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount *',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., 50.00',
                  prefixText: '\$ ',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: dueDateController,
                decoration: const InputDecoration(
                  labelText: 'Due Date',
                  border: OutlineInputBorder(),
                  hintText: 'DD/MM/YYYY',
                ),
                onTap: () => _selectDueDate(context, dueDateController),
                readOnly: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _createDueForMember(
              member,
              descriptionController.text,
              amountController.text,
              dueDateController.text,
            ),
            child: const Text('Create Due'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDueDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      controller.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
    }
  }

  Future<void> _createDueForMember(
    Map<String, dynamic> member,
    String description,
    String amountText,
    String dueDateText,
  ) async {
    if (description.trim().isEmpty || amountText.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Description and amount are required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final amount = double.tryParse(amountText.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Parse due date
      DateTime dueDate = DateTime.now().add(const Duration(days: 30));
      if (dueDateText.trim().isNotEmpty) {
        final parts = dueDateText.trim().split('/');
        if (parts.length == 3) {
          dueDate = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
      }

      final success = await FirebaseService.addDue(
        userId: member['id'] ?? '',
        description: description.trim(),
        amount: amount,
        dueDate: dueDate,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Due created successfully' : 'Failed to create due'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (success) {
          setState(() {}); // Refresh the UI
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error creating due'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildMessagesTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirebaseService.getAdminMessages(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Error Loading Messages',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text('${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final messages = snapshot.data ?? [];

        if (messages.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mail_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No Messages',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text('No support requests or messages'),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: messages.length,
          itemBuilder: (context, index) {
            try {
              if (index < 0 || index >= messages.length || messages.isEmpty) {
                return const SizedBox.shrink();
              }
              final message = messages[index];
              if (message == null) {
                return const SizedBox.shrink();
              }
              return _buildMessageCard(message);
            } catch (e) {
              print('Error building message at index $index: $e');
              return const SizedBox.shrink();
            }
          },
        );
      },
    );
  }

  Widget _buildMessageCard(Map<String, dynamic> message) {
    if (message.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final isRead = message['status']?.toString() == 'read';
    final subject = message['subject']?.toString() ?? 'No Subject';
    final messageText = message['message']?.toString() ?? '';
    final messageId = message['id']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRead ? Colors.grey[50] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRead ? Colors.grey[200]! : const Color(0xFF1976D2).withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isRead ? Icons.mail_outline : Icons.mail,
                color: isRead ? Colors.grey : const Color(0xFF1976D2),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  subject,
                  style: TextStyle(
                    fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              if (!isRead && messageId != null)
                GestureDetector(
                  onTap: () => _markMessageAsRead(messageId),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1976D2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Mark Read',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            messageText,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildActionCard(
            'Manage Announcements',
            'View, create, edit and delete announcements',
            Icons.campaign,
            Colors.blue,
            () => _navigateToAnnouncementsManagement(),
          ),
          _buildActionCard(
            'Refresh Statistics',
            'Update dashboard statistics',
            Icons.refresh,
            Colors.green,
            _loadDashboardStats,
          ),
          _buildActionCard(
            'Export User Data',
            'Download user data as CSV',
            Icons.download,
            Colors.purple,
            () => _showComingSoonDialog('Export functionality'),
          ),
          _buildActionCard(
            'System Settings',
            'Configure app settings',
            Icons.settings,
            Colors.orange,
            () => _showComingSoonDialog('Settings panel'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _approveUser(String userId) async {
    final success = await FirebaseService.approveUserAccess(userId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'User approved successfully' : 'Failed to approve user'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectUser(String userId) async {
    final success = await FirebaseService.rejectUserAccess(userId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'User rejected successfully' : 'Failed to reject user'),
          backgroundColor: success ? Colors.orange : Colors.red,
        ),
      );
    }
  }

  Future<void> _markMessageAsRead(String messageId) async {
    await FirebaseService.markMessageAsRead(messageId);
  }

  void _showCreateAnnouncementDialog() {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    final dateController = TextEditingController();
    final timeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Announcement'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: bodyController,
                decoration: const InputDecoration(labelText: 'Message'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: dateController,
                decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: timeController,
                decoration: const InputDecoration(labelText: 'Time (HH:MM)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty && bodyController.text.isNotEmpty) {
                final success = await FirebaseService.createAnnouncement(
                  title: titleController.text,
                  body: bodyController.text,
                  date: dateController.text.isNotEmpty 
                      ? dateController.text 
                      : DateTime.now().toString().split(' ')[0],
                  time: timeController.text.isNotEmpty 
                      ? timeController.text 
                      : '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Announcement created' : 'Failed to create announcement'),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Coming Soon'),
        content: Text('$feature will be available in a future update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
} 