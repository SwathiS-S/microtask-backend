import 'package:flutter/material.dart';

enum TaskStatus { draft, funded, open, assigned, inProgress, submitted, reviewed, completed, disputed, resolved, expired, cancelled }

enum WorkType { wfh, onsite, all }

class Task {
  final String id;
  final String title;
  final String description;
  final int amount;
  final String createdBy; // Business Lead ID
  final String? createdByName;
  final TaskStatus status;
  final String? acceptedBy; // User ID who accepted the task
  final WorkType workType;
  final String? finalFileUrl;
  final String? finalStatus;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? submittedAt;
  final DateTime? completedAt;
  final List<dynamic>? applications;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.amount,
    required this.createdBy,
    this.createdByName,
    required this.status,
    this.acceptedBy,
    this.workType = WorkType.wfh,
    this.finalFileUrl,
    this.finalStatus,
    required this.createdAt,
    this.acceptedAt,
    this.submittedAt,
    this.completedAt,
    this.applications,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['_id'] ?? json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      amount: json['amount'] ?? 0,
      createdBy: json['postedBy'] is Map ? json['postedBy']['_id'] : (json['postedBy'] ?? json['createdBy'] ?? ''),
      createdByName: json['postedBy'] is Map ? json['postedBy']['name'] : null,
      status: _statusFromString(json['status']),
      acceptedBy: json['acceptedBy'] is Map ? json['acceptedBy']['_id'] : json['acceptedBy'],
      workType: _workTypeFromString(json['workType']),
      finalFileUrl: json['finalFile'] != null ? json['finalFile']['path'] : null,
      finalStatus: json['finalStatus'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      acceptedAt: json['acceptedAt'] != null ? DateTime.parse(json['acceptedAt']) : null,
      submittedAt: json['submittedAt'] != null ? DateTime.parse(json['submittedAt']) : null,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      applications: json['applications'],
    );
  }

  static TaskStatus _statusFromString(String? status) {
    switch (status) {
      case 'draft':
        return TaskStatus.draft;
      case 'funded':
        return TaskStatus.funded;
      case 'open':
        return TaskStatus.open;
      case 'assigned':
        return TaskStatus.assigned;
      case 'in_progress':
      case 'inProgress':
        return TaskStatus.inProgress;
      case 'submitted':
        return TaskStatus.submitted;
      case 'reviewed':
        return TaskStatus.reviewed;
      case 'pending_release':
      case 'paid':
      case 'completed':
        return TaskStatus.completed;
      case 'disputed':
        return TaskStatus.disputed;
      case 'resolved':
        return TaskStatus.resolved;
      case 'expired':
        return TaskStatus.expired;
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
      case TaskStatus.draft:
        return 'Draft';
      case TaskStatus.funded:
        return 'Funded';
      case TaskStatus.open:
        return 'Available';
      case TaskStatus.assigned:
        return 'Assigned';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.submitted:
        return 'Submitted';
      case TaskStatus.reviewed:
        return 'Reviewed';
      case TaskStatus.completed:
        return 'Completed';
      case TaskStatus.disputed:
        return 'Disputed';
      case TaskStatus.resolved:
        return 'Resolved';
      case TaskStatus.expired:
        return 'Expired';
      case TaskStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get statusColor {
    switch (status) {
      case TaskStatus.draft:
        return Colors.grey;
      case TaskStatus.funded:
        return Colors.blueAccent;
      case TaskStatus.open:
        return Colors.blue;
      case TaskStatus.assigned:
        return Colors.teal;
      case TaskStatus.inProgress:
        return Colors.amber;
      case TaskStatus.submitted:
        return Colors.orange;
      case TaskStatus.reviewed:
        return Colors.cyan;
      case TaskStatus.completed:
        return Colors.green;
      case TaskStatus.disputed:
        return Colors.red;
      case TaskStatus.resolved:
        return Colors.indigo;
      case TaskStatus.expired:
        return Colors.black54;
      case TaskStatus.cancelled:
        return Colors.blueGrey;
    }
  }
}

