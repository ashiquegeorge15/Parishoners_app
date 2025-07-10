import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../services/firebase_service.dart';
import 'auth_screen.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<MemberData> _allMembers = [];
  List<MemberData> _filteredMembers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMembers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredMembers = List.from(_allMembers);
      } else {
        _filteredMembers = _allMembers.where((member) =>
          member.name.toLowerCase().contains(query) ||
          member.email.toLowerCase().contains(query) ||
          member.phone.toLowerCase().contains(query)
        ).toList();
      }
    });
  }

  Future<void> _loadMembers() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Check if user is authenticated
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() {
          _error = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      // Fetch users from Firestore
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();

      if (querySnapshot.docs.isEmpty) {
        setState(() {
          _allMembers = [];
          _filteredMembers = [];
          _isLoading = false;
        });
        return;
      }

      final members = <MemberData>[];
      
      for (var doc in querySnapshot.docs) {
        final userData = doc.data();
        final member = MemberData.fromFirestore(doc.id, userData);
        
        // Load profile picture asynchronously (but don't wait for it)
        _getProfilePicUrl(doc.id, userData).then((url) {
          if (mounted) {
            setState(() {
              member.profilePictureUrl = url;
            });
          }
        });
        
        members.add(member);
      }

      // Sort by name
      members.sort((a, b) => a.name.compareTo(b.name));

      setState(() {
        _allMembers = members;
        _filteredMembers = List.from(members);
        _isLoading = false;
      });

    } catch (error) {
      setState(() {
        _error = 'Error loading members: $error';
        _isLoading = false;
      });
    }
  }

  Future<String> _getProfilePicUrl(String userId, Map<String, dynamic> userData) async {
    try {
      // First check if the user has a photoURL in their profile
      if (userData['photoURL'] != null && userData['photoURL'].toString().isNotEmpty) {
        return userData['photoURL'];
      }
      
      // Try multiple possible locations in Storage
      final possiblePaths = [
        'profile_pics/$userId',
        'profile_pics/$userId.jpg',
        'profile_pics/$userId.png',
        'profileImages/$userId',
        'profileImages/$userId.jpg',
        'profileImages/$userId.png',
        'users/$userId/profile',
        'users/$userId/profile.jpg',
        'users/$userId/profile.png',
      ];
      
      // Try each path in order
      for (final path in possiblePaths) {
        try {
          final url = await FirebaseStorage.instance.ref(path).getDownloadURL();
          if (url.isNotEmpty) return url;
        } catch (e) {
          // Continue to next path
        }
      }
      
      // Return empty string to indicate no profile picture found
      return '';
    } catch (error) {
      return '';
    }
  }

  String _generateInitials(String name) {
    if (name.isEmpty) return 'U';
    
    final nameParts = name.trim().split(RegExp(r'\s+'));
    if (nameParts.length == 1) {
      return nameParts[0][0].toUpperCase();
    } else if (nameParts.length > 1) {
      return (nameParts[0][0] + nameParts[nameParts.length - 1][0]).toUpperCase();
    }
    return 'U';
  }

  void _showMemberDetails(MemberData member) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Member Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Profile Picture
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF1976D2),
                    width: 3,
                  ),
                ),
                child: ClipOval(
                  child: member.profilePictureUrl.isNotEmpty
                      ? Image.network(
                          member.profilePictureUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildInitialsAvatar(member.name, 120),
                        )
                      : _buildInitialsAvatar(member.name, 120),
                ),
              ),
              const SizedBox(height: 20),
              
              // Member Information
              _buildDetailRow('Name', member.name),
              _buildDetailRow('Email', member.email),
              _buildDetailRow('Phone', member.phone),
              _buildDetailRow('Address', member.address),
              _buildDetailRow('Gender', member.gender),
              _buildDetailRow('Date of Birth', member.dob),
              
              const SizedBox(height: 20),
              
              // Close Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isEmpty ? 'N/A' : value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialsAvatar(String name, double size) {
    final initials = _generateInitials(name);
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1976D2),
            Color(0xFF42A5F5),
          ],
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Members'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF8F9FA),
      body: StreamBuilder<User?>(
        stream: FirebaseService.authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1976D2),
              ),
            );
          }
          
          final user = snapshot.data;
          
          if (user == null) {
            return _buildGuestView();
          }
          
          // User is authenticated, trigger members loading if not already loaded
          if (_allMembers.isEmpty && !_isLoading) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadMembers();
            });
          }
          
          return _buildMembersView();
        },
      ),
    );
  }

  Widget _buildGuestView() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.people_outline,
            size: 64,
            color: Color(0xFF1976D2),
          ),
          const SizedBox(height: 20),
          const Text(
            'Sign in to view members',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please sign in to access the member directory',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AuthScreen(),
                ),
              );
            },
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search members...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF1976D2),
                  width: 2,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Members List
          Expanded(
            child: _buildMembersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersList() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Color(0xFF1976D2),
            ),
            SizedBox(height: 16),
            Text(
              'Loading members...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadMembers,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredMembers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isNotEmpty
                  ? 'No members found matching your search'
                  : 'No members found',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isNotEmpty
                  ? 'Try adjusting your search terms'
                  : 'Members will appear here when available',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMembers,
      child: ListView.builder(
        itemCount: _filteredMembers.length,
        itemBuilder: (context, index) {
          final member = _filteredMembers[index];
          return _buildMemberCard(member);
        },
      ),
    );
  }

  Widget _buildMemberCard(MemberData member) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showMemberDetails(member),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Profile Picture
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF1976D2),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: member.profilePictureUrl.isNotEmpty
                      ? Image.network(
                          member.profilePictureUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildInitialsAvatar(member.name, 60),
                        )
                      : _buildInitialsAvatar(member.name, 60),
                ),
              ),
              const SizedBox(width: 16),
              
              // Member Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (member.phone.isNotEmpty)
                      Text(
                        member.phone,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    if (member.address.isNotEmpty)
                      Text(
                        member.address,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (member.gender.isNotEmpty && member.gender != 'Choose...')
                      Text(
                        member.gender,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                  ],
                ),
              ),
              
              // View Icon
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF1976D2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MemberData {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String gender;
  final String dob;
  String profilePictureUrl;

  MemberData({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.gender,
    required this.dob,
    this.profilePictureUrl = '',
  });

  factory MemberData.fromFirestore(String id, Map<String, dynamic> data) {
    return MemberData(
      id: id,
      name: data['name']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      phone: data['phno']?.toString() ?? '',
      address: data['address']?.toString() ?? '',
      gender: data['gender']?.toString() ?? '',
      dob: data['dob']?.toString() ?? '',
    );
  }
} 