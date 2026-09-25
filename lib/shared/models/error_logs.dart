import 'package:equatable/equatable.dart';

enum ErrorSeverity { low, medium, high, critical }

class ErrorLogs extends Equatable {
  final String id;
  final String? userId;
  final String errorType;
  final String errorMessage;
  final String? stackTrace;
  final ErrorSeverity severity;
  final String? endpoint;
  final String? requestData;
  final String? userAgent;
  final String? ipAddress;
  final Map<String, dynamic>? metadata;
  final bool resolved;
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final DateTime createdAt;

  const ErrorLogs({
    required this.id,
    this.userId,
    required this.errorType,
    required this.errorMessage,
    this.stackTrace,
    this.severity = ErrorSeverity.medium,
    this.endpoint,
    this.requestData,
    this.userAgent,
    this.ipAddress,
    this.metadata,
    this.resolved = false,
    this.resolvedBy,
    this.resolvedAt,
    required this.createdAt,
  });

  factory ErrorLogs.fromJson(Map<String, dynamic> json) {
    return ErrorLogs(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      errorType: json['error_type'] as String,
      errorMessage: json['error_message'] as String,
      stackTrace: json['stack_trace'] as String?,
      severity: ErrorSeverity.values.firstWhere(
        (severity) => severity.name == json['severity'],
        orElse: () => ErrorSeverity.medium,
      ),
      endpoint: json['endpoint'] as String?,
      requestData: json['request_data'] as String?,
      userAgent: json['user_agent'] as String?,
      ipAddress: json['ip_address'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      resolved: json['resolved'] ?? false,
      resolvedBy: json['resolved_by'] as String?,
      resolvedAt: json['resolved_at'] != null ? DateTime.parse(json['resolved_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'error_type': errorType,
      'error_message': errorMessage,
      'stack_trace': stackTrace,
      'severity': severity.name,
      'endpoint': endpoint,
      'request_data': requestData,
      'user_agent': userAgent,
      'ip_address': ipAddress,
      'metadata': metadata,
      'resolved': resolved,
      'resolved_by': resolvedBy,
      'resolved_at': resolvedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  ErrorLogs copyWith({
    String? id,
    String? userId,
    String? errorType,
    String? errorMessage,
    String? stackTrace,
    ErrorSeverity? severity,
    String? endpoint,
    String? requestData,
    String? userAgent,
    String? ipAddress,
    Map<String, dynamic>? metadata,
    bool? resolved,
    String? resolvedBy,
    DateTime? resolvedAt,
    DateTime? createdAt,
  }) {
    return ErrorLogs(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      errorType: errorType ?? this.errorType,
      errorMessage: errorMessage ?? this.errorMessage,
      stackTrace: stackTrace ?? this.stackTrace,
      severity: severity ?? this.severity,
      endpoint: endpoint ?? this.endpoint,
      requestData: requestData ?? this.requestData,
      userAgent: userAgent ?? this.userAgent,
      ipAddress: ipAddress ?? this.ipAddress,
      metadata: metadata ?? this.metadata,
      resolved: resolved ?? this.resolved,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        errorType,
        errorMessage,
        stackTrace,
        severity,
        endpoint,
        requestData,
        userAgent,
        ipAddress,
        metadata,
        resolved,
        resolvedBy,
        resolvedAt,
        createdAt,
      ];
}
