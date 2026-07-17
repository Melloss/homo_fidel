import 'package:get_it/get_it.dart';

final sl = GetIt.instance;

/// Wires the layers together. Registration order is data -> domain ->
/// presentation, so each layer only ever resolves the one beneath it.
Future<void> init() async {
  // --- Presentation -------------------------------------------------------
  // sl.registerFactory(() => CheckerBloc(scanText: sl(), swapLetter: sl()));

  // --- Domain (use cases) -------------------------------------------------
  // sl.registerLazySingleton(() => ScanText(sl()));
  // sl.registerLazySingleton(() => SwapLetter(sl()));

  // --- Domain (repository contract) -> Data (implementation) --------------
  // sl.registerLazySingleton<HomophoneRepository>(
  //   () => HomophoneRepositoryImpl(localDataSource: sl()),
  // );

  // --- Data (sources) -----------------------------------------------------
  // sl.registerLazySingleton<FamilyLocalDataSource>(
  //   () => FamilyLocalDataSourceImpl(),
  // );
}
