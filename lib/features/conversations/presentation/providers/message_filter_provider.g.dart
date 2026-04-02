// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_filter_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$messageFilterServiceHash() =>
    r'c258e4e59618544e3b421857e8c72110771fafb0';

/// Message filtering service provider
///
/// This service provides content moderation and filtering capabilities
/// including spam detection, profanity filtering, and threat analysis.
///
/// Copied from [MessageFilterService].
@ProviderFor(MessageFilterService)
final messageFilterServiceProvider =
    AutoDisposeNotifierProvider<
      MessageFilterService,
      MessageFilterService
    >.internal(
      MessageFilterService.new,
      name: r'messageFilterServiceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$messageFilterServiceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$MessageFilterService = AutoDisposeNotifier<MessageFilterService>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
