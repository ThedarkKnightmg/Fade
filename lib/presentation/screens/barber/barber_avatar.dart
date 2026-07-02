import 'package:flutter/material.dart';

import '../../../data/app_state.dart';
import '../../widgets/paper_kit.dart';

/// The signed-in barber's avatar — their sign-up photo if they added one,
/// otherwise an initials circle.
class BarberAvatar extends StatelessWidget {
  const BarberAvatar({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    final photo = s.registeredBarber?.photo;
    if (photo != null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(image: MemoryImage(photo), fit: BoxFit.cover),
        ),
      );
    }
    return InitialAvatar(name: s.meBarber.barber.name, size: size, index: 1);
  }
}
