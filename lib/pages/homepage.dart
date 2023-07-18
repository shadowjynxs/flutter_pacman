import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pacman/pages/ghost.dart';
import 'package:pacman/pages/path.dart';
import 'package:pacman/pages/pixel.dart';
import 'package:pacman/pages/player.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static int numberInRow = 11;
  int numberOfSquares = numberInRow * 17;
  int player = numberInRow * 15 + 1;

  List<int> barriers = [
    0,
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    11,
    22,
    33,
    44,
    55,
    66,
    77,
    99,
    110,
    121,
    132,
    143,
    154,
    165,
    176,
    177,
    178,
    179,
    180,
    181,
    182,
    183,
    184,
    185,
    186,
    175,
    164,
    153,
    142,
    131,
    120,
    109,
    87,
    76,
    65,
    54,
    43,
    32,
    21,
    78,
    79,
    80,
    100,
    101,
    102,
    84,
    85,
    86,
    106,
    107,
    108,
    24,
    35,
    46,
    57,
    30,
    41,
    52,
    63,
    81,
    70,
    59,
    61,
    72,
    83,
    26,
    28,
    37,
    38,
    39,
    123,
    134,
    145,
    156,
    129,
    140,
    151,
    162,
    103,
    114,
    125,
    105,
    116,
    127,
    147,
    148,
    149,
    158,
    160
  ];

  List<int> food = [];

  String direction = "right";
  bool preGame = true;
  bool mouthClosed = false;
  bool isGameStarted = false;
  bool isGhostMoving = false;
  int score = 0;

  int ghost = numberInRow * 2 - 2;
  String ghostDirection = "left";

  void startGame() {
    if (!isGameStarted) {
      moveGhost();
      preGame = false;
      isGameStarted = true;
      getFood();
      Timer.periodic(
        const Duration(milliseconds: 200),
        (timer) {
          setState(() {
            mouthClosed = !mouthClosed;
          });

          if (food.contains(player)) {
            food.remove(player);
            score++;
          }

          if (player == ghost) {
            isGameStarted = false;
            timer.cancel();
            showGameOverDialog();
          }

          if (score == 87) {
            isGameStarted = false;
            timer.cancel();
            lvlCompl();
          }

          switch (direction) {
            case "left":
              moveLeft();
              break;
            case "right":
              moveRight();
              break;
            case "up":
              moveUp();
              break;
            case "down":
              moveDown();
              break;
          }
        },
      );
    }
  }

  void getFood() {
    for (int i = 0; i < numberOfSquares; i++) {
      if (!barriers.contains(i)) {
        food.add(i);
      }
    }
  }

  void lvlCompl() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Level Completed"),
            content: Text("Your score: $score"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close the dialog
                  setState(() {
                    preGame = true;
                    isGameStarted = false;
                    score = 0;
                    player = numberInRow * 15 + 1;
                    ghost = numberInRow * 2 - 2;
                    food.clear();
                  });
                  startGame(); // Start the game again after resetting the state
                },
                child: const Text("Next Level"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close the dialog
                  SystemNavigator
                      .pop(); // Close the dialog and return "exit" value
                },
                child: const Text("Exit"),
              ),
            ],
          );
        });
  }

  void showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Game Over"),
          content: Text("Your score: $score"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                setState(() {
                  preGame = true;
                  isGameStarted = false;
                  score = 0;
                  player = numberInRow * 15 + 1;
                  ghost = numberInRow * 2 - 2;
                });
                startGame(); // Start the game again after resetting the state
              },
              child: const Text("Play Again"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                SystemNavigator
                    .pop(); // Close the dialog and return "exit" value
              },
              child: const Text("Exit"),
            ),
          ],
        );
      },
    ).then((value) {
      if (value != null && value == "exit") {
        // This is executed when the "Exit" button is clicked in the dialog
        Navigator.pop(context, "exit"); // Close the app
      }
    });
  }

  void moveGhost() {
    Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (!isGameStarted) {
      timer.cancel();
      isGhostMoving = false;
      return;
    }
      setState(() {
        // Use breadth-first search to find the shortest path to the player's position.
        List<int> queue = [ghost];
        List<int> visited = [ghost];
        Map<int, int?> previous = {};

        while (queue.isNotEmpty) {
          int current = queue.removeAt(0);

          if (current == player) {
            // Found the player's position, so break the loop.
            break;
          }

          // Get possible next positions for the ghost.
          List<int> nextPositions = [
            current - 1, // Left
            current + 1, // Right
            current - numberInRow, // Up
            current + numberInRow, // Down
          ];

          for (int nextPos in nextPositions) {
            if (!visited.contains(nextPos) && !barriers.contains(nextPos)) {
              queue.add(nextPos);
              visited.add(nextPos);
              previous[nextPos] = current;
            }
          }
        }

        // Reconstruct the shortest path to the player.
        List<int> shortestPath = [player];
        int? current = player;
        while (current != null && previous.containsKey(current)) {
          current = previous[current];
          if (current != null) {
            shortestPath.add(current);
          }
        }

        // Move the ghost towards the next position in the shortest path.
        if (shortestPath.length >= 2) {
          int nextPosition = shortestPath[shortestPath.length - 2];
          if (nextPosition == ghost - 1) {
            ghostDirection = "left";
          } else if (nextPosition == ghost + 1) {
            ghostDirection = "right";
          } else if (nextPosition == ghost - numberInRow) {
            ghostDirection = "up";
          } else if (nextPosition == ghost + numberInRow) {
            ghostDirection = "down";
          }

          // Update the ghost's position.
          ghost = nextPosition;
        }
        if (!isGameStarted) {
          timer.cancel();
          isGhostMoving = false; // Reset the flag when the timer is canceled
        }
      });
    });
  }

  void moveLeft() {
    if (!barriers.contains(player - 1)) {
      setState(() {
        player--;
      });
    }
  }

  void moveRight() {
    if (!barriers.contains(player + 1)) {
      setState(() {
        player++;
      });
    }
  }

  void moveUp() {
    if (!barriers.contains(player - numberInRow)) {
      setState(() {
        player -= numberInRow;
      });
    }
  }

  void moveDown() {
    if (!barriers.contains(player + numberInRow)) {
      setState(() {
        player += numberInRow;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                if (details.delta.dy > 0) {
                  direction = "down";
                } else if (details.delta.dy < 0) {
                  direction = "up";
                }
              },
              onHorizontalDragUpdate: (details) {
                if (details.delta.dx > 0) {
                  direction = "right";
                } else if (details.delta.dx < 0) {
                  direction = "left";
                }
              },
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: numberOfSquares,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: numberInRow,
                ),
                itemBuilder: (BuildContext context, int index) {
                  if (mouthClosed && player == index) {
                    return Padding(
                      padding: const EdgeInsets.all(1),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.yellow,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  } else if (player == index) {
                    switch (direction) {
                      case "left":
                        return Transform.rotate(
                          angle: pi,
                          child: const MyPlayer(),
                        );
                      case "right":
                        return const MyPlayer();
                      case "up":
                        return Transform.rotate(
                          angle: 3 * pi / 2,
                          child: const MyPlayer(),
                        );
                      case "down":
                        return Transform.rotate(
                          angle: pi / 2,
                          child: const MyPlayer(),
                        );
                      default:
                        return const MyPlayer();
                    }
                  } else if (ghost == index) {
                    return const MyGhost();
                  } else if (barriers.contains(index)) {
                    return MyPixel(
                      innerColor: Colors.blue[800],
                      outerColor: Colors.blue[900],
                    );
                  } else if (food.contains(index) || preGame) {
                    return const MyPath(
                      innerColor: Colors.yellow,
                      outerColor: Colors.black,
                    );
                  } else {
                    return const MyPath(
                      innerColor: Colors.black,
                      outerColor: Colors.black,
                    );
                  }
                },
              ),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                isGameStarted
                    ? Text(
                        "Score: ${score.toString()}",
                        style: const TextStyle(
                            fontSize: 70,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      )
                    : Container(),
                isGameStarted
                    ? Container()
                    : GestureDetector(
                        onTap: () {
                          startGame();
                        },
                        child: const Text(
                          "T A P   T O   P L A Y",
                          style: TextStyle(
                            fontSize: 40,
                            color: Colors.pink,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
