import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../main.dart';
import '../models/event.dart';
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
  
  // Dues management state
  String _duesSearchQuery = '';
  bool _showOnlyMembersWithDues = false;

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
          Tab(text: 'Users', icon: Icon(Icons.people, size: 14)),
          Tab(text: 'Events', icon: Icon(Icons.event, size: 14)),
          Tab(text: 'Dues', icon: Icon(Icons.payment, size: 14)),
          Tab(text: 'Pending', icon: Icon(Icons.schedule, size: 14)),
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
          _buildUsersTab(),
          _buildEventsTab(),
          _buildDuesTab(),
          _buildPendingApprovalTab(),
          _buildActionsTab(),
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
    
    final isActive = user['isActive'] ?? true;
    final userName = user['name']?.toString() ?? user['email']?.toString() ?? 'Unknown';
    final userEmail = user['email']?.toString() ?? '';
    final userRole = user['role']?.toString() ?? 'Member';

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
            backgroundColor: const Color(0xFF1976D2),
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
              color: const Color(0xFF1976D2).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              userRole,
              style: const TextStyle(
                color: Color(0xFF1976D2),
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
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: FirebaseService.getMembersWithDues(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Color(0xFF1976D2)),
                SizedBox(height: 16),
                Text('Loading dues information...'),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Error Loading Dues',
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

        final allMembers = snapshot.data ?? [];
        final membersWithDues = allMembers.where((member) => 
          (member['outstandingDues'] as double) > 0).toList();

        return Column(
          children: [
            // Statistics cards
            _buildDuesStatisticsCards(allMembers),
            const SizedBox(height: 16),
            
            // Filter and search bar
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
                      child: TextField(
                        onChanged: (value) => setState(() => _duesSearchQuery = value),
                        decoration: const InputDecoration(
                          hintText: 'Search members...',
                          prefixIcon: Icon(Icons.search),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Filter buttons
                  Container(
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
                    child: ToggleButtons(
                      borderRadius: BorderRadius.circular(12),
                      children: const [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('All'),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('With Dues'),
                        ),
                      ],
                      isSelected: [!_showOnlyMembersWithDues, _showOnlyMembersWithDues],
                      onPressed: (index) {
                        setState(() {
                          _showOnlyMembersWithDues = index == 1;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            // Members list
            Expanded(
              child: _buildMembersList(allMembers),
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

  Widget _buildDuesStatisticsCards(List<Map<String, dynamic>> allMembers) {
    double totalOutstanding = 0;
    double totalPaid = 0;
    int membersWithDues = 0;
    int totalDuesCount = 0;

    for (var member in allMembers) {
      final duesHistory = member['duesHistory'] as List? ?? [];
      bool hasUnpaidDues = false;

      for (var dues in duesHistory) {
        totalDuesCount++;
        final amount = (dues['amount'] as num?)?.toDouble() ?? 0;

        if (dues['status'] == 'paid') {
          totalPaid += amount;
        } else {
          totalOutstanding += amount;
          hasUnpaidDues = true;
        }
      }

      if (hasUnpaidDues) {
        membersWithDues++;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Outstanding',
              '\$${totalOutstanding.toStringAsFixed(2)}',
              Icons.schedule,
              Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Paid',
              '\$${totalPaid.toStringAsFixed(2)}',
              Icons.check_circle,
              Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Members w/ Dues',
              '$membersWithDues',
              Icons.people,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Total Entries',
              '$totalDuesCount',
              Icons.receipt,
              Colors.purple,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildMembersList(List<Map<String, dynamic>> allMembers) {
    // Filter members based on search query and dues filter
    List<Map<String, dynamic>> filteredMembers = allMembers.where((member) {
      // Search filter
      if (_duesSearchQuery.isNotEmpty) {
        final query = _duesSearchQuery.toLowerCase();
        final name = (member['name'] as String).toLowerCase();
        final email = (member['email'] as String).toLowerCase();
        if (!name.contains(query) && !email.contains(query)) {
          return false;
        }
      }

      // Dues filter
      if (_showOnlyMembersWithDues) {
        return (member['outstandingDues'] as double) > 0;
      }

      return true;
    }).toList();

    if (filteredMembers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _showOnlyMembersWithDues ? Icons.money_off : Icons.people_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _showOnlyMembersWithDues ? 'No Members with Outstanding Dues' : 'No Members Found',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(_duesSearchQuery.isNotEmpty ? 'Try adjusting your search' : 'No registered members yet'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredMembers.length,
      itemBuilder: (context, index) {
        final member = filteredMembers[index];
        return _buildEnhancedMemberDueCard(member);
      },
    );
  }

  Widget _buildEnhancedMemberDueCard(Map<String, dynamic> member) {
    final memberName = member['name']?.toString() ?? 'Unknown';
    final memberEmail = member['email']?.toString() ?? '';
    final memberPhone = member['phone']?.toString() ?? '';
    final memberId = member['id']?.toString() ?? '';
    final outstandingDues = (member['outstandingDues'] as double?) ?? 0.0;
    final duesHistory = member['duesHistory'] as List? ?? [];

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
          // Member header
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: outstandingDues > 0 ? Colors.orange[100] : const Color(0xFF1976D2).withOpacity(0.1),
                child: Icon(
                  outstandingDues > 0 ? Icons.schedule : Icons.person,
                  color: outstandingDues > 0 ? Colors.orange : const Color(0xFF1976D2),
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
                    if (memberPhone.isNotEmpty)
                      Text(
                        memberPhone,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (outstandingDues > 0) ...[
                    Text(
                      '\$${outstandingDues.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const Text(
                      'Outstanding',
                      style: TextStyle(fontSize: 10, color: Colors.orange),
                    ),
                  ] else ...[
                    const Text(
                      'No Dues',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showCreateDueDialogForMember(member),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Due'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showDuesHistoryDialog(member),
                  icon: const Icon(Icons.history, size: 16),
                  label: const Text('History'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
          
          // Recent dues preview
          if (duesHistory.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Recent Dues (${duesHistory.length})',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
            ),
            const SizedBox(height: 8),
            ...duesHistory.take(2).map((due) => _buildDueItem(due)),
            if (duesHistory.length > 2)
              TextButton(
                onPressed: () => _showDuesHistoryDialog(member),
                child: Text('View ${duesHistory.length - 2} more...'),
              ),
          ],
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

  void _showDuesHistoryDialog(Map<String, dynamic> member) {
    final memberName = member['name']?.toString() ?? 'Unknown Member';
    final duesHistory = member['duesHistory'] as List? ?? [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Dues History: $memberName'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: duesHistory.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No dues history found'),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: duesHistory.length,
                  itemBuilder: (context, index) {
                    final due = duesHistory[index];
                    final description = due['description']?.toString() ?? 'No description';
                    final amount = (due['amount'] as num?)?.toDouble() ?? 0.0;
                    final status = due['status']?.toString() ?? 'unpaid';
                    final dueDate = due['dueDate']?.toString() ?? '';
                    final isPaid = status.toLowerCase() == 'paid';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          isPaid ? Icons.check_circle : Icons.schedule,
                          color: isPaid ? Colors.green : Colors.orange,
                        ),
                        title: Text(description),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Amount: \$${amount.toStringAsFixed(2)}'),
                            if (dueDate.isNotEmpty) Text('Due: $dueDate'),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isPaid ? Colors.green : Colors.orange,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isPaid ? 'Paid' : 'Unpaid',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (!isPaid)
                              TextButton(
                                onPressed: () async {
                                  final success = await FirebaseService.markDuesAsPaid(
                                    userId: member['id'],
                                    duesIndex: index,
                                  );
                                  if (success && mounted) {
                                    Navigator.pop(context);
                                    setState(() {});
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Dues marked as paid'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                },
                                child: const Text('Mark Paid', style: TextStyle(fontSize: 10)),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingApprovalTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: FirebaseService.getPendingApprovalRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Color(0xFF1976D2)),
                SizedBox(height: 16),
                Text('Loading pending approvals...'),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Error Loading Pending Approvals',
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
                Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                SizedBox(height: 16),
                Text(
                  'No Pending Approvals',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text('All registration requests have been processed'),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pending Approval Requests',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        Text(
                          '${pendingRequests.length} users waiting for approval',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Pending requests list
            Expanded(
              child: ListView.builder(
                itemCount: pendingRequests.length,
                itemBuilder: (context, index) {
                  final request = pendingRequests[index];
                  return _buildPendingRequestCard(request);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPendingRequestCard(Map<String, dynamic> request) {
    final name = request['name']?.toString() ?? 'Unknown';
    final email = request['email']?.toString() ?? '';
    final createdAt = request['createdAt'] as Timestamp?;
    final collection = request['collection']?.toString() ?? 'users';
    
    String timeAgo = 'Just now';
    if (createdAt != null) {
      final duration = DateTime.now().difference(createdAt.toDate());
      if (duration.inDays > 0) {
        timeAgo = '${duration.inDays} days ago';
      } else if (duration.inHours > 0) {
        timeAgo = '${duration.inHours} hours ago';
      } else if (duration.inMinutes > 0) {
        timeAgo = '${duration.inMinutes} minutes ago';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
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
                radius: 24,
                backgroundColor: Colors.orange[100],
                child: const Icon(Icons.person, color: Colors.orange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      email,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Requested $timeAgo',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'PENDING',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _approveUser(request['id'], collection),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _rejectUser(request['id'], collection),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _approveUser(String userId, String collection) async {
    try {
      final success = await FirebaseService.approveUserAccess(userId, collection);
      
      if (success && mounted) {
        setState(() {}); // Refresh the tab
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User approved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to approve user'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error approving user: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectUser(String userId, String collection) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject User'),
        content: const Text('Are you sure you want to reject this user? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final success = await FirebaseService.rejectUserAccess(userId, collection);
      
      if (success && mounted) {
        setState(() {}); // Refresh the tab
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User rejected'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to reject user'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error rejecting user: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildEventsTab() {
    return Column(
      children: [
        // Header with Add Event button
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Events Management',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1976D2),
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showCreateEventDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Event'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Events list
        Expanded(
          child: StreamBuilder<List<Event>>(
            stream: FirebaseService.getEventsAsObjects(),
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
                        'Error Loading Events',
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

              final events = snapshot.data ?? [];

              if (events.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_note, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No Events',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text('Create your first event to get started'),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return _buildEventCard(event);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEventCard(Event event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF1976D2).withOpacity(0.2),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getCategoryColor(event.category).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getCategoryIcon(event.category),
                  color: _getCategoryColor(event.category),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      event.categoryDisplayName,
                      style: TextStyle(
                        color: _getCategoryColor(event.category),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _showEditEventDialog(event);
                      break;
                    case 'delete':
                      _showDeleteEventDialog(event);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 16),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                event.formattedDateTime,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  event.location,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          if (event.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              event.description,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
                height: 1.3,
              ),
            ),
          ],
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

  // Event management methods
  void _showCreateEventDialog() {
    _showEventDialog();
  }

  void _showEditEventDialog(Event event) {
    _showEventDialog(event: event);
  }

  void _showEventDialog({Event? event}) {
    final isEditing = event != null;
    final titleController = TextEditingController(text: event?.title ?? '');
    final descriptionController = TextEditingController(text: event?.description ?? '');
    final locationController = TextEditingController(text: event?.location ?? '');
    
    DateTime selectedDate = event?.date ?? DateTime.now();
    TimeOfDay? selectedTime = event?.time != null ? TimeOfDay.fromDateTime(event!.time!) : null;
    bool isAllDay = event?.isAllDay ?? false;
    String selectedCategory = event?.category ?? 'other';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Event' : 'Create Event'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Event Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'worship', child: Text('Worship')),
                      DropdownMenuItem(value: 'community', child: Text('Community')),
                      DropdownMenuItem(value: 'education', child: Text('Education')),
                      DropdownMenuItem(value: 'meeting', child: Text('Meeting')),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedCategory = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) {
                              setDialogState(() {
                                selectedDate = date;
                              });
                            }
                          },
                          child: Text('Date: ${_formatDateShort(selectedDate)}'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('All Day Event'),
                    value: isAllDay,
                    onChanged: (value) {
                      setDialogState(() {
                        isAllDay = value!;
                        if (isAllDay) selectedTime = null;
                      });
                    },
                  ),
                  if (!isAllDay) ...[
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: selectedTime ?? TimeOfDay.now(),
                        );
                        if (time != null) {
                          setDialogState(() {
                            selectedTime = time;
                          });
                        }
                      },
                      child: Text(selectedTime != null
                          ? 'Time: ${selectedTime!.format(context)}'
                          : 'Select Time'),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty ||
                    locationController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all required fields')),
                  );
                  return;
                }

                DateTime? eventDateTime;
                if (!isAllDay && selectedTime != null) {
                  eventDateTime = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    selectedTime!.hour,
                    selectedTime!.minute,
                  );
                }

                try {
                  if (isEditing) {
                    await FirebaseService.updateEvent(
                      eventId: event!.id,
                      title: titleController.text.trim(),
                      description: descriptionController.text.trim(),
                      eventDate: selectedDate,
                      location: locationController.text.trim(),
                      eventTime: eventDateTime,
                      isAllDay: isAllDay,
                      category: selectedCategory,
                    );
                  } else {
                    await FirebaseService.addEvent(
                      title: titleController.text.trim(),
                      description: descriptionController.text.trim(),
                      eventDate: selectedDate,
                      location: locationController.text.trim(),
                      eventTime: eventDateTime,
                      isAllDay: isAllDay,
                      category: selectedCategory,
                    );
                  }

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isEditing
                            ? 'Event updated successfully'
                            : 'Event created successfully'),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: Text(isEditing ? 'Update' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteEventDialog(Event event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text('Are you sure you want to delete "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseService.deleteEvent(event.id);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Event deleted successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting event: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Helper methods for event categories
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'worship':
        return Colors.purple;
      case 'community':
        return Colors.green;
      case 'education':
        return Colors.blue;
      case 'meeting':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'worship':
        return Icons.church;
      case 'community':
        return Icons.people;
      case 'education':
        return Icons.school;
      case 'meeting':
        return Icons.meeting_room;
      default:
        return Icons.event;
    }
  }

  String _formatDateShort(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 