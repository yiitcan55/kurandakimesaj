import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'theme/app_theme.dart';

/// Uygulama genelinde tutarlı sayfa geçişleri.
///
/// go_router route'larında tekrar eden geçiş kodu yerine bu fabrikalar
/// kullanılır. Tüm süre/eğriler [AppDurations] token'larından gelir.
///
/// Erişilebilirlik: Cihazda "hareketi azalt" (reduce motion) açıksa
/// kaydırma/ölçek bırakılır, yalnız hızlı bir fade uygulanır — sayfa
/// içeriği yine de anlık değil yumuşak görünür ama vestibüler rahatsızlık
/// yaratmaz.
abstract class AppPageTransitions {
  const AppPageTransitions._();

  /// Material 3 "shared axis (X)" benzeri geçiş: yeni sayfa hafifçe sağdan
  /// kayarak ve solarak girer; eski sayfa aksi yönde hafif kayar. Tam ekran
  /// özellik route'ları (detay sayfaları) için varsayılan.
  static CustomTransitionPage<T> sharedAxis<T>({
    required LocalKey? key,
    required Widget child,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      transitionDuration: AppDurations.normal,
      reverseTransitionDuration: AppDurations.fast,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
        if (reduceMotion) {
          return FadeTransition(opacity: animation, child: child);
        }

        const enterOffset = Offset(0.06, 0.0);
        const exitOffset = Offset(-0.03, 0.0);

        final enter = CurvedAnimation(parent: animation, curve: AppDurations.emphasized);
        final exit = CurvedAnimation(parent: secondaryAnimation, curve: AppDurations.easeOut);

        return SlideTransition(
          position: Tween<Offset>(begin: exitOffset, end: Offset.zero).animate(exit),
          child: SlideTransition(
            position: Tween<Offset>(begin: enterOffset, end: Offset.zero).animate(enter),
            child: FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(enter),
              child: child,
            ),
          ),
        );
      },
    );
  }

  /// Material 3 "fade through" geçişi: çıkan sayfa solar, giren sayfa hafif
  /// büyüyerek belirir. Kök/akış geçişleri (splash → setup/home gibi yön
  /// taşımayan akışlar) için uygundur.
  static CustomTransitionPage<T> fadeThrough<T>({
    required LocalKey? key,
    required Widget child,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      transitionDuration: AppDurations.normal,
      reverseTransitionDuration: AppDurations.fast,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
        if (reduceMotion) {
          return FadeTransition(opacity: animation, child: child);
        }

        final enter = CurvedAnimation(parent: animation, curve: AppDurations.easeOut);
        return FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(enter),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1.0).animate(enter),
            child: child,
          ),
        );
      },
    );
  }
}
