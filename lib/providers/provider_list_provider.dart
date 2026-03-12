import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../service/api/provider_api.dart';
import '../service/api/models/provider.dart';

part 'provider_list_provider.g.dart';

@Riverpod(keepAlive: true)
Future<ProviderListResponse> providerList(Ref ref) async {
  final api = await ref.watch(providerApiProvider.future);
  return await api.list();
}
