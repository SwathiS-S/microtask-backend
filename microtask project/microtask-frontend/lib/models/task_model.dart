import 'package:flutter/material.dart';

enum TaskStatus { open, accepted, submitted, approved, paid, rejected, cancelled }

enum WorkType { wfh, onsite, all }

class Task {
  final String id;
  final String title;
  final String description;
  final int amount;
  final String createdBy; // Business Lead ID
  final TaskStatus status;
  final String? acceptedBy; // User ID who accepted the task
  final WorkType workType;
  final String? finalFileUrl;
  final String? finalStatus;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? submittedAt;
  final DateTime? completedAt;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.amount,
    required this.createdBy,
    required this.status,
    this.acceptedBy,
    this.workType = WorkType.wfh,
    this.finalFileUrl,
    this.finalStatus,
    required this.createdAt,
    this.acceptedAt,
    this.submittedAt,
    this.completedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['_id'] ?? json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      amount: json['amount'] ?? 0,
      createdBy: json['postedBy'] ?? json['createdBy'] ?? '',
      status: _statusFromString(json['status']),
      acceptedBy: json['acceptedBy'],
      workType: _workTypeFromString(json['workType']),
      finalFileUrl: json['finalFile'] != null ? json['finalFile']['path'] : null,
      finalStatus: json['finalStatus'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      acceptedAt: json['acceptedAt'] != null ? DateTime.parse(json['acceptedAt']) : null,
      submittedAt: json['submittedAt'] != null ? DateTime.parse(json['submittedAt']) : null,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
    );
  }

  static TaskStatus _statusFromString(String? status) {
    switch (status) {
      case 'open':
      case 'created':
        return TaskStatus.open;
      case 'accepted':
        return TaskStatus.accepted;
      case 'submitted':
        return TaskStatus.submitted;
      case 'approved':
        return TaskStatus.approved;
      case 'paid':
        return TaskStatus.paid;
      case 'rejected':
        return TaskStatus.rejected;
      case 'cancelled':
        return TaskStatus.cancelled;
      default:
        return TaskStatus.open;
    }
  }

  static WorkType _workTypeFromString(String? type) {
    switch (type) {
      case 'WFH':
        return WorkType.wfh;
      case 'ONSITE':
        return WorkType.onsite;
      case 'ALL':
        return WorkType.all;
      default:
        return WorkType.wfh;
    }
  }

  String get statusDisplay {
    switch (status) {
      case TaskStatus.open:
        return 'Available';
      case TaskStatus.accepted:
        return 'Accepted';
      case TaskStatus.submitted:
        return 'Submitted';
      case TaskStatus.approved:
        return 'Approved';
      case TaskStatus.paid:
        return 'Paid';
      case TaskStatus.rejected:
        return 'Rejected';
      case TaskStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get statusColor {
    switch (status) {
      case TaskStatus.open:
        return Colors.blue;
      case TaskStatus.accepted:
        return Colors.green;
      case TaskStatus.submitted:
        return Colors.orange;
      case TaskStatus.approved:
        return Colors.teal;
      case TaskStatus.paid:
        return Colors.indigo;
      case TaskStatus.rejected:
        return Colors.red;
      case TaskStatus.cancelled:
        return Colors.grey;
    }
  }
}

