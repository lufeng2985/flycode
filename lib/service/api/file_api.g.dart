// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_api.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(fileApi)
final fileApiProvider = FileApiProvider._();

final class FileApiProvider
    extends $FunctionalProvider<AsyncValue<FileApi>, FileApi, FutureOr<FileApi>>
    with $FutureModifier<FileApi>, $FutureProvider<FileApi> {
  FileApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fileApiProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fileApiHash();

  @$internal
  @override
  $FutureProviderElement<FileApi> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<FileApi> create(Ref ref) {
    return fileApi(ref);
  }
}

String _$fileApiHash() => r'ef4d95a3d41a463267e0f80c71ffac412c877065';
