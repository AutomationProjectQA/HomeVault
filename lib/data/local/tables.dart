import 'package:drift/drift.dart';

/// Schema v1 — mirrors docs/03-architecture.md ERD.
///
/// Conventions shared by every synced table:
///  - `id` is a client-generated UUID (offline-first: no server round-trip)
///  - soft delete via `deletedAt` (sync-safe; hard deletes break replication)
///  - `updatedAt` drives last-write-wins conflict resolution

mixin SyncColumns on Table {
  TextColumn get id => text()();
  TextColumn get homeId => text()();
  TextColumn get createdBy => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Homes extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get address => text().nullable()();
  TextColumn get photoPath => text().nullable()();
  TextColumn get ownerId => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Members extends Table {
  TextColumn get id => text()();
  TextColumn get homeId => text()();
  TextColumn get userId => text()();
  TextColumn get displayName => text()();
  TextColumn get role => text().withDefault(const Constant('member'))(); // owner | member
  DateTimeColumn get joinedAt => dateTime()();
  DateTimeColumn get removedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Assets extends Table with SyncColumns {
  TextColumn get name => text()();
  TextColumn get category => text().withDefault(const Constant('other'))();
  TextColumn get brand => text().nullable()();
  TextColumn get model => text().nullable()();
  TextColumn get serialNumber => text().nullable()();
  DateTimeColumn get purchaseDate => dateTime().nullable()();
  RealColumn get purchasePrice => real().nullable()();
  TextColumn get vendor => text().nullable()();
  DateTimeColumn get warrantyEndDate => dateTime().nullable()();
  TextColumn get roomId => text().nullable()(); // Rooms module lands Phase 2
  TextColumn get notes => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))(); // active | sold | disposed
}

class Bills extends Table with SyncColumns {
  TextColumn get type => text()(); // electricity | water | gas | internet | ...
  TextColumn get provider => text().nullable()();
  RealColumn get amount => real().nullable()();
  DateTimeColumn get dueDate => dateTime()();
  TextColumn get status => text().withDefault(const Constant('upcoming'))(); // upcoming | paid | overdue
  DateTimeColumn get paidDate => dateTime().nullable()();
  TextColumn get paymentMethod => text().nullable()();
  TextColumn get recurrenceRule => text().nullable()(); // RRULE string
  TextColumn get notes => text().nullable()();
}

/// Append-only asset timeline: purchase, service, repair, disposal.
class Events extends Table with SyncColumns {
  TextColumn get assetId => text().nullable()(); // nullable: standalone services (e.g. tank cleaning)
  TextColumn get type => text()(); // purchase | service | repair | note
  TextColumn get title => text()();
  DateTimeColumn get occurredAt => dateTime()();
  RealColumn get cost => real().nullable()();
  TextColumn get providerName => text().nullable()();
  TextColumn get providerPhone => text().nullable()();
  TextColumn get notes => text().nullable()();
}

/// Polymorphic attachments + Phase-2 standalone document vault.
class Documents extends Table with SyncColumns {
  TextColumn get title => text()();
  TextColumn get category => text().nullable()(); // invoice | warranty | manual | property | ...
  TextColumn get sourceType => text().nullable()(); // asset | bill | event | null (standalone)
  TextColumn get sourceId => text().nullable()();
  TextColumn get localPath => text().nullable()();
  TextColumn get remotePath => text().nullable()();
  TextColumn get mimeType => text().nullable()();
  DateTimeColumn get expiryDate => dateTime().nullable()();
}

/// The Reminder Engine's storage — see docs/04-reminder-engine.md.
class Reminders extends Table with SyncColumns {
  TextColumn get sourceType => text()(); // asset | bill | document | event | manual
  TextColumn get sourceId => text().nullable()();
  TextColumn get title => text()();
  TextColumn get priority => text()(); // critical | medium | low
  DateTimeColumn get dueAt => dateTime()();
  TextColumn get assignedTo => text().nullable()(); // null = whole home
  TextColumn get recurrenceRule => text().nullable()();
  TextColumn get state => text().withDefault(const Constant('scheduled'))(); // scheduled | active | snoozed | overdue | completed | cancelled
  DateTimeColumn get snoozedUntil => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  BoolColumn get escalationEnabled => boolean().withDefault(const Constant(false))();
}

/// Outbox pattern: every local mutation queues here until pushed remote.
class OutboxEntries extends Table {
  IntColumn get seq => integer().autoIncrement()();
  TextColumn get entityTable => text()();
  TextColumn get entityId => text()();
  TextColumn get operation => text()(); // upsert | delete
  DateTimeColumn get queuedAt => dateTime()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
}
