import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
// import 'package:writeright/main.dart';

import '../widgets/game/question_factory.dart';
import 'package:writeright/new/ui/view_model/game.dart';
import '../widgets/game/widgets/hearts.dart';
import '../widgets/game/widgets/popup.dart';
import '../widgets/game/widgets/progress_bar.dart';

import 'package:writeright/new/utils/logger.dart';
import '../widgets/game/widgets/flag_question.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  GamePageState createState() => GamePageState();
}

class GamePageState extends State<GamePage> {
  @override
  void initState() {
    super.initState();

    // Initialize the game view model
    final viewModel = context.read<GameViewModel>();
    viewModel.initializeGame();
  }

  void _onBackPressed(BuildContext context) {
    // Handle back button press
    context.go('/home'); // Navigate to the home page
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<GameViewModel>(context);

    AppLogger.info('rebuilding GamePage');
    AppLogger.debug('Future: ${viewModel.gameObjectFuture}');

    return Scaffold(
      backgroundColor: const Color(0xFF0A3D62), // Deep blue background
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Add a container to hold the health bar and back button
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Stack(
                    children: [
                      // Back Button (aligned to the left)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () => _onBackPressed(context),
                        ),
                      ),

                      // Health Bar (aligned to the center)
                      Align(
                        alignment: Alignment.center,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: LivesDisplay(
                            maxHealth: viewModel.maxLives,
                            currentHealth: viewModel.currentLives,
                          ),
                        ),
                      ),

                      // Three dot menu (aligned to the right)
                      Align(
                        alignment: Alignment.centerRight,
                        child: viewModel.isGameStarted
                            ? PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.more_vert,
                                  color: Colors.white,
                                ),
                                onSelected: (String value) {
                                  if (value == 'flag') {
                                    showDialog(
                                      context: context,
                                      builder: (context) => FlagQuestionDialog(
                                        questionId: viewModel
                                            .currentQuestion!
                                            .questionId,
                                        viewModel: viewModel,
                                      ),
                                    );
                                  }
                                },
                                itemBuilder: (BuildContext context) =>
                                    <PopupMenuEntry<String>>[
                                      const PopupMenuItem<String>(
                                        value: 'flag',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.flag,
                                              color: Colors.redAccent,
                                            ),
                                            SizedBox(width: 8),
                                            Text('Flag question'),
                                          ],
                                        ),
                                      ),
                                    ],
                              )
                            : const SizedBox(),
                      ),
                    ],
                  ),
                ),

                // Progress Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: viewModel.isGameStarted
                      ? SegmentedProgressBar(
                          totalSegments: viewModel.totalQuestions,
                          currentSegment: viewModel.currentQuestionIndex,
                          segmentStates: viewModel.getProgressBarStates(),
                          completedColor: const Color(0xFF4CAF50), // Green
                          currentColor: const Color(0xFFFFEB3B), // Yellow
                          pendingColor: const Color(0xFF424242), // Dark gray
                          failedColor: const Color(0xFFF44336), // Red
                          height: 6.0,
                          segmentSpacing: 3.0,
                        )
                      : const SizedBox(),
                ),

                const SizedBox(height: 16),

                // Question prompt widget
                FutureBuilder(
                  future: viewModel
                      .gameObjectFuture, // Use a future to fetch the current question
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.0),
                        child: SizedBox(),
                      );
                    } else if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Center(
                          child: Text(
                            'Error: ${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      );
                    } else if (snapshot.hasData) {
                      final prompt = viewModel.currentQuestion?.prompt;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Text(
                          prompt ?? 'No question available',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    } else {
                      return const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.0),
                        child: Center(child: Text('No question available')),
                      );
                    }
                  },
                ),

                const SizedBox(
                  height: 20,
                ), // Spacing between prompt and question content
                // Question Factory Widget
                FutureBuilder(
                  future: viewModel.gameObjectFuture,
                  builder: (context, asyncSnapshot) {
                    if (asyncSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 40),
                              Text(
                                '海豚威威正在加載題目...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ), // Show a loading spinner while waiting
                        ),
                      );
                    } else if (asyncSnapshot.hasError) {
                      return Expanded(
                        child: Center(
                          child: Text(
                            'Error: ${asyncSnapshot.error}', // Display error message
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      );
                    } else if (asyncSnapshot.hasData) {
                      return Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth:
                                  800, // Set the maximum width to 800 pixels
                            ),
                            child: viewModel.currentQuestion != null
                                ? QuestionFactory(
                                    question: viewModel.currentQuestion!,
                                  )
                                : const SizedBox(), // Handle null case
                          ),
                        ),
                      );
                    } else {
                      return const Expanded(
                        child: Center(
                          child: Text(
                            'No data available',
                          ), // Handle no data case
                        ),
                      );
                    }
                  },
                ),

                const SizedBox(height: 20), // Spacing
              ],
            ),
          ),

          // Popup Message Widget
          PopupMessageWidget(
            onButtonPressed: () => viewModel.handlePopupButtonPress(context),
          ),
        ],
      ),
    );
  }
}
