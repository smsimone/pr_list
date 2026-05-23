// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $PullRequestsTable extends PullRequests
    with TableInfo<$PullRequestsTable, PullRequest> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PullRequestsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _projectAliasMeta = const VerificationMeta(
    'projectAlias',
  );
  @override
  late final GeneratedColumn<String> projectAlias = GeneratedColumn<String>(
    'project_alias',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _branchMeta = const VerificationMeta('branch');
  @override
  late final GeneratedColumn<String> branch = GeneratedColumn<String>(
    'branch',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jiraTicketMeta = const VerificationMeta(
    'jiraTicket',
  );
  @override
  late final GeneratedColumn<String> jiraTicket = GeneratedColumn<String>(
    'jira_ticket',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _prLinkMeta = const VerificationMeta('prLink');
  @override
  late final GeneratedColumn<String> prLink = GeneratedColumn<String>(
    'pr_link',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _providerMeta = const VerificationMeta(
    'provider',
  );
  @override
  late final GeneratedColumn<String> provider = GeneratedColumn<String>(
    'provider',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _providerPrIdMeta = const VerificationMeta(
    'providerPrId',
  );
  @override
  late final GeneratedColumn<String> providerPrId = GeneratedColumn<String>(
    'provider_pr_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _providerStatusMeta = const VerificationMeta(
    'providerStatus',
  );
  @override
  late final GeneratedColumn<String> providerStatus = GeneratedColumn<String>(
    'provider_status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastCommitShaMeta = const VerificationMeta(
    'lastCommitSha',
  );
  @override
  late final GeneratedColumn<String> lastCommitSha = GeneratedColumn<String>(
    'last_commit_sha',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isTicketClosedMeta = const VerificationMeta(
    'isTicketClosed',
  );
  @override
  late final GeneratedColumn<bool> isTicketClosed = GeneratedColumn<bool>(
    'is_ticket_closed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_ticket_closed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isOnDevelopMeta = const VerificationMeta(
    'isOnDevelop',
  );
  @override
  late final GeneratedColumn<bool> isOnDevelop = GeneratedColumn<bool>(
    'is_on_develop',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_on_develop" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isOnUatMeta = const VerificationMeta(
    'isOnUat',
  );
  @override
  late final GeneratedColumn<bool> isOnUat = GeneratedColumn<bool>(
    'is_on_uat',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_on_uat" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isOnPreprodMeta = const VerificationMeta(
    'isOnPreprod',
  );
  @override
  late final GeneratedColumn<bool> isOnPreprod = GeneratedColumn<bool>(
    'is_on_preprod',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_on_preprod" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    projectAlias,
    branch,
    jiraTicket,
    prLink,
    provider,
    providerPrId,
    providerStatus,
    lastCommitSha,
    isTicketClosed,
    isOnDevelop,
    isOnUat,
    isOnPreprod,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pull_requests';
  @override
  VerificationContext validateIntegrity(
    Insertable<PullRequest> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('project_alias')) {
      context.handle(
        _projectAliasMeta,
        projectAlias.isAcceptableOrUnknown(
          data['project_alias']!,
          _projectAliasMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_projectAliasMeta);
    }
    if (data.containsKey('branch')) {
      context.handle(
        _branchMeta,
        branch.isAcceptableOrUnknown(data['branch']!, _branchMeta),
      );
    } else if (isInserting) {
      context.missing(_branchMeta);
    }
    if (data.containsKey('jira_ticket')) {
      context.handle(
        _jiraTicketMeta,
        jiraTicket.isAcceptableOrUnknown(data['jira_ticket']!, _jiraTicketMeta),
      );
    }
    if (data.containsKey('pr_link')) {
      context.handle(
        _prLinkMeta,
        prLink.isAcceptableOrUnknown(data['pr_link']!, _prLinkMeta),
      );
    }
    if (data.containsKey('provider')) {
      context.handle(
        _providerMeta,
        provider.isAcceptableOrUnknown(data['provider']!, _providerMeta),
      );
    }
    if (data.containsKey('provider_pr_id')) {
      context.handle(
        _providerPrIdMeta,
        providerPrId.isAcceptableOrUnknown(
          data['provider_pr_id']!,
          _providerPrIdMeta,
        ),
      );
    }
    if (data.containsKey('provider_status')) {
      context.handle(
        _providerStatusMeta,
        providerStatus.isAcceptableOrUnknown(
          data['provider_status']!,
          _providerStatusMeta,
        ),
      );
    }
    if (data.containsKey('last_commit_sha')) {
      context.handle(
        _lastCommitShaMeta,
        lastCommitSha.isAcceptableOrUnknown(
          data['last_commit_sha']!,
          _lastCommitShaMeta,
        ),
      );
    }
    if (data.containsKey('is_ticket_closed')) {
      context.handle(
        _isTicketClosedMeta,
        isTicketClosed.isAcceptableOrUnknown(
          data['is_ticket_closed']!,
          _isTicketClosedMeta,
        ),
      );
    }
    if (data.containsKey('is_on_develop')) {
      context.handle(
        _isOnDevelopMeta,
        isOnDevelop.isAcceptableOrUnknown(
          data['is_on_develop']!,
          _isOnDevelopMeta,
        ),
      );
    }
    if (data.containsKey('is_on_uat')) {
      context.handle(
        _isOnUatMeta,
        isOnUat.isAcceptableOrUnknown(data['is_on_uat']!, _isOnUatMeta),
      );
    }
    if (data.containsKey('is_on_preprod')) {
      context.handle(
        _isOnPreprodMeta,
        isOnPreprod.isAcceptableOrUnknown(
          data['is_on_preprod']!,
          _isOnPreprodMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PullRequest map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PullRequest(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      projectAlias: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_alias'],
      )!,
      branch: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}branch'],
      )!,
      jiraTicket: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}jira_ticket'],
      ),
      prLink: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pr_link'],
      ),
      provider: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider'],
      ),
      providerPrId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_pr_id'],
      ),
      providerStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_status'],
      ),
      lastCommitSha: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_commit_sha'],
      ),
      isTicketClosed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_ticket_closed'],
      )!,
      isOnDevelop: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_on_develop'],
      )!,
      isOnUat: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_on_uat'],
      )!,
      isOnPreprod: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_on_preprod'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PullRequestsTable createAlias(String alias) {
    return $PullRequestsTable(attachedDatabase, alias);
  }
}

class PullRequest extends DataClass implements Insertable<PullRequest> {
  final int id;
  final String projectAlias;
  final String branch;
  final String? jiraTicket;
  final String? prLink;
  final String? provider;
  final String? providerPrId;
  final String? providerStatus;
  final String? lastCommitSha;
  final bool isTicketClosed;
  final bool isOnDevelop;
  final bool isOnUat;
  final bool isOnPreprod;
  final DateTime createdAt;
  final DateTime updatedAt;
  const PullRequest({
    required this.id,
    required this.projectAlias,
    required this.branch,
    this.jiraTicket,
    this.prLink,
    this.provider,
    this.providerPrId,
    this.providerStatus,
    this.lastCommitSha,
    required this.isTicketClosed,
    required this.isOnDevelop,
    required this.isOnUat,
    required this.isOnPreprod,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['project_alias'] = Variable<String>(projectAlias);
    map['branch'] = Variable<String>(branch);
    if (!nullToAbsent || jiraTicket != null) {
      map['jira_ticket'] = Variable<String>(jiraTicket);
    }
    if (!nullToAbsent || prLink != null) {
      map['pr_link'] = Variable<String>(prLink);
    }
    if (!nullToAbsent || provider != null) {
      map['provider'] = Variable<String>(provider);
    }
    if (!nullToAbsent || providerPrId != null) {
      map['provider_pr_id'] = Variable<String>(providerPrId);
    }
    if (!nullToAbsent || providerStatus != null) {
      map['provider_status'] = Variable<String>(providerStatus);
    }
    if (!nullToAbsent || lastCommitSha != null) {
      map['last_commit_sha'] = Variable<String>(lastCommitSha);
    }
    map['is_ticket_closed'] = Variable<bool>(isTicketClosed);
    map['is_on_develop'] = Variable<bool>(isOnDevelop);
    map['is_on_uat'] = Variable<bool>(isOnUat);
    map['is_on_preprod'] = Variable<bool>(isOnPreprod);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PullRequestsCompanion toCompanion(bool nullToAbsent) {
    return PullRequestsCompanion(
      id: Value(id),
      projectAlias: Value(projectAlias),
      branch: Value(branch),
      jiraTicket: jiraTicket == null && nullToAbsent
          ? const Value.absent()
          : Value(jiraTicket),
      prLink: prLink == null && nullToAbsent
          ? const Value.absent()
          : Value(prLink),
      provider: provider == null && nullToAbsent
          ? const Value.absent()
          : Value(provider),
      providerPrId: providerPrId == null && nullToAbsent
          ? const Value.absent()
          : Value(providerPrId),
      providerStatus: providerStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(providerStatus),
      lastCommitSha: lastCommitSha == null && nullToAbsent
          ? const Value.absent()
          : Value(lastCommitSha),
      isTicketClosed: Value(isTicketClosed),
      isOnDevelop: Value(isOnDevelop),
      isOnUat: Value(isOnUat),
      isOnPreprod: Value(isOnPreprod),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PullRequest.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PullRequest(
      id: serializer.fromJson<int>(json['id']),
      projectAlias: serializer.fromJson<String>(json['projectAlias']),
      branch: serializer.fromJson<String>(json['branch']),
      jiraTicket: serializer.fromJson<String?>(json['jiraTicket']),
      prLink: serializer.fromJson<String?>(json['prLink']),
      provider: serializer.fromJson<String?>(json['provider']),
      providerPrId: serializer.fromJson<String?>(json['providerPrId']),
      providerStatus: serializer.fromJson<String?>(json['providerStatus']),
      lastCommitSha: serializer.fromJson<String?>(json['lastCommitSha']),
      isTicketClosed: serializer.fromJson<bool>(json['isTicketClosed']),
      isOnDevelop: serializer.fromJson<bool>(json['isOnDevelop']),
      isOnUat: serializer.fromJson<bool>(json['isOnUat']),
      isOnPreprod: serializer.fromJson<bool>(json['isOnPreprod']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'projectAlias': serializer.toJson<String>(projectAlias),
      'branch': serializer.toJson<String>(branch),
      'jiraTicket': serializer.toJson<String?>(jiraTicket),
      'prLink': serializer.toJson<String?>(prLink),
      'provider': serializer.toJson<String?>(provider),
      'providerPrId': serializer.toJson<String?>(providerPrId),
      'providerStatus': serializer.toJson<String?>(providerStatus),
      'lastCommitSha': serializer.toJson<String?>(lastCommitSha),
      'isTicketClosed': serializer.toJson<bool>(isTicketClosed),
      'isOnDevelop': serializer.toJson<bool>(isOnDevelop),
      'isOnUat': serializer.toJson<bool>(isOnUat),
      'isOnPreprod': serializer.toJson<bool>(isOnPreprod),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PullRequest copyWith({
    int? id,
    String? projectAlias,
    String? branch,
    Value<String?> jiraTicket = const Value.absent(),
    Value<String?> prLink = const Value.absent(),
    Value<String?> provider = const Value.absent(),
    Value<String?> providerPrId = const Value.absent(),
    Value<String?> providerStatus = const Value.absent(),
    Value<String?> lastCommitSha = const Value.absent(),
    bool? isTicketClosed,
    bool? isOnDevelop,
    bool? isOnUat,
    bool? isOnPreprod,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PullRequest(
    id: id ?? this.id,
    projectAlias: projectAlias ?? this.projectAlias,
    branch: branch ?? this.branch,
    jiraTicket: jiraTicket.present ? jiraTicket.value : this.jiraTicket,
    prLink: prLink.present ? prLink.value : this.prLink,
    provider: provider.present ? provider.value : this.provider,
    providerPrId: providerPrId.present ? providerPrId.value : this.providerPrId,
    providerStatus: providerStatus.present
        ? providerStatus.value
        : this.providerStatus,
    lastCommitSha: lastCommitSha.present
        ? lastCommitSha.value
        : this.lastCommitSha,
    isTicketClosed: isTicketClosed ?? this.isTicketClosed,
    isOnDevelop: isOnDevelop ?? this.isOnDevelop,
    isOnUat: isOnUat ?? this.isOnUat,
    isOnPreprod: isOnPreprod ?? this.isOnPreprod,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PullRequest copyWithCompanion(PullRequestsCompanion data) {
    return PullRequest(
      id: data.id.present ? data.id.value : this.id,
      projectAlias: data.projectAlias.present
          ? data.projectAlias.value
          : this.projectAlias,
      branch: data.branch.present ? data.branch.value : this.branch,
      jiraTicket: data.jiraTicket.present
          ? data.jiraTicket.value
          : this.jiraTicket,
      prLink: data.prLink.present ? data.prLink.value : this.prLink,
      provider: data.provider.present ? data.provider.value : this.provider,
      providerPrId: data.providerPrId.present
          ? data.providerPrId.value
          : this.providerPrId,
      providerStatus: data.providerStatus.present
          ? data.providerStatus.value
          : this.providerStatus,
      lastCommitSha: data.lastCommitSha.present
          ? data.lastCommitSha.value
          : this.lastCommitSha,
      isTicketClosed: data.isTicketClosed.present
          ? data.isTicketClosed.value
          : this.isTicketClosed,
      isOnDevelop: data.isOnDevelop.present
          ? data.isOnDevelop.value
          : this.isOnDevelop,
      isOnUat: data.isOnUat.present ? data.isOnUat.value : this.isOnUat,
      isOnPreprod: data.isOnPreprod.present
          ? data.isOnPreprod.value
          : this.isOnPreprod,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PullRequest(')
          ..write('id: $id, ')
          ..write('projectAlias: $projectAlias, ')
          ..write('branch: $branch, ')
          ..write('jiraTicket: $jiraTicket, ')
          ..write('prLink: $prLink, ')
          ..write('provider: $provider, ')
          ..write('providerPrId: $providerPrId, ')
          ..write('providerStatus: $providerStatus, ')
          ..write('lastCommitSha: $lastCommitSha, ')
          ..write('isTicketClosed: $isTicketClosed, ')
          ..write('isOnDevelop: $isOnDevelop, ')
          ..write('isOnUat: $isOnUat, ')
          ..write('isOnPreprod: $isOnPreprod, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    projectAlias,
    branch,
    jiraTicket,
    prLink,
    provider,
    providerPrId,
    providerStatus,
    lastCommitSha,
    isTicketClosed,
    isOnDevelop,
    isOnUat,
    isOnPreprod,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PullRequest &&
          other.id == this.id &&
          other.projectAlias == this.projectAlias &&
          other.branch == this.branch &&
          other.jiraTicket == this.jiraTicket &&
          other.prLink == this.prLink &&
          other.provider == this.provider &&
          other.providerPrId == this.providerPrId &&
          other.providerStatus == this.providerStatus &&
          other.lastCommitSha == this.lastCommitSha &&
          other.isTicketClosed == this.isTicketClosed &&
          other.isOnDevelop == this.isOnDevelop &&
          other.isOnUat == this.isOnUat &&
          other.isOnPreprod == this.isOnPreprod &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PullRequestsCompanion extends UpdateCompanion<PullRequest> {
  final Value<int> id;
  final Value<String> projectAlias;
  final Value<String> branch;
  final Value<String?> jiraTicket;
  final Value<String?> prLink;
  final Value<String?> provider;
  final Value<String?> providerPrId;
  final Value<String?> providerStatus;
  final Value<String?> lastCommitSha;
  final Value<bool> isTicketClosed;
  final Value<bool> isOnDevelop;
  final Value<bool> isOnUat;
  final Value<bool> isOnPreprod;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const PullRequestsCompanion({
    this.id = const Value.absent(),
    this.projectAlias = const Value.absent(),
    this.branch = const Value.absent(),
    this.jiraTicket = const Value.absent(),
    this.prLink = const Value.absent(),
    this.provider = const Value.absent(),
    this.providerPrId = const Value.absent(),
    this.providerStatus = const Value.absent(),
    this.lastCommitSha = const Value.absent(),
    this.isTicketClosed = const Value.absent(),
    this.isOnDevelop = const Value.absent(),
    this.isOnUat = const Value.absent(),
    this.isOnPreprod = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  PullRequestsCompanion.insert({
    this.id = const Value.absent(),
    required String projectAlias,
    required String branch,
    this.jiraTicket = const Value.absent(),
    this.prLink = const Value.absent(),
    this.provider = const Value.absent(),
    this.providerPrId = const Value.absent(),
    this.providerStatus = const Value.absent(),
    this.lastCommitSha = const Value.absent(),
    this.isTicketClosed = const Value.absent(),
    this.isOnDevelop = const Value.absent(),
    this.isOnUat = const Value.absent(),
    this.isOnPreprod = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : projectAlias = Value(projectAlias),
       branch = Value(branch),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<PullRequest> custom({
    Expression<int>? id,
    Expression<String>? projectAlias,
    Expression<String>? branch,
    Expression<String>? jiraTicket,
    Expression<String>? prLink,
    Expression<String>? provider,
    Expression<String>? providerPrId,
    Expression<String>? providerStatus,
    Expression<String>? lastCommitSha,
    Expression<bool>? isTicketClosed,
    Expression<bool>? isOnDevelop,
    Expression<bool>? isOnUat,
    Expression<bool>? isOnPreprod,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectAlias != null) 'project_alias': projectAlias,
      if (branch != null) 'branch': branch,
      if (jiraTicket != null) 'jira_ticket': jiraTicket,
      if (prLink != null) 'pr_link': prLink,
      if (provider != null) 'provider': provider,
      if (providerPrId != null) 'provider_pr_id': providerPrId,
      if (providerStatus != null) 'provider_status': providerStatus,
      if (lastCommitSha != null) 'last_commit_sha': lastCommitSha,
      if (isTicketClosed != null) 'is_ticket_closed': isTicketClosed,
      if (isOnDevelop != null) 'is_on_develop': isOnDevelop,
      if (isOnUat != null) 'is_on_uat': isOnUat,
      if (isOnPreprod != null) 'is_on_preprod': isOnPreprod,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  PullRequestsCompanion copyWith({
    Value<int>? id,
    Value<String>? projectAlias,
    Value<String>? branch,
    Value<String?>? jiraTicket,
    Value<String?>? prLink,
    Value<String?>? provider,
    Value<String?>? providerPrId,
    Value<String?>? providerStatus,
    Value<String?>? lastCommitSha,
    Value<bool>? isTicketClosed,
    Value<bool>? isOnDevelop,
    Value<bool>? isOnUat,
    Value<bool>? isOnPreprod,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return PullRequestsCompanion(
      id: id ?? this.id,
      projectAlias: projectAlias ?? this.projectAlias,
      branch: branch ?? this.branch,
      jiraTicket: jiraTicket ?? this.jiraTicket,
      prLink: prLink ?? this.prLink,
      provider: provider ?? this.provider,
      providerPrId: providerPrId ?? this.providerPrId,
      providerStatus: providerStatus ?? this.providerStatus,
      lastCommitSha: lastCommitSha ?? this.lastCommitSha,
      isTicketClosed: isTicketClosed ?? this.isTicketClosed,
      isOnDevelop: isOnDevelop ?? this.isOnDevelop,
      isOnUat: isOnUat ?? this.isOnUat,
      isOnPreprod: isOnPreprod ?? this.isOnPreprod,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (projectAlias.present) {
      map['project_alias'] = Variable<String>(projectAlias.value);
    }
    if (branch.present) {
      map['branch'] = Variable<String>(branch.value);
    }
    if (jiraTicket.present) {
      map['jira_ticket'] = Variable<String>(jiraTicket.value);
    }
    if (prLink.present) {
      map['pr_link'] = Variable<String>(prLink.value);
    }
    if (provider.present) {
      map['provider'] = Variable<String>(provider.value);
    }
    if (providerPrId.present) {
      map['provider_pr_id'] = Variable<String>(providerPrId.value);
    }
    if (providerStatus.present) {
      map['provider_status'] = Variable<String>(providerStatus.value);
    }
    if (lastCommitSha.present) {
      map['last_commit_sha'] = Variable<String>(lastCommitSha.value);
    }
    if (isTicketClosed.present) {
      map['is_ticket_closed'] = Variable<bool>(isTicketClosed.value);
    }
    if (isOnDevelop.present) {
      map['is_on_develop'] = Variable<bool>(isOnDevelop.value);
    }
    if (isOnUat.present) {
      map['is_on_uat'] = Variable<bool>(isOnUat.value);
    }
    if (isOnPreprod.present) {
      map['is_on_preprod'] = Variable<bool>(isOnPreprod.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PullRequestsCompanion(')
          ..write('id: $id, ')
          ..write('projectAlias: $projectAlias, ')
          ..write('branch: $branch, ')
          ..write('jiraTicket: $jiraTicket, ')
          ..write('prLink: $prLink, ')
          ..write('provider: $provider, ')
          ..write('providerPrId: $providerPrId, ')
          ..write('providerStatus: $providerStatus, ')
          ..write('lastCommitSha: $lastCommitSha, ')
          ..write('isTicketClosed: $isTicketClosed, ')
          ..write('isOnDevelop: $isOnDevelop, ')
          ..write('isOnUat: $isOnUat, ')
          ..write('isOnPreprod: $isOnPreprod, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $SchemaMigrationsTable extends SchemaMigrations
    with TableInfo<$SchemaMigrationsTable, SchemaMigration> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SchemaMigrationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _checksumMeta = const VerificationMeta(
    'checksum',
  );
  @override
  late final GeneratedColumn<String> checksum = GeneratedColumn<String>(
    'checksum',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _appliedAtMeta = const VerificationMeta(
    'appliedAt',
  );
  @override
  late final GeneratedColumn<DateTime> appliedAt = GeneratedColumn<DateTime>(
    'applied_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, version, checksum, appliedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'schema_migrations';
  @override
  VerificationContext validateIntegrity(
    Insertable<SchemaMigration> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('checksum')) {
      context.handle(
        _checksumMeta,
        checksum.isAcceptableOrUnknown(data['checksum']!, _checksumMeta),
      );
    } else if (isInserting) {
      context.missing(_checksumMeta);
    }
    if (data.containsKey('applied_at')) {
      context.handle(
        _appliedAtMeta,
        appliedAt.isAcceptableOrUnknown(data['applied_at']!, _appliedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_appliedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SchemaMigration map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SchemaMigration(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      checksum: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}checksum'],
      )!,
      appliedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}applied_at'],
      )!,
    );
  }

  @override
  $SchemaMigrationsTable createAlias(String alias) {
    return $SchemaMigrationsTable(attachedDatabase, alias);
  }
}

class SchemaMigration extends DataClass implements Insertable<SchemaMigration> {
  final int id;
  final int version;
  final String checksum;
  final DateTime appliedAt;
  const SchemaMigration({
    required this.id,
    required this.version,
    required this.checksum,
    required this.appliedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['version'] = Variable<int>(version);
    map['checksum'] = Variable<String>(checksum);
    map['applied_at'] = Variable<DateTime>(appliedAt);
    return map;
  }

  SchemaMigrationsCompanion toCompanion(bool nullToAbsent) {
    return SchemaMigrationsCompanion(
      id: Value(id),
      version: Value(version),
      checksum: Value(checksum),
      appliedAt: Value(appliedAt),
    );
  }

  factory SchemaMigration.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SchemaMigration(
      id: serializer.fromJson<int>(json['id']),
      version: serializer.fromJson<int>(json['version']),
      checksum: serializer.fromJson<String>(json['checksum']),
      appliedAt: serializer.fromJson<DateTime>(json['appliedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'version': serializer.toJson<int>(version),
      'checksum': serializer.toJson<String>(checksum),
      'appliedAt': serializer.toJson<DateTime>(appliedAt),
    };
  }

  SchemaMigration copyWith({
    int? id,
    int? version,
    String? checksum,
    DateTime? appliedAt,
  }) => SchemaMigration(
    id: id ?? this.id,
    version: version ?? this.version,
    checksum: checksum ?? this.checksum,
    appliedAt: appliedAt ?? this.appliedAt,
  );
  SchemaMigration copyWithCompanion(SchemaMigrationsCompanion data) {
    return SchemaMigration(
      id: data.id.present ? data.id.value : this.id,
      version: data.version.present ? data.version.value : this.version,
      checksum: data.checksum.present ? data.checksum.value : this.checksum,
      appliedAt: data.appliedAt.present ? data.appliedAt.value : this.appliedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SchemaMigration(')
          ..write('id: $id, ')
          ..write('version: $version, ')
          ..write('checksum: $checksum, ')
          ..write('appliedAt: $appliedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, version, checksum, appliedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SchemaMigration &&
          other.id == this.id &&
          other.version == this.version &&
          other.checksum == this.checksum &&
          other.appliedAt == this.appliedAt);
}

class SchemaMigrationsCompanion extends UpdateCompanion<SchemaMigration> {
  final Value<int> id;
  final Value<int> version;
  final Value<String> checksum;
  final Value<DateTime> appliedAt;
  const SchemaMigrationsCompanion({
    this.id = const Value.absent(),
    this.version = const Value.absent(),
    this.checksum = const Value.absent(),
    this.appliedAt = const Value.absent(),
  });
  SchemaMigrationsCompanion.insert({
    this.id = const Value.absent(),
    required int version,
    required String checksum,
    required DateTime appliedAt,
  }) : version = Value(version),
       checksum = Value(checksum),
       appliedAt = Value(appliedAt);
  static Insertable<SchemaMigration> custom({
    Expression<int>? id,
    Expression<int>? version,
    Expression<String>? checksum,
    Expression<DateTime>? appliedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (version != null) 'version': version,
      if (checksum != null) 'checksum': checksum,
      if (appliedAt != null) 'applied_at': appliedAt,
    });
  }

  SchemaMigrationsCompanion copyWith({
    Value<int>? id,
    Value<int>? version,
    Value<String>? checksum,
    Value<DateTime>? appliedAt,
  }) {
    return SchemaMigrationsCompanion(
      id: id ?? this.id,
      version: version ?? this.version,
      checksum: checksum ?? this.checksum,
      appliedAt: appliedAt ?? this.appliedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (checksum.present) {
      map['checksum'] = Variable<String>(checksum.value);
    }
    if (appliedAt.present) {
      map['applied_at'] = Variable<DateTime>(appliedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SchemaMigrationsCompanion(')
          ..write('id: $id, ')
          ..write('version: $version, ')
          ..write('checksum: $checksum, ')
          ..write('appliedAt: $appliedAt')
          ..write(')'))
        .toString();
  }
}

class $ProjectsTable extends Projects with TableInfo<$ProjectsTable, Project> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _aliasMeta = const VerificationMeta('alias');
  @override
  late final GeneratedColumn<String> alias = GeneratedColumn<String>(
    'alias',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    alias,
    path,
    color,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'projects';
  @override
  VerificationContext validateIntegrity(
    Insertable<Project> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('alias')) {
      context.handle(
        _aliasMeta,
        alias.isAcceptableOrUnknown(data['alias']!, _aliasMeta),
      );
    } else if (isInserting) {
      context.missing(_aliasMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {alias},
  ];
  @override
  Project map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Project(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      alias: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alias'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ProjectsTable createAlias(String alias) {
    return $ProjectsTable(attachedDatabase, alias);
  }
}

class Project extends DataClass implements Insertable<Project> {
  final int id;
  final String alias;
  final String path;
  final int? color;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Project({
    required this.id,
    required this.alias,
    required this.path,
    this.color,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['alias'] = Variable<String>(alias);
    map['path'] = Variable<String>(path);
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<int>(color);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ProjectsCompanion toCompanion(bool nullToAbsent) {
    return ProjectsCompanion(
      id: Value(id),
      alias: Value(alias),
      path: Value(path),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Project.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Project(
      id: serializer.fromJson<int>(json['id']),
      alias: serializer.fromJson<String>(json['alias']),
      path: serializer.fromJson<String>(json['path']),
      color: serializer.fromJson<int?>(json['color']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'alias': serializer.toJson<String>(alias),
      'path': serializer.toJson<String>(path),
      'color': serializer.toJson<int?>(color),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Project copyWith({
    int? id,
    String? alias,
    String? path,
    Value<int?> color = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Project(
    id: id ?? this.id,
    alias: alias ?? this.alias,
    path: path ?? this.path,
    color: color.present ? color.value : this.color,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Project copyWithCompanion(ProjectsCompanion data) {
    return Project(
      id: data.id.present ? data.id.value : this.id,
      alias: data.alias.present ? data.alias.value : this.alias,
      path: data.path.present ? data.path.value : this.path,
      color: data.color.present ? data.color.value : this.color,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Project(')
          ..write('id: $id, ')
          ..write('alias: $alias, ')
          ..write('path: $path, ')
          ..write('color: $color, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, alias, path, color, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Project &&
          other.id == this.id &&
          other.alias == this.alias &&
          other.path == this.path &&
          other.color == this.color &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ProjectsCompanion extends UpdateCompanion<Project> {
  final Value<int> id;
  final Value<String> alias;
  final Value<String> path;
  final Value<int?> color;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const ProjectsCompanion({
    this.id = const Value.absent(),
    this.alias = const Value.absent(),
    this.path = const Value.absent(),
    this.color = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ProjectsCompanion.insert({
    this.id = const Value.absent(),
    required String alias,
    required String path,
    this.color = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : alias = Value(alias),
       path = Value(path),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Project> custom({
    Expression<int>? id,
    Expression<String>? alias,
    Expression<String>? path,
    Expression<int>? color,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (alias != null) 'alias': alias,
      if (path != null) 'path': path,
      if (color != null) 'color': color,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ProjectsCompanion copyWith({
    Value<int>? id,
    Value<String>? alias,
    Value<String>? path,
    Value<int?>? color,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return ProjectsCompanion(
      id: id ?? this.id,
      alias: alias ?? this.alias,
      path: path ?? this.path,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (alias.present) {
      map['alias'] = Variable<String>(alias.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProjectsCompanion(')
          ..write('id: $id, ')
          ..write('alias: $alias, ')
          ..write('path: $path, ')
          ..write('color: $color, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $EnvironmentMappingsTable extends EnvironmentMappings
    with TableInfo<$EnvironmentMappingsTable, EnvironmentMapping> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EnvironmentMappingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _environmentNameMeta = const VerificationMeta(
    'environmentName',
  );
  @override
  late final GeneratedColumn<String> environmentName = GeneratedColumn<String>(
    'environment_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _branchPatternMeta = const VerificationMeta(
    'branchPattern',
  );
  @override
  late final GeneratedColumn<String> branchPattern = GeneratedColumn<String>(
    'branch_pattern',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sortOrder,
    environmentName,
    branchPattern,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'environment_mappings';
  @override
  VerificationContext validateIntegrity(
    Insertable<EnvironmentMapping> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('environment_name')) {
      context.handle(
        _environmentNameMeta,
        environmentName.isAcceptableOrUnknown(
          data['environment_name']!,
          _environmentNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_environmentNameMeta);
    }
    if (data.containsKey('branch_pattern')) {
      context.handle(
        _branchPatternMeta,
        branchPattern.isAcceptableOrUnknown(
          data['branch_pattern']!,
          _branchPatternMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_branchPatternMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EnvironmentMapping map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EnvironmentMapping(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      environmentName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}environment_name'],
      )!,
      branchPattern: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}branch_pattern'],
      )!,
    );
  }

  @override
  $EnvironmentMappingsTable createAlias(String alias) {
    return $EnvironmentMappingsTable(attachedDatabase, alias);
  }
}

class EnvironmentMapping extends DataClass
    implements Insertable<EnvironmentMapping> {
  final int id;
  final int sortOrder;
  final String environmentName;
  final String branchPattern;
  const EnvironmentMapping({
    required this.id,
    required this.sortOrder,
    required this.environmentName,
    required this.branchPattern,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['sort_order'] = Variable<int>(sortOrder);
    map['environment_name'] = Variable<String>(environmentName);
    map['branch_pattern'] = Variable<String>(branchPattern);
    return map;
  }

  EnvironmentMappingsCompanion toCompanion(bool nullToAbsent) {
    return EnvironmentMappingsCompanion(
      id: Value(id),
      sortOrder: Value(sortOrder),
      environmentName: Value(environmentName),
      branchPattern: Value(branchPattern),
    );
  }

  factory EnvironmentMapping.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EnvironmentMapping(
      id: serializer.fromJson<int>(json['id']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      environmentName: serializer.fromJson<String>(json['environmentName']),
      branchPattern: serializer.fromJson<String>(json['branchPattern']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'environmentName': serializer.toJson<String>(environmentName),
      'branchPattern': serializer.toJson<String>(branchPattern),
    };
  }

  EnvironmentMapping copyWith({
    int? id,
    int? sortOrder,
    String? environmentName,
    String? branchPattern,
  }) => EnvironmentMapping(
    id: id ?? this.id,
    sortOrder: sortOrder ?? this.sortOrder,
    environmentName: environmentName ?? this.environmentName,
    branchPattern: branchPattern ?? this.branchPattern,
  );
  EnvironmentMapping copyWithCompanion(EnvironmentMappingsCompanion data) {
    return EnvironmentMapping(
      id: data.id.present ? data.id.value : this.id,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      environmentName: data.environmentName.present
          ? data.environmentName.value
          : this.environmentName,
      branchPattern: data.branchPattern.present
          ? data.branchPattern.value
          : this.branchPattern,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EnvironmentMapping(')
          ..write('id: $id, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('environmentName: $environmentName, ')
          ..write('branchPattern: $branchPattern')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, sortOrder, environmentName, branchPattern);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EnvironmentMapping &&
          other.id == this.id &&
          other.sortOrder == this.sortOrder &&
          other.environmentName == this.environmentName &&
          other.branchPattern == this.branchPattern);
}

class EnvironmentMappingsCompanion extends UpdateCompanion<EnvironmentMapping> {
  final Value<int> id;
  final Value<int> sortOrder;
  final Value<String> environmentName;
  final Value<String> branchPattern;
  const EnvironmentMappingsCompanion({
    this.id = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.environmentName = const Value.absent(),
    this.branchPattern = const Value.absent(),
  });
  EnvironmentMappingsCompanion.insert({
    this.id = const Value.absent(),
    required int sortOrder,
    required String environmentName,
    required String branchPattern,
  }) : sortOrder = Value(sortOrder),
       environmentName = Value(environmentName),
       branchPattern = Value(branchPattern);
  static Insertable<EnvironmentMapping> custom({
    Expression<int>? id,
    Expression<int>? sortOrder,
    Expression<String>? environmentName,
    Expression<String>? branchPattern,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (environmentName != null) 'environment_name': environmentName,
      if (branchPattern != null) 'branch_pattern': branchPattern,
    });
  }

  EnvironmentMappingsCompanion copyWith({
    Value<int>? id,
    Value<int>? sortOrder,
    Value<String>? environmentName,
    Value<String>? branchPattern,
  }) {
    return EnvironmentMappingsCompanion(
      id: id ?? this.id,
      sortOrder: sortOrder ?? this.sortOrder,
      environmentName: environmentName ?? this.environmentName,
      branchPattern: branchPattern ?? this.branchPattern,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (environmentName.present) {
      map['environment_name'] = Variable<String>(environmentName.value);
    }
    if (branchPattern.present) {
      map['branch_pattern'] = Variable<String>(branchPattern.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EnvironmentMappingsCompanion(')
          ..write('id: $id, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('environmentName: $environmentName, ')
          ..write('branchPattern: $branchPattern')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PullRequestsTable pullRequests = $PullRequestsTable(this);
  late final $SchemaMigrationsTable schemaMigrations = $SchemaMigrationsTable(
    this,
  );
  late final $ProjectsTable projects = $ProjectsTable(this);
  late final $EnvironmentMappingsTable environmentMappings =
      $EnvironmentMappingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    pullRequests,
    schemaMigrations,
    projects,
    environmentMappings,
  ];
}

typedef $$PullRequestsTableCreateCompanionBuilder =
    PullRequestsCompanion Function({
      Value<int> id,
      required String projectAlias,
      required String branch,
      Value<String?> jiraTicket,
      Value<String?> prLink,
      Value<String?> provider,
      Value<String?> providerPrId,
      Value<String?> providerStatus,
      Value<String?> lastCommitSha,
      Value<bool> isTicketClosed,
      Value<bool> isOnDevelop,
      Value<bool> isOnUat,
      Value<bool> isOnPreprod,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$PullRequestsTableUpdateCompanionBuilder =
    PullRequestsCompanion Function({
      Value<int> id,
      Value<String> projectAlias,
      Value<String> branch,
      Value<String?> jiraTicket,
      Value<String?> prLink,
      Value<String?> provider,
      Value<String?> providerPrId,
      Value<String?> providerStatus,
      Value<String?> lastCommitSha,
      Value<bool> isTicketClosed,
      Value<bool> isOnDevelop,
      Value<bool> isOnUat,
      Value<bool> isOnPreprod,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$PullRequestsTableFilterComposer
    extends Composer<_$AppDatabase, $PullRequestsTable> {
  $$PullRequestsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectAlias => $composableBuilder(
    column: $table.projectAlias,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get branch => $composableBuilder(
    column: $table.branch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jiraTicket => $composableBuilder(
    column: $table.jiraTicket,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get prLink => $composableBuilder(
    column: $table.prLink,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get providerPrId => $composableBuilder(
    column: $table.providerPrId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get providerStatus => $composableBuilder(
    column: $table.providerStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastCommitSha => $composableBuilder(
    column: $table.lastCommitSha,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isTicketClosed => $composableBuilder(
    column: $table.isTicketClosed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isOnDevelop => $composableBuilder(
    column: $table.isOnDevelop,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isOnUat => $composableBuilder(
    column: $table.isOnUat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isOnPreprod => $composableBuilder(
    column: $table.isOnPreprod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PullRequestsTableOrderingComposer
    extends Composer<_$AppDatabase, $PullRequestsTable> {
  $$PullRequestsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectAlias => $composableBuilder(
    column: $table.projectAlias,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get branch => $composableBuilder(
    column: $table.branch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jiraTicket => $composableBuilder(
    column: $table.jiraTicket,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get prLink => $composableBuilder(
    column: $table.prLink,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get providerPrId => $composableBuilder(
    column: $table.providerPrId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get providerStatus => $composableBuilder(
    column: $table.providerStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastCommitSha => $composableBuilder(
    column: $table.lastCommitSha,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isTicketClosed => $composableBuilder(
    column: $table.isTicketClosed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isOnDevelop => $composableBuilder(
    column: $table.isOnDevelop,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isOnUat => $composableBuilder(
    column: $table.isOnUat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isOnPreprod => $composableBuilder(
    column: $table.isOnPreprod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PullRequestsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PullRequestsTable> {
  $$PullRequestsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get projectAlias => $composableBuilder(
    column: $table.projectAlias,
    builder: (column) => column,
  );

  GeneratedColumn<String> get branch =>
      $composableBuilder(column: $table.branch, builder: (column) => column);

  GeneratedColumn<String> get jiraTicket => $composableBuilder(
    column: $table.jiraTicket,
    builder: (column) => column,
  );

  GeneratedColumn<String> get prLink =>
      $composableBuilder(column: $table.prLink, builder: (column) => column);

  GeneratedColumn<String> get provider =>
      $composableBuilder(column: $table.provider, builder: (column) => column);

  GeneratedColumn<String> get providerPrId => $composableBuilder(
    column: $table.providerPrId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get providerStatus => $composableBuilder(
    column: $table.providerStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastCommitSha => $composableBuilder(
    column: $table.lastCommitSha,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isTicketClosed => $composableBuilder(
    column: $table.isTicketClosed,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isOnDevelop => $composableBuilder(
    column: $table.isOnDevelop,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isOnUat =>
      $composableBuilder(column: $table.isOnUat, builder: (column) => column);

  GeneratedColumn<bool> get isOnPreprod => $composableBuilder(
    column: $table.isOnPreprod,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PullRequestsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PullRequestsTable,
          PullRequest,
          $$PullRequestsTableFilterComposer,
          $$PullRequestsTableOrderingComposer,
          $$PullRequestsTableAnnotationComposer,
          $$PullRequestsTableCreateCompanionBuilder,
          $$PullRequestsTableUpdateCompanionBuilder,
          (
            PullRequest,
            BaseReferences<_$AppDatabase, $PullRequestsTable, PullRequest>,
          ),
          PullRequest,
          PrefetchHooks Function()
        > {
  $$PullRequestsTableTableManager(_$AppDatabase db, $PullRequestsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PullRequestsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PullRequestsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PullRequestsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> projectAlias = const Value.absent(),
                Value<String> branch = const Value.absent(),
                Value<String?> jiraTicket = const Value.absent(),
                Value<String?> prLink = const Value.absent(),
                Value<String?> provider = const Value.absent(),
                Value<String?> providerPrId = const Value.absent(),
                Value<String?> providerStatus = const Value.absent(),
                Value<String?> lastCommitSha = const Value.absent(),
                Value<bool> isTicketClosed = const Value.absent(),
                Value<bool> isOnDevelop = const Value.absent(),
                Value<bool> isOnUat = const Value.absent(),
                Value<bool> isOnPreprod = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => PullRequestsCompanion(
                id: id,
                projectAlias: projectAlias,
                branch: branch,
                jiraTicket: jiraTicket,
                prLink: prLink,
                provider: provider,
                providerPrId: providerPrId,
                providerStatus: providerStatus,
                lastCommitSha: lastCommitSha,
                isTicketClosed: isTicketClosed,
                isOnDevelop: isOnDevelop,
                isOnUat: isOnUat,
                isOnPreprod: isOnPreprod,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String projectAlias,
                required String branch,
                Value<String?> jiraTicket = const Value.absent(),
                Value<String?> prLink = const Value.absent(),
                Value<String?> provider = const Value.absent(),
                Value<String?> providerPrId = const Value.absent(),
                Value<String?> providerStatus = const Value.absent(),
                Value<String?> lastCommitSha = const Value.absent(),
                Value<bool> isTicketClosed = const Value.absent(),
                Value<bool> isOnDevelop = const Value.absent(),
                Value<bool> isOnUat = const Value.absent(),
                Value<bool> isOnPreprod = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => PullRequestsCompanion.insert(
                id: id,
                projectAlias: projectAlias,
                branch: branch,
                jiraTicket: jiraTicket,
                prLink: prLink,
                provider: provider,
                providerPrId: providerPrId,
                providerStatus: providerStatus,
                lastCommitSha: lastCommitSha,
                isTicketClosed: isTicketClosed,
                isOnDevelop: isOnDevelop,
                isOnUat: isOnUat,
                isOnPreprod: isOnPreprod,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PullRequestsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PullRequestsTable,
      PullRequest,
      $$PullRequestsTableFilterComposer,
      $$PullRequestsTableOrderingComposer,
      $$PullRequestsTableAnnotationComposer,
      $$PullRequestsTableCreateCompanionBuilder,
      $$PullRequestsTableUpdateCompanionBuilder,
      (
        PullRequest,
        BaseReferences<_$AppDatabase, $PullRequestsTable, PullRequest>,
      ),
      PullRequest,
      PrefetchHooks Function()
    >;
typedef $$SchemaMigrationsTableCreateCompanionBuilder =
    SchemaMigrationsCompanion Function({
      Value<int> id,
      required int version,
      required String checksum,
      required DateTime appliedAt,
    });
typedef $$SchemaMigrationsTableUpdateCompanionBuilder =
    SchemaMigrationsCompanion Function({
      Value<int> id,
      Value<int> version,
      Value<String> checksum,
      Value<DateTime> appliedAt,
    });

class $$SchemaMigrationsTableFilterComposer
    extends Composer<_$AppDatabase, $SchemaMigrationsTable> {
  $$SchemaMigrationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get checksum => $composableBuilder(
    column: $table.checksum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get appliedAt => $composableBuilder(
    column: $table.appliedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SchemaMigrationsTableOrderingComposer
    extends Composer<_$AppDatabase, $SchemaMigrationsTable> {
  $$SchemaMigrationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get checksum => $composableBuilder(
    column: $table.checksum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get appliedAt => $composableBuilder(
    column: $table.appliedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SchemaMigrationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SchemaMigrationsTable> {
  $$SchemaMigrationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get checksum =>
      $composableBuilder(column: $table.checksum, builder: (column) => column);

  GeneratedColumn<DateTime> get appliedAt =>
      $composableBuilder(column: $table.appliedAt, builder: (column) => column);
}

class $$SchemaMigrationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SchemaMigrationsTable,
          SchemaMigration,
          $$SchemaMigrationsTableFilterComposer,
          $$SchemaMigrationsTableOrderingComposer,
          $$SchemaMigrationsTableAnnotationComposer,
          $$SchemaMigrationsTableCreateCompanionBuilder,
          $$SchemaMigrationsTableUpdateCompanionBuilder,
          (
            SchemaMigration,
            BaseReferences<
              _$AppDatabase,
              $SchemaMigrationsTable,
              SchemaMigration
            >,
          ),
          SchemaMigration,
          PrefetchHooks Function()
        > {
  $$SchemaMigrationsTableTableManager(
    _$AppDatabase db,
    $SchemaMigrationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SchemaMigrationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SchemaMigrationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SchemaMigrationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String> checksum = const Value.absent(),
                Value<DateTime> appliedAt = const Value.absent(),
              }) => SchemaMigrationsCompanion(
                id: id,
                version: version,
                checksum: checksum,
                appliedAt: appliedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int version,
                required String checksum,
                required DateTime appliedAt,
              }) => SchemaMigrationsCompanion.insert(
                id: id,
                version: version,
                checksum: checksum,
                appliedAt: appliedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SchemaMigrationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SchemaMigrationsTable,
      SchemaMigration,
      $$SchemaMigrationsTableFilterComposer,
      $$SchemaMigrationsTableOrderingComposer,
      $$SchemaMigrationsTableAnnotationComposer,
      $$SchemaMigrationsTableCreateCompanionBuilder,
      $$SchemaMigrationsTableUpdateCompanionBuilder,
      (
        SchemaMigration,
        BaseReferences<_$AppDatabase, $SchemaMigrationsTable, SchemaMigration>,
      ),
      SchemaMigration,
      PrefetchHooks Function()
    >;
typedef $$ProjectsTableCreateCompanionBuilder =
    ProjectsCompanion Function({
      Value<int> id,
      required String alias,
      required String path,
      Value<int?> color,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$ProjectsTableUpdateCompanionBuilder =
    ProjectsCompanion Function({
      Value<int> id,
      Value<String> alias,
      Value<String> path,
      Value<int?> color,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$ProjectsTableFilterComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get alias => $composableBuilder(
    column: $table.alias,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProjectsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get alias => $composableBuilder(
    column: $table.alias,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProjectsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get alias =>
      $composableBuilder(column: $table.alias, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ProjectsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProjectsTable,
          Project,
          $$ProjectsTableFilterComposer,
          $$ProjectsTableOrderingComposer,
          $$ProjectsTableAnnotationComposer,
          $$ProjectsTableCreateCompanionBuilder,
          $$ProjectsTableUpdateCompanionBuilder,
          (Project, BaseReferences<_$AppDatabase, $ProjectsTable, Project>),
          Project,
          PrefetchHooks Function()
        > {
  $$ProjectsTableTableManager(_$AppDatabase db, $ProjectsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProjectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProjectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProjectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> alias = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<int?> color = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ProjectsCompanion(
                id: id,
                alias: alias,
                path: path,
                color: color,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String alias,
                required String path,
                Value<int?> color = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => ProjectsCompanion.insert(
                id: id,
                alias: alias,
                path: path,
                color: color,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProjectsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProjectsTable,
      Project,
      $$ProjectsTableFilterComposer,
      $$ProjectsTableOrderingComposer,
      $$ProjectsTableAnnotationComposer,
      $$ProjectsTableCreateCompanionBuilder,
      $$ProjectsTableUpdateCompanionBuilder,
      (Project, BaseReferences<_$AppDatabase, $ProjectsTable, Project>),
      Project,
      PrefetchHooks Function()
    >;
typedef $$EnvironmentMappingsTableCreateCompanionBuilder =
    EnvironmentMappingsCompanion Function({
      Value<int> id,
      required int sortOrder,
      required String environmentName,
      required String branchPattern,
    });
typedef $$EnvironmentMappingsTableUpdateCompanionBuilder =
    EnvironmentMappingsCompanion Function({
      Value<int> id,
      Value<int> sortOrder,
      Value<String> environmentName,
      Value<String> branchPattern,
    });

class $$EnvironmentMappingsTableFilterComposer
    extends Composer<_$AppDatabase, $EnvironmentMappingsTable> {
  $$EnvironmentMappingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get environmentName => $composableBuilder(
    column: $table.environmentName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get branchPattern => $composableBuilder(
    column: $table.branchPattern,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EnvironmentMappingsTableOrderingComposer
    extends Composer<_$AppDatabase, $EnvironmentMappingsTable> {
  $$EnvironmentMappingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get environmentName => $composableBuilder(
    column: $table.environmentName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get branchPattern => $composableBuilder(
    column: $table.branchPattern,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EnvironmentMappingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EnvironmentMappingsTable> {
  $$EnvironmentMappingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get environmentName => $composableBuilder(
    column: $table.environmentName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get branchPattern => $composableBuilder(
    column: $table.branchPattern,
    builder: (column) => column,
  );
}

class $$EnvironmentMappingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EnvironmentMappingsTable,
          EnvironmentMapping,
          $$EnvironmentMappingsTableFilterComposer,
          $$EnvironmentMappingsTableOrderingComposer,
          $$EnvironmentMappingsTableAnnotationComposer,
          $$EnvironmentMappingsTableCreateCompanionBuilder,
          $$EnvironmentMappingsTableUpdateCompanionBuilder,
          (
            EnvironmentMapping,
            BaseReferences<
              _$AppDatabase,
              $EnvironmentMappingsTable,
              EnvironmentMapping
            >,
          ),
          EnvironmentMapping,
          PrefetchHooks Function()
        > {
  $$EnvironmentMappingsTableTableManager(
    _$AppDatabase db,
    $EnvironmentMappingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EnvironmentMappingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EnvironmentMappingsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$EnvironmentMappingsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String> environmentName = const Value.absent(),
                Value<String> branchPattern = const Value.absent(),
              }) => EnvironmentMappingsCompanion(
                id: id,
                sortOrder: sortOrder,
                environmentName: environmentName,
                branchPattern: branchPattern,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int sortOrder,
                required String environmentName,
                required String branchPattern,
              }) => EnvironmentMappingsCompanion.insert(
                id: id,
                sortOrder: sortOrder,
                environmentName: environmentName,
                branchPattern: branchPattern,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EnvironmentMappingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EnvironmentMappingsTable,
      EnvironmentMapping,
      $$EnvironmentMappingsTableFilterComposer,
      $$EnvironmentMappingsTableOrderingComposer,
      $$EnvironmentMappingsTableAnnotationComposer,
      $$EnvironmentMappingsTableCreateCompanionBuilder,
      $$EnvironmentMappingsTableUpdateCompanionBuilder,
      (
        EnvironmentMapping,
        BaseReferences<
          _$AppDatabase,
          $EnvironmentMappingsTable,
          EnvironmentMapping
        >,
      ),
      EnvironmentMapping,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PullRequestsTableTableManager get pullRequests =>
      $$PullRequestsTableTableManager(_db, _db.pullRequests);
  $$SchemaMigrationsTableTableManager get schemaMigrations =>
      $$SchemaMigrationsTableTableManager(_db, _db.schemaMigrations);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db, _db.projects);
  $$EnvironmentMappingsTableTableManager get environmentMappings =>
      $$EnvironmentMappingsTableTableManager(_db, _db.environmentMappings);
}
