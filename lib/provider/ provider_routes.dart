// lib/provider/provider_routes.dart
import 'package:flutter/widgets.dart';
import 'provider_home.dart';
import 'manage_teas.dart';
import 'manage_orders.dart';
import 'analytics.dart';

Map<String, WidgetBuilder> providerRoutes() {
  return {
    '/provider': (_) => const ProviderHome(),
    '/provider/teas': (_) => const ManageTeasScreen(),
    '/provider/orders': (_) => const ManageOrdersScreen(),
    '/provider/analytics': (_) => const AnalyticsScreen(),
  };
}
