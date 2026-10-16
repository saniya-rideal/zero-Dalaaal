enum TicketCategory {
  tradingOrders('Trading & Orders'),
  fundsPayments('Funds & UPI Payments'),
  marginRisk('Margin & RMS Liquidation'),
  accountKyc('Account, Demat & KYC'),
  derivativesFno('F&O and Derivatives'),
  technicalApp('Technical & App Issues'),
  corporateActions('Dividends & Corporate Actions');

  final String label;
  const TicketCategory(this.label);
}

enum TicketPriority {
  low('Low'),
  medium('Medium'),
  high('High'),
  critical('Critical / RMS Emergency');

  final String label;
  const TicketPriority(this.label);
}

enum TicketStatus {
  open('Open'),
  inProgress('In Progress'),
  awaitingClient('Awaiting Client'),
  resolved('Resolved'),
  closed('Closed');

  final String label;
  const TicketStatus(this.label);
}

class TicketAttachment {
  final String id;
  final String fileName;
  final int fileSizeBytes;
  final String fileType; // 'image' or 'pdf'
  final DateTime uploadedAt;

  const TicketAttachment({
    required this.id,
    required this.fileName,
    required this.fileSizeBytes,
    required this.fileType,
    required this.uploadedAt,
  });

  String get formattedSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fileName': fileName,
    'fileSizeBytes': fileSizeBytes,
    'fileType': fileType,
    'uploadedAt': uploadedAt.toIso8601String(),
  };

  factory TicketAttachment.fromJson(Map<String, dynamic> json) => TicketAttachment(
    id: json['id'] as String,
    fileName: json['fileName'] as String,
    fileSizeBytes: json['fileSizeBytes'] as int,
    fileType: json['fileType'] as String,
    uploadedAt: DateTime.parse(json['uploadedAt'] as String),
  );
}

enum MessageSenderRole {
  client,
  supportAgent,
  system,
}

class TicketMessage {
  final String id;
  final String senderName;
  final MessageSenderRole senderRole;
  final String content;
  final DateTime timestamp;
  final List<TicketAttachment> attachments;

  const TicketMessage({
    required this.id,
    required this.senderName,
    required this.senderRole,
    required this.content,
    required this.timestamp,
    this.attachments = const [],
  });

  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'senderName': senderName,
    'senderRole': senderRole.name,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
    'attachments': attachments.map((a) => a.toJson()).toList(),
  };

  factory TicketMessage.fromJson(Map<String, dynamic> json) => TicketMessage(
    id: json['id'] as String,
    senderName: json['senderName'] as String,
    senderRole: MessageSenderRole.values.byName(json['senderRole'] as String),
    content: json['content'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    attachments: (json['attachments'] as List<dynamic>?)
            ?.map((e) => TicketAttachment.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
  );
}

class SupportTicket {
  final String id;
  final String title;
  final String description;
  final TicketCategory category;
  final TicketPriority priority;
  final TicketStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<TicketMessage> messages;
  final List<TicketAttachment> attachments;
  final String assignedAgent;

  const SupportTicket({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.messages = const [],
    this.attachments = const [],
    this.assignedAgent = 'Zero Desk Officer',
  });

  SupportTicket copyWith({
    String? id,
    String? title,
    String? description,
    TicketCategory? category,
    TicketPriority? priority,
    TicketStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<TicketMessage>? messages,
    List<TicketAttachment>? attachments,
    String? assignedAgent,
  }) {
    return SupportTicket(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
      attachments: attachments ?? this.attachments,
      assignedAgent: assignedAgent ?? this.assignedAgent,
    );
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'category': category.name,
    'priority': priority.name,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'messages': messages.map((m) => m.toJson()).toList(),
    'attachments': attachments.map((a) => a.toJson()).toList(),
    'assignedAgent': assignedAgent,
  };

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    final catStr = (json['category'] ?? 'tradingOrders').toString();
    final prioStr = (json['priority'] ?? 'medium').toString();
    final statStr = (json['status'] ?? 'open').toString();

    TicketCategory category = TicketCategory.tradingOrders;
    for (final c in TicketCategory.values) {
      if (c.name.toLowerCase() == catStr.toLowerCase() ||
          c.label.toLowerCase() == catStr.toLowerCase()) {
        category = c;
        break;
      }
    }

    TicketPriority priority = TicketPriority.medium;
    for (final p in TicketPriority.values) {
      if (p.name.toLowerCase() == prioStr.toLowerCase() ||
          p.label.toLowerCase() == prioStr.toLowerCase()) {
        priority = p;
        break;
      }
    }

    TicketStatus status = TicketStatus.open;
    for (final s in TicketStatus.values) {
      if (s.name.toLowerCase() == statStr.toLowerCase() ||
          s.label.toLowerCase() == statStr.toLowerCase()) {
        status = s;
        break;
      }
    }

    return SupportTicket(
      id: (json['id'] ?? json['_id'] ?? 'tk_${DateTime.now().millisecondsSinceEpoch}').toString(),
      title: (json['title'] ?? json['subject'] ?? 'Support Ticket').toString(),
      description: (json['description'] ?? json['message'] ?? '').toString(),
      category: category,
      priority: priority,
      status: status,
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? (DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      messages: (json['messages'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map((e) => TicketMessage.fromJson(e))
              .toList() ??
          const [],
      attachments: (json['attachments'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map((e) => TicketAttachment.fromJson(e))
              .toList() ??
          const [],
      assignedAgent: (json['assignedAgent'] ?? 'Zero Desk Officer').toString(),
    );
  }
}

class FaqItem {
  final String id;
  final String category;
  final String question;
  final String answer;
  final List<String> tags;
  int helpfulCount;

  FaqItem({
    required this.id,
    required this.category,
    required this.question,
    required this.answer,
    this.tags = const [],
    this.helpfulCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'question': question,
    'answer': answer,
    'tags': tags,
    'helpfulCount': helpfulCount,
  };

  factory FaqItem.fromJson(Map<String, dynamic> json) => FaqItem(
    id: json['id'] as String,
    category: json['category'] as String,
    question: json['question'] as String,
    answer: json['answer'] as String,
    tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
    helpfulCount: json['helpfulCount'] as int? ?? 0,
  );
}

class EscalationTier {
  final int level;
  final String title;
  final String officerName;
  final String designation;
  final String email;
  final String phone;
  final String tat;
  final String description;

  const EscalationTier({
    required this.level,
    required this.title,
    required this.officerName,
    required this.designation,
    required this.email,
    required this.phone,
    required this.tat,
    required this.description,
  });
}

class CorporateContact {
  final String companyName;
  final String registeredAddress;
  final String corporateOffice;
  final String sebiRegNumber;
  final String cdslDpId;
  final String nsdlDpId;
  final String nseMemberId;
  final String bseMemberId;
  final String mcxMemberId;
  final String tollFreePhone;
  final String directPhone;
  final String supportEmail;
  final String complianceEmail;
  final String hours;

  const CorporateContact({
    required this.companyName,
    required this.registeredAddress,
    required this.corporateOffice,
    required this.sebiRegNumber,
    required this.cdslDpId,
    required this.nsdlDpId,
    required this.nseMemberId,
    required this.bseMemberId,
    required this.mcxMemberId,
    required this.tollFreePhone,
    required this.directPhone,
    required this.supportEmail,
    required this.complianceEmail,
    required this.hours,
  });
}
