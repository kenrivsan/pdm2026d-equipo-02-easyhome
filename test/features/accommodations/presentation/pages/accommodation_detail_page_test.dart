import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:easyhome/features/accommodations/domain/entities/accommodation.dart';
import 'package:easyhome/features/accommodations/presentation/pages/accommodation_detail_page.dart';

void main() {
  testWidgets(
    'muestra la información detallada de un alojamiento',
    (WidgetTester tester) async {
      const accommodation = Accommodation(
        id: 'accommodation-1',
        title: 'Apartamento para estudiantes',
        type: AccommodationType.apartment,
        location: 'Zona 3, Quetzaltenango',
        departmentId: 'quetzaltenango',
        universityIds: ['mesoamericana-quetzaltenango'],
        monthlyPrice: 2200,
        bathrooms: 1,
        sizeSquareMeters: 45,
        imageUrls: [],
        contactName: 'Persona anfitriona de ejemplo',
        contactPhone: '5555-0102',
        contactEmail: 'host@example.com',
        available: true,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: AccommodationDetailPage(
            accommodation: accommodation,
          ),
        ),
      );

      expect(find.text('Detalle del alojamiento'), findsOneWidget);
      expect(find.text('Apartamento para estudiantes'), findsOneWidget);
      expect(find.text('Apartamento'), findsOneWidget);
      expect(find.text('Zona 3, Quetzaltenango'), findsOneWidget);
      expect(find.text('Disponible'), findsOneWidget);
      expect(find.text('45 m²'), findsOneWidget);
      expect(find.text('Q2200.00'), findsOneWidget);
      expect(find.text('No hay imágenes disponibles.'), findsOneWidget);
      expect(
        find.text('Persona anfitriona de ejemplo'),
        findsOneWidget,
      );
      expect(find.text('5555-0102'), findsOneWidget);
      expect(find.text('host@example.com'), findsOneWidget);
    },
  );
}