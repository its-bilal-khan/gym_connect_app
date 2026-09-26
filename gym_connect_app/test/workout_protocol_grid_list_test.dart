import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_connect_app/features/workout/domain/models/workout_models.dart';
import 'package:gym_connect_app/features/workout/presentation/desktop/widgets/day_overview_toolbar.dart';
import 'package:gym_connect_app/features/workout/presentation/desktop/widgets/exercise_catalog_picker_dialog.dart';

void main() {
  group('Dual-View Listing (Grid & List View) Standard Tests', () {
    testWidgets('DayOverviewToolbar renders List & Grid view toggle buttons and triggers callback',
        (tester) async {
      bool gridValue = false;

      const dummyDay = WorkoutRoutineDay(
        id: 'day-1',
        routineId: 'routine-1',
        dayNumber: 1,
        title: 'Day 1: Chest & Triceps',
        muscleGroups: ['Chest', 'Triceps'],
        isRestDay: false,
        exercises: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return DayOverviewToolbar(
                  day: dummyDay,
                  isGridView: gridValue,
                  onToggleRestDay: (_) {},
                  onAddExercise: () {},
                  onToggleGridView: (val) {
                    setState(() => gridValue = val);
                  },
                );
              },
            ),
          ),
        ),
      );

      // Verify both List View and Grid View icons exist
      expect(find.byIcon(Icons.view_list_rounded), findsOneWidget);
      expect(find.byIcon(Icons.grid_view_rounded), findsOneWidget);

      // Tap Grid View icon
      await tester.tap(find.byIcon(Icons.grid_view_rounded));
      await tester.pumpAndSettle();

      expect(gridValue, isTrue);

      // Tap List View icon
      await tester.tap(find.byIcon(Icons.view_list_rounded));
      await tester.pumpAndSettle();

      expect(gridValue, isFalse);
    });

    testWidgets('ExerciseCatalogPickerDialog renders Grid & List toggle and switches layouts',
        (tester) async {
      const sampleCatalog = [
        Exercise(
          id: 'ex-1',
          name: 'Flat Barbell Bench Press',
          targetMuscle: 'Chest',
          equipment: 'Barbell',
        ),
        Exercise(
          id: 'ex-2',
          name: 'Incline Dumbbell Press',
          targetMuscle: 'Chest',
          equipment: 'Dumbbell',
        ),
      ];

      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExerciseCatalogPickerDialog(
              catalog: sampleCatalog,
              onExerciseSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially in List View
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(GridView), findsNothing);

      // Toggle to Grid View
      await tester.tap(find.byIcon(Icons.grid_view_rounded), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Now GridView is rendered
      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(ListView), findsNothing);

      // Toggle back to List View
      await tester.tap(find.byIcon(Icons.view_list_rounded), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(GridView), findsNothing);
    });
  });
}
