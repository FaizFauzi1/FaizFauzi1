import 'package:equatable/equatable.dart';

class ApiLog extends Equatable {
  final String id;
  final String? userId;
  final String endpoint;
  final String method;
  final int? statusCode;
  final int? responseTime;
  final String? ipAddress;
  final String? userAgent;
  final Map<String, dynamic>? requestData;
  final Map<String, dynamic>? responseData;
  final String? errorMessage;
  final DateTime createdAt;

  const ApiLog({
    required this.id,
    this.userId,
    required this.endpoint,
    required this.method,
    this.statusCode,
    this.responseTime,
    this.ipAddress,
    this.userAgent,
    this.requestData,
    this.responseData,
    this.errorMessage,
    required this.createdAt,
  });

  factory ApiLog.fromJson(Map<String, dynamic> json) {
    return ApiLog(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      endpoint: json['endpoint'] as String,
      method: json['method'] as String,
      statusCode: json['status_code'] as int?,
      responseTime: json['response_time'] as int?,
      ipAddress: json['ip_address'] as String?,
      userAgent: json['user_agent'] as String?,
      requestData: json['request_data'] as Map<String, dynamic>?,
      responseData: json['response_data'] as Map<String, dynamic>?,
      errorMessage: json['error_message'] as String?,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'endpoint': endpoint,
      'method': method,
      'status_code': statusCode,
      'response_time': responseTime,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'request_data': requestData,
      'response_data': responseData,
      'error_message': errorMessage,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ApiLog copyWith({
    String? id,
    String? userId,
    String? endpoint,
    String? method,
    int? statusCode,
    int? responseTime,
    String? ipAddress,
    String? userAgent,
    Map<String, dynamic>? requestData,
    Map<String, dynamic>? responseData,
    String? errorMessage,
    DateTime? createdAt,
  }) {
    return ApiLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      endpoint: endpoint ?? this.endpoint,
      method: method ?? this.method,
      statusCode: statusCode ?? this.statusCode,
      responseTime: responseTime ?? this.responseTime,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      requestData: requestData ?? this.requestData,
      responseData: responseData ?? this.responseData,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        endpoint,
        method,
        statusCode,
        responseTime,
        ipAddress,
        userAgent,
        requestData,
        responseData,
        errorMessage,
        createdAt,
      ];
}
