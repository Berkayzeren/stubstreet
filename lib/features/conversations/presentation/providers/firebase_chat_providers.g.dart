// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'firebase_chat_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$firebaseChatServiceHash() =>
    r'8e7e725b77e442f00304989824a807525c8d64cf';

/// Firebase Chat Service Provider
///
/// Bu provider, uygulamanın her yerinde kullanılabilecek
/// Firebase chat servis instance'ını sağlar.
///
/// Copied from [firebaseChatService].
@ProviderFor(firebaseChatService)
final firebaseChatServiceProvider = Provider<FirebaseChatService>.internal(
  firebaseChatService,
  name: r'firebaseChatServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$firebaseChatServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FirebaseChatServiceRef = ProviderRef<FirebaseChatService>;
String _$totalUnreadMessagesCountHash() =>
    r'11286f809406affc5462d969cd260911c46af674';

/// Kullanıcının tüm sohbetlerindeki toplam okunmamış mesaj sayısını hesaplayan provider
///
/// Bu provider, bottom navigation bar'da mesaj tab'ının yanında badge göstermek için kullanılır.
///
/// Copied from [totalUnreadMessagesCount].
@ProviderFor(totalUnreadMessagesCount)
final totalUnreadMessagesCountProvider = AutoDisposeProvider<int>.internal(
  totalUnreadMessagesCount,
  name: r'totalUnreadMessagesCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$totalUnreadMessagesCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TotalUnreadMessagesCountRef = AutoDisposeProviderRef<int>;
String _$authStatusHandlerHash() => r'912384265a5e580bc6515b40124e10480c538f3f';

/// Auth durumu değişikliklerini handle eden provider
/// Bu provider kullanıcının online/offline durumunu yönetir
///
/// Copied from [AuthStatusHandler].
@ProviderFor(AuthStatusHandler)
final authStatusHandlerProvider =
    AutoDisposeNotifierProvider<AuthStatusHandler, void>.internal(
      AuthStatusHandler.new,
      name: r'authStatusHandlerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$authStatusHandlerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AuthStatusHandler = AutoDisposeNotifier<void>;
String _$messageSenderHash() => r'ecdf5611c3d6fda9bd9e0db34ecbdd542af4d297';

/// Mesaj gönderme işlemlerini yöneten provider
///
/// Bu provider, mesaj gönderme işlemlerinin durumunu tutar
/// ve hata yönetimi sağlar.
///
/// Copied from [MessageSender].
@ProviderFor(MessageSender)
final messageSenderProvider =
    AutoDisposeNotifierProvider<MessageSender, AsyncValue<void>>.internal(
      MessageSender.new,
      name: r'messageSenderProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$messageSenderHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$MessageSender = AutoDisposeNotifier<AsyncValue<void>>;
String _$conversationStarterHash() =>
    r'a8e19b0deb6d6efbc19bac649376f698e1b98a36';

/// Yeni sohbet başlatma işlemlerini yöneten provider
///
/// Bu provider, yeni sohbet oluşturma işlemlerinin durumunu tutar.
///
/// Copied from [ConversationStarter].
@ProviderFor(ConversationStarter)
final conversationStarterProvider =
    AutoDisposeNotifierProvider<
      ConversationStarter,
      AsyncValue<String?>
    >.internal(
      ConversationStarter.new,
      name: r'conversationStarterProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$conversationStarterHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ConversationStarter = AutoDisposeNotifier<AsyncValue<String?>>;
String _$onlineUsersCounterHash() =>
    r'c6b29f7beafed4056bd1055a57da3767ec9ef11f';

/// Online kullanıcıları sayan yardımcı provider
///
/// Bu provider, UI'da kaç kullanıcının online olduğunu göstermek için kullanılabilir.
///
/// Copied from [OnlineUsersCounter].
@ProviderFor(OnlineUsersCounter)
final onlineUsersCounterProvider =
    AutoDisposeNotifierProvider<OnlineUsersCounter, int>.internal(
      OnlineUsersCounter.new,
      name: r'onlineUsersCounterProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$onlineUsersCounterHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$OnlineUsersCounter = AutoDisposeNotifier<int>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
