import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/dues.dart';
import '../services/firebase_service.dart';
import 'auth_screen.dart';

class DuesScreen extends StatelessWidget {
  const DuesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseService.authStateChanges,
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;
        
        if (user == null) {
          return _buildGuestDuesPage(context);
        }
        
        return StreamBuilder<List<Due>>(
          stream: FirebaseService.getDuesStream(user.uid),
          builder: (context, duesSnapshot) {
            if (duesSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(50.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: Color(0xFF1976D2),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Loading dues information...',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (duesSnapshot.hasError) {
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
                      const Text(
                        'Error loading dues',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please try again later',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final dues = duesSnapshot.data ?? [];
            final statistics = FirebaseService.calculateDuesStatistics(dues);
            final outstandingDues = FirebaseService.getOutstandingDues(dues);
            final paymentHistory = FirebaseService.getPaymentHistory(dues);

            return _buildDuesContent(context, statistics, outstandingDues, paymentHistory, user);
          },
        );
      },
    );
  }

  Widget _buildGuestDuesPage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.account_balance_wallet_outlined,
            size: 64,
            color: Color(0xFF1976D2),
          ),
          const SizedBox(height: 20),
          const Text(
            'Sign in to view dues',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please sign in to access your dues information',
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

  Widget _buildDuesContent(BuildContext context, DuesStatistics statistics, List<Due> outstandingDues, List<Due> paymentHistory, User user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistics Cards
          _buildDuesStatisticsCards(statistics),
          const SizedBox(height: 24),
          
          // Outstanding Dues Section
          _buildSectionHeader('Outstanding Dues', Icons.warning_amber_outlined, Colors.orange),
          const SizedBox(height: 12),
          _buildOutstandingDuesSection(context, outstandingDues, user),
          const SizedBox(height: 24),
          
          // Payment History Section
          _buildSectionHeader('Payment History', Icons.history, Colors.green),
          const SizedBox(height: 12),
          _buildPaymentHistorySection(context, paymentHistory),
        ],
      ),
    );
  }

  Widget _buildDuesStatisticsCards(DuesStatistics statistics) {
    return Column(
      children: [
        // Progress Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1976D2).withOpacity(0.1),
                const Color(0xFF42A5F5).withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF1976D2).withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.account_balance_wallet,
                size: 48,
                color: Color(0xFF1976D2),
              ),
              const SizedBox(height: 16),
              const Text(
                'Payment Progress',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Progress Bar
              Container(
                height: 12,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.grey[200],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: statistics.paymentPercentage / 100,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getProgressColor(statistics.progressColor),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${statistics.paymentPercentage.toStringAsFixed(1)}% Complete',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _getProgressColor(statistics.progressColor),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Statistics Row
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Dues',
                '₦${statistics.totalAmount.toStringAsFixed(2)}',
                Icons.assessment,
                const Color(0xFF1976D2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Paid',
                '₦${statistics.paidAmount.toStringAsFixed(2)}',
                Icons.check_circle,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Outstanding',
                '₦${statistics.unpaidAmount.toStringAsFixed(2)}',
                Icons.pending,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Count',
                '${statistics.paidCount}/${statistics.totalCount}',
                Icons.format_list_numbered,
                const Color(0xFF42A5F5),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getProgressColor(String progressColor) {
    switch (progressColor) {
      case 'success':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'danger':
        return Colors.red;
      default:
        return const Color(0xFF1976D2);
    }
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildOutstandingDuesSection(BuildContext context, List<Due> outstandingDues, User user) {
    if (outstandingDues.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green[200]!),
        ),
        child: Column(
          children: [
            Icon(Icons.check_circle, size: 48, color: Colors.green[600]),
            const SizedBox(height: 12),
            const Text(
              'All caught up!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'You have no outstanding dues',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: outstandingDues.map((due) => _buildDueCard(context, due, user, true)).toList(),
    );
  }

  Widget _buildPaymentHistorySection(BuildContext context, List<Due> paymentHistory) {
    if (paymentHistory.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Icon(Icons.history, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            const Text(
              'No payment history',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your payment history will appear here',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: paymentHistory.map((due) => _buildDueCard(context, due, null, false)).toList(),
    );
  }

  Widget _buildDueCard(BuildContext context, Due due, User? user, bool isOutstanding) {
    final isOverdue = due.isOverdue;
    final cardColor = isOverdue ? Colors.red[50] : Colors.white;
    final borderColor = isOverdue ? Colors.red[200] : Colors.grey[200];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        due.description,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${due.id.substring(0, 8)}...',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  due.formattedAmount,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1976D2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isOutstanding ? 'Due Date' : 'Payment Date',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        isOutstanding ? due.formattedDueDate : due.formattedPaymentDate,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isOverdue ? Colors.red[700] : Colors.black87,
                        ),
                      ),
                      if (isOutstanding) ...[
                        const SizedBox(height: 2),
                        Text(
                          due.dueMessage,
                          style: TextStyle(
                            fontSize: 12,
                            color: isOverdue ? Colors.red[600] : Colors.orange[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ] else if (due.paymentDate != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          due.formattedPaymentTime,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(due.statusColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    due.status.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            if (isOutstanding && user != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showPaymentComingSoon(context);
                      },
                      icon: const Icon(Icons.payment, size: 16),
                      label: const Text('Pay Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      _showContactAdminDialog(context, user, due.id);
                    },
                    icon: const Icon(Icons.message, size: 16),
                    label: const Text('Contact'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1976D2),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String statusColor) {
    switch (statusColor) {
      case 'success':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'danger':
        return Colors.red;
      case 'secondary':
        return Colors.grey;
      default:
        return const Color(0xFF1976D2);
    }
  }

  void _showPaymentComingSoon(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Gateway'),
        content: const Text('Payment gateway integration is coming soon! You can contact admin for payment instructions.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showContactAdminDialog(BuildContext context, User user, String dueId) {
    final subjectController = TextEditingController();
    final messageController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Contact Admin'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: subjectController,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: messageController,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                final subject = subjectController.text.trim();
                final message = messageController.text.trim();

                if (subject.isEmpty || message.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in all fields')),
                  );
                  return;
                }

                setState(() => isLoading = true);

                final success = await FirebaseService.sendMessageToAdmin(
                  subject: subject,
                  message: message,
                  userId: user.uid,
                  dueId: dueId,
                );

                setState(() => isLoading = false);

                if (success) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Message sent successfully')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to send message. Please try again.')),
                  );
                }
              },
              child: isLoading 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }
} 