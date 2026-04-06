// ─── Admin Dashboard Metrics ──────────────────────────────────────────────

class DashboardMetrics {
  final List<DauEntry> dauData;
  final List<RequestEntry> requestData;
  final List<ErrorEntry> errorData;
  final List<SlowApiEntry> slowApis;

  const DashboardMetrics({
    required this.dauData,
    required this.requestData,
    required this.errorData,
    required this.slowApis,
  });

  factory DashboardMetrics.fromJson(Map<String, dynamic> json) {
    return DashboardMetrics(
      dauData: (json['dauData'] as List<dynamic>? ?? [])
          .map((e) => DauEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      requestData: (json['requestData'] as List<dynamic>? ?? [])
          .map((e) => RequestEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      errorData: (json['errorData'] as List<dynamic>? ?? [])
          .map((e) => ErrorEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      slowApis: (json['slowApis'] as List<dynamic>? ?? [])
          .map((e) => SlowApiEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DauEntry {
  final String date;
  final int count;
  const DauEntry({required this.date, required this.count});
  factory DauEntry.fromJson(Map<String, dynamic> json) =>
      DauEntry(date: json['date'] as String? ?? '', count: (json['count'] as num?)?.toInt() ?? 0);
}

class RequestEntry {
  final String date;
  final int count;
  const RequestEntry({required this.date, required this.count});
  factory RequestEntry.fromJson(Map<String, dynamic> json) =>
      RequestEntry(date: json['date'] as String? ?? '', count: (json['count'] as num?)?.toInt() ?? 0);
}

class ErrorEntry {
  final String date;
  final int count;
  const ErrorEntry({required this.date, required this.count});
  factory ErrorEntry.fromJson(Map<String, dynamic> json) =>
      ErrorEntry(date: json['date'] as String? ?? '', count: (json['count'] as num?)?.toInt() ?? 0);
}

class SlowApiEntry {
  final String endpoint;
  final double avgMs;
  final int count;
  const SlowApiEntry({required this.endpoint, required this.avgMs, required this.count});
  factory SlowApiEntry.fromJson(Map<String, dynamic> json) => SlowApiEntry(
        endpoint: json['endpoint'] as String? ?? '',
        avgMs: (json['avgMs'] as num?)?.toDouble() ?? 0,
        count: (json['count'] as num?)?.toInt() ?? 0,
      );
}

// ─── Admin User ────────────────────────────────────────────────────────────

class AdminUser {
  final int memberId;
  final String email;
  final String? nickname;
  final String? profileImg;
  final String plan;
  final int projectCount;
  final DateTime createdAt;

  const AdminUser({
    required this.memberId,
    required this.email,
    this.nickname,
    this.profileImg,
    required this.plan,
    required this.projectCount,
    required this.createdAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
        memberId: (json['memberId'] as num).toInt(),
        email: json['email'] as String? ?? '',
        nickname: json['nickname'] as String?,
        profileImg: json['profileImg'] as String?,
        plan: json['plan'] as String? ?? 'free',
        projectCount: (json['projectCount'] as num?)?.toInt() ?? 0,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
      );

  String get displayName => nickname ?? email;
}

// ─── Admin Error Log ────────────────────────────────────────────────────────

class ErrorLog {
  final int errorId;
  final String level; // ERROR, WARN, INFO
  final String source;
  final String message;
  final String? stackTrace;
  final DateTime createdAt;

  const ErrorLog({
    required this.errorId,
    required this.level,
    required this.source,
    required this.message,
    this.stackTrace,
    required this.createdAt,
  });

  factory ErrorLog.fromJson(Map<String, dynamic> json) => ErrorLog(
        errorId: (json['errorId'] as num).toInt(),
        level: json['level'] as String? ?? 'ERROR',
        source: json['source'] as String? ?? '',
        message: json['message'] as String? ?? '',
        stackTrace: json['stackTrace'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
      );
}

// ─── System Status ─────────────────────────────────────────────────────────

class SystemStatus {
  final bool workerOnline;
  final bool dbOnline;
  final String? workerVersion;
  final int? queueLength;
  final Map<String, dynamic> raw;

  const SystemStatus({
    required this.workerOnline,
    required this.dbOnline,
    this.workerVersion,
    this.queueLength,
    required this.raw,
  });

  factory SystemStatus.fromJson(Map<String, dynamic> json) => SystemStatus(
        workerOnline: json['workerOnline'] as bool? ?? false,
        dbOnline: json['dbOnline'] as bool? ?? false,
        workerVersion: json['workerVersion'] as String?,
        queueLength: (json['queueLength'] as num?)?.toInt(),
        raw: json,
      );
}

// ─── Announcement ──────────────────────────────────────────────────────────

class Announcement {
  final int announceId;
  final String title;
  final String body;
  final int sentCount;
  final DateTime createdAt;

  const Announcement({
    required this.announceId,
    required this.title,
    required this.body,
    required this.sentCount,
    required this.createdAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
        announceId: (json['announceId'] as num).toInt(),
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        sentCount: (json['sentCount'] as num?)?.toInt() ?? 0,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
      );
}
