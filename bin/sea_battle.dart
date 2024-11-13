import 'dart:io';
import 'dart:math';

class GameManager {
  final int gridSize = 10;
  late List<List<String>> playerBoard;
  late List<List<String>> computerBoard;
  late AlertManager alertManager;
  late ShipManager shipManager;
  int playerScore = 0;
  int computerScore = 0;

  GameManager() {
    alertManager = AlertManager();
    shipManager = ShipManager(gridSize);
    playerBoard = List.generate(gridSize, (_) => List.filled(gridSize, '~'));
    computerBoard = List.generate(gridSize, (_) => List.filled(gridSize, '~'));
  }

  void startGame() {
    alertManager.printMessage("Добро пожаловать в игру Морской бой!");
    alertManager.printMessage("Хотите расставить корабли самостоятельно? (да/нет):");
    
    var choice;
    while (choice != 'да' && choice != 'нет') {
      choice = stdin.readLineSync()?.toLowerCase();
      if (choice != 'да' && choice != 'нет') {
        alertManager.printMessage("Ошибка ввода. Введите 'да' или 'нет':");
      }
    }
    
    if (choice == 'да') {
      shipManager.manualShipPlacement(playerBoard);
    } else {
      shipManager.placeShips(playerBoard, isPlayer: true);
    }
    
    shipManager.placeShips(computerBoard, isPlayer: false);
    playGame();
  }

  void playGame() {
    while (true) {
      clearConsole();
      displayBoards();

      bool playerTurnSuccess = true;
      while (playerTurnSuccess) {
        playerTurnSuccess = playerTurn();
        if (isGameOver(computerBoard)) {
          alertManager.printMessage("Игрок выиграл!");
          return;
        }
      }

      bool computerTurnSuccess = true;
      while (computerTurnSuccess) {
        computerTurnSuccess = computerTurn();
        if (isGameOver(playerBoard)) {
          alertManager.printMessage("Компьютер выиграл!");
          return;
        }
      }
    }
  }

  bool playerTurn() {
    alertManager.printMessage("Ход игрока. Введите координаты (x y):");

    var coordinates = getValidCoordinates();
    int x = coordinates[0];
    int y = coordinates[1];

    if (computerBoard[x][y] == 'S') {
      alertManager.printMessage("Попал! Ход продолжается.");
      computerBoard[x][y] = 'X';
      playerScore++;
      return true;
    } else {
      alertManager.printMessage("Мимо!");
      computerBoard[x][y] = '*';
      return false;
    }
  }

  bool computerTurn() {
    var random = Random();
    int x = random.nextInt(gridSize);
    int y = random.nextInt(gridSize);

    if (playerBoard[x][y] == 'S') {
      alertManager.printMessage("Компьютер попал! Ход продолжается.");
      playerBoard[x][y] = 'X';
      computerScore++;
      return true;
    } else {
      alertManager.printMessage("Компьютер промахнулся.");
      playerBoard[x][y] = '*';
      return false;
    }
  }

  bool isGameOver(List<List<String>> board) {
    for (var row in board) {
      if (row.contains('S')) return false;
    }
    return true;
  }

  void displayBoards() {
    alertManager.printMessage("Поле игрока:");
    displayBoard(playerBoard);
    alertManager.printMessage("Поле компьютера:");
    displayBoard(computerBoard, hideShips: true);
  }

  void displayBoard(List<List<String>> board, {bool hideShips = false}) {
    print('  ' + List.generate(gridSize, (index) => index).join(' '));
    for (int i = 0; i < gridSize; i++) {
      var row = board[i];
      print('$i ' + row.map((cell) => hideShips && cell == 'S' ? '~' : cell).join(' '));
    }
  }

  List<int> getValidCoordinates() {
    while (true) {
      var input = stdin.readLineSync();
      var coordinates = input?.split(' ').map(int.tryParse).toList();

      if (coordinates != null &&
          coordinates.length == 2 &&
          coordinates[0] != null &&
          coordinates[1] != null &&
          coordinates[0]! >= 0 && coordinates[0]! < gridSize &&
          coordinates[1]! >= 0 && coordinates[1]! < gridSize) {
        return [coordinates[0]!, coordinates[1]!];
      } else {
        alertManager.printMessage("Ошибка ввода. Введите корректные координаты (x y) в пределах поля.");
      }
    }
  }

  void clearConsole() {
    print("\x1B[2J\x1B[0;0H"); // Код для очистки консоли
  }
}

class AlertManager {
  void printMessage(String message) {
    print(message);
  }
}

class Ship {
  int length;
  List<Point> coordinates;

  Ship(this.length) : coordinates = [];
}

class ShipManager {
  final int gridSize;
  late List<Ship> ships;

  ShipManager(this.gridSize) {
    ships = [
      Ship(4),
      Ship(3),
      Ship(3),
      Ship(2),
      Ship(2),
      Ship(2),
      Ship(1),
      Ship(1),
      Ship(1),
      Ship(1),
    ];
  }

  void placeShips(List<List<String>> board, {required bool isPlayer}) {
    var random = Random();
    for (var ship in ships) {
      while (true) {
        int x = random.nextInt(gridSize);
        int y = random.nextInt(gridSize);
        bool horizontal = random.nextBool();
        if (canPlaceShip(ship, board, x, y, horizontal)) {
          placeShip(ship, board, x, y, horizontal);
          break;
        }
      }
    }
  }

  void manualShipPlacement(List<List<String>> board) {
    for (var ship in ships) {
      bool placed = false;
      while (!placed) {
        print("Разместите корабль длиной ${ship.length}. Введите начальные координаты (x y) и ориентацию (h/v):");
        var coordinates = GameManager().getValidCoordinates();
        int x = coordinates[0];
        int y = coordinates[1];
        
        print("Введите ориентацию (h/v):");
        var orientation = stdin.readLineSync()?.toLowerCase();
        if (orientation != 'h' && orientation != 'v') {
          print("Ошибка: введите 'h' для горизонтального или 'v' для вертикального размещения.");
          continue;
        }
        
        bool horizontal = orientation == 'h';
        if (canPlaceShip(ship, board, x, y, horizontal)) {
          placeShip(ship, board, x, y, horizontal);
          print("Корабль размещен!");
          placed = true;
        } else {
          print("Ошибка: нельзя разместить корабль в данной позиции.");
        }
      }
    }
  }

  bool canPlaceShip(Ship ship, List<List<String>> board, int x, int y, bool horizontal) {
    if (horizontal) {
      if (y + ship.length > gridSize) return false;
      for (int i = 0; i < ship.length; i++) {
        if (board[x][y + i] != '~' || !isSafeZone(x, y + i, board)) return false;
      }
    } else {
      if (x + ship.length > gridSize) return false;
      for (int i = 0; i < ship.length; i++) {
        if (board[x + i][y] != '~' || !isSafeZone(x + i, y, board)) return false;
      }
    }
    return true;
  }

  void placeShip(Ship ship, List<List<String>> board, int x, int y, bool horizontal) {
    for (int i = 0; i < ship.length; i++) {
      if (horizontal) {
        board[x][y + i] = 'S';
        ship.coordinates.add(Point(x, y + i));
      } else {
        board[x + i][y] = 'S';
        ship.coordinates.add(Point(x + i, y));
      }
    }
  }

  bool isSafeZone(int x, int y, List<List<String>> board) {
    for (int dx = -1; dx <= 1; dx++) {
      for (int dy = -1; dy <= 1; dy++) {
        int nx = x + dx;
        int ny = y + dy;
        if (nx >= 0 && ny >= 0 && nx < gridSize && ny < gridSize && board[nx][ny] == 'S') {
          return false;
        }
      }
    }
    return true;
  }
}

void main() {
  GameManager gameManager = GameManager();
  gameManager.startGame();
}