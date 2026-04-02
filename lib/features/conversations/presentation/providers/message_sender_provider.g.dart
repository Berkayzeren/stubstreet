// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_sender_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$messageSenderHash() => r'2b70a919de70b6471f9a2395bb2e7871c1cb4d6e';

/// Enhanced message sender provider with comprehensive error handling
///
/// This provider handles:
/// - Message sending with retry logic
/// - Optimistic UI updates
/// - Proper error handling and user feedback
/// - Message status tracking (sent/delivered/read)
/// - Connection status awareness
/// - Offline message queuing (future enhancement)
///
/// Copied from [MessageSender].
@ProviderFor(MessageSender)
final messageSenderProvider =
    AutoDisposeNotifierProvider<MessageSender, AsyncValue<String?>>.internal(
      MessageSender.new,
      name: r'messageSenderProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$messageSenderHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$MessageSender = AutoDisposeNotifier<AsyncValue<String?>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
