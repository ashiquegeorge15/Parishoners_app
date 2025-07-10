import 'package:cloud_firestore/cloud_firestore.dart';

class Due {
  final String id;
  final String userId;
  final String description;
  final double amount;
  final DateTime dueDate;
  final String status; // paid, unpaid, pending, overdue
  final DateTime? paymentDate;

  Due({
    required this.id,
    required this.userId,
    required this.description,
    required this.amount,
    required this.dueDate,
    required this.status,
    this.paymentDate,
  });

  factory Due.fromMap(Map<String, dynamic> data, {String? id}) {
    return Due(
      id: id ?? data['id'] ?? _generateId(),
      userId: data['userId'] ?? '',
      description: data['description'] ?? 'Unnamed Due',
      amount: (data['amount'] ?? 0).toDouble(),
      dueDate: data['dueDate'] is Timestamp 
          ? (data['dueDate'] as Timestamp).toDate()
          : DateTime.tryParse(data['dueDate'].toString()) ?? DateTime.now(),
      status: data['status'] ?? 'unpaid',
      paymentDate: data['paymentDate'] != null
          ? (data['paymentDate'] is Timestamp 
              ? (data['paymentDate'] as Timestamp).toDate()
              : DateTime.tryParse(data['paymentDate'].toString()))
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'description': description,
      'amount': amount,
      'dueDate': Timestamp.fromDate(dueDate),
      'status': status,
      'paymentDate': paymentDate != null ? Timestamp.fromDate(paymentDate!) : null,
    };
  }

  static String _generateId() {
    return 'due_${DateTime.now().millisecondsSinceEpoch}_${(DateTime.now().microsecond % 1000)}';
  }

  // Helper methods for UI
  bool get isPaid => status.toLowerCase() == 'paid';
  bool get isOverdue => !isPaid && DateTime.now().isAfter(dueDate);
  
  int get daysUntilDue {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final dueStart = DateTime(dueDate.year, dueDate.month, dueDate.day);
    
    return dueStart.difference(todayStart).inDays;
  }

  String get dueMessage {
    final days = daysUntilDue;
    if (days < 0) {
      return 'Overdue by ${days.abs()} days';
    } else if (days == 0) {
      return 'Due today';
    } else if (days == 1) {
      return 'Due tomorrow';
    } else if (days < 7) {
      return 'Due in $days days';
    } else {
      return 'Due in $days days';
    }
  }

  String get statusColor {
    switch (status.toLowerCase()) {
      case 'paid':
        return 'success';
      case 'pending':
        return 'warning';
      case 'overdue':
        return 'danger';
      case 'cancelled':
        return 'secondary';
      default:
        return 'primary';
    }
  }

  String get formattedAmount {
    return '₦${amount.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}';
  }

  String get formattedDueDate {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dueDate.day} ${months[dueDate.month - 1]} ${dueDate.year}';
  }

  String get formattedPaymentDate {
    if (paymentDate == null) return 'N/A';
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${paymentDate!.day} ${months[paymentDate!.month - 1]} ${paymentDate!.year}';
  }

  String get formattedPaymentTime {
    if (paymentDate == null) return '';
    final hour = paymentDate!.hour;
    final minute = paymentDate!.minute.toString().padLeft(2, '0');
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$displayHour:$minute $ampm';
  }
}

class DuesStatistics {
  final double totalAmount;
  final double paidAmount;
  final double unpaidAmount;
  final int totalCount;
  final int paidCount;
  final int unpaidCount;

  DuesStatistics({
    required this.totalAmount,
    required this.paidAmount,
    required this.unpaidAmount,
    required this.totalCount,
    required this.paidCount,
    required this.unpaidCount,
  });

  double get paymentPercentage {
    return totalAmount > 0 ? (paidAmount / totalAmount) * 100 : 0;
  }

  String get progressColor {
    final percentage = paymentPercentage;
    if (percentage < 30) return 'danger';
    if (percentage < 70) return 'warning';
    return 'success';
  }
} 