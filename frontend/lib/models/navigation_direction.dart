import 'package:flutter/material.dart';

enum NavigationDirection {
  slightLeft('slight_left'),
  left('left'),
  sharpLeft('sharp_left'),
  straight('straight'),
  slightRight('slight_right'),
  right('right'),
  sharpRight('sharp_right'),
  uTurn('u_turn'),
  stairsUp('stairs_up'),
  stairsDown('stairs_down'),
  elevatorUp('elevator_up'),
  elevatorDown('elevator_down'),
  enterBuilding('enter_building'),
  exit('exit'),
  unknown('unknown');

  final String serverValue;
  const NavigationDirection(this.serverValue);

  static NavigationDirection fromServerValue(String? value) {
    return NavigationDirection.values.firstWhere(
      (e) => e.serverValue == value,
      orElse: () => NavigationDirection.unknown,
    );
  }

  IconData get icon {
    switch (this) {
      case NavigationDirection.slightLeft:
        return Icons.turn_slight_left;
      case NavigationDirection.left:
        return Icons.turn_left;
      case NavigationDirection.sharpLeft:
        return Icons.turn_sharp_left;
      case NavigationDirection.straight:
        return Icons.straight;
      case NavigationDirection.slightRight:
        return Icons.turn_slight_right;
      case NavigationDirection.right:
        return Icons.turn_right;
      case NavigationDirection.sharpRight:
        return Icons.turn_sharp_right;
      case NavigationDirection.uTurn:
        return Icons.u_turn_left;
      case NavigationDirection.stairsUp:
        return Icons.stairs;
      case NavigationDirection.stairsDown:
        return Icons.stairs; // Or Icons.downhill_skiing if you want a down variant, but stairs is general
      case NavigationDirection.elevatorUp:
        return Icons.elevator;
      case NavigationDirection.elevatorDown:
        return Icons.elevator;
      case NavigationDirection.enterBuilding:
        return Icons.login;
      case NavigationDirection.exit:
        return Icons.logout;
      case NavigationDirection.unknown:
      default:
        return Icons.navigation;
    }
  }

  Color get color {
    switch (this) {
      case NavigationDirection.stairsUp:
      case NavigationDirection.stairsDown:
      case NavigationDirection.elevatorUp:
      case NavigationDirection.elevatorDown:
        return Colors.blue;
      case NavigationDirection.exit:
      case NavigationDirection.enterBuilding:
        return Colors.orange;
      default:
        return Colors.deepPurple;
    }
  }
}
