import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:writeright/new/data/models/questions.dart';
import 'package:writeright/new/utils/logger.dart';
import 'package:writeright/new/ui/view/widgets/game/widgets/pairing_card.dart';
import 'package:writeright/new/ui/view_model/game.dart';

enum OnClickAction { select, unselect, correct, wrong }

class PairingCardsView extends StatefulWidget {
  final PairingCardsQuestion question;

  /// ValueNotifier to track wrong flash cards
  final ValueNotifier<Set<int>> wrongFlashCards = ValueNotifier({});

  PairingCardsView({
    super.key,
    required this.question,
  });

  @override
  PairingCardsState createState() => PairingCardsState();
}

class PairingCardsState extends State<PairingCardsView> {
  late List<MultiChoiceOption> options; // List of options to display
  late int remainingPairCount;
  int selectedOptionIndex = -1; // Index of the currently selected option
  List<PairingOption> selectedPairs = []; // List of selected pairs
  List<GlobalKey<PairingCardWidgetState>> cardKeys =
      []; // List to track the state of each card

  late PairingCardsQuestion questionCopy;

  /// Disable every card if end game
  /// set by onWrongAnswer callback
  bool disableAllCards = false;

  @override
  void initState() {
    super.initState();
    AppLogger.debug("PairingCardsQType initialized");
    options = widget.question.pairing.allOptions;
    remainingPairCount = widget.question.pairing.pairs.length;
    // Initialize card keys
    cardKeys = List.generate(
        options.length, (_) => GlobalKey<PairingCardWidgetState>());
    questionCopy = widget.question;
  }

  void _addSelectedPair(List<MultiChoiceOption> items) {
    int nextPairId = selectedPairs.isEmpty
        ? 1 // Start from 1 if no pairs submitted yet
        : selectedPairs.length + 1;
    selectedPairs.add(PairingOption(pairId: nextPairId, items: items));
  }

  bool _onWrongAnswer(BuildContext context) {
    AppLogger.debug("Wrong answer selected");
    // Notify the parent about the wrong answer
    bool isAlive = context.read<GameViewModel>().onWrongPair();
    if (!isAlive) {
      AppLogger.debug("No more health left, ending game");
      _onEndGame(context);
    }
    return isAlive;
  }

  void _onEndGame(BuildContext context) {
    questionCopy.pairing.submittedPairs = selectedPairs;
    setState(() {
      disableAllCards = true;
    });
    AppLogger.debug("disabled? $disableAllCards");
    // Notify the parent with the submitted pairs
    context.read<GameViewModel>().submitPairingCardsAnswer(selectedPairs);
  }

  OnClickAction _getCurrentAction(MultiChoiceOption clickedChoice) {
    if (selectedOptionIndex == -1) {
      return OnClickAction.select; // Select the current card
    } else if (selectedOptionIndex == options.indexOf(clickedChoice)) {
      return OnClickAction.unselect; // Unselect the current card
    } else {
      List<MultiChoiceOption> currentPair = [
        options[selectedOptionIndex],
        clickedChoice
      ];
      if (widget.question.pairing.containPair(currentPair)) {
        return OnClickAction.correct; // Correct pair
      } else {
        return OnClickAction.wrong; // Wrong pair
      }
    }
  }

  /// Build cards using the extracted `PairingCardWidget`
  Widget _buildCard(MultiChoiceOption option, int index) {
    return Expanded(
        child: PairingCardWidget(
            key: cardKeys[index],
            option: option,
            onClick: (MultiChoiceOption option) {
              AppLogger.debug(
                  "selected option before handle new click: $selectedOptionIndex");
              switch (_getCurrentAction(option)) {
                case OnClickAction.select:
                  // Select the current card
                  setState(() {
                    selectedOptionIndex = index;
                  });
                  cardKeys[index].currentState?.onSelect();
                case OnClickAction.unselect:

                  /// If repeated selection, unselect the card
                  if (selectedOptionIndex == index) {
                    setState(() {
                      selectedOptionIndex = -1;
                    });
                    cardKeys[index].currentState?.onCancel();
                    return;
                  }
                case OnClickAction.correct:
                  _addSelectedPair([options[selectedOptionIndex], option]);
                  cardKeys[selectedOptionIndex].currentState?.onCorrect();
                  cardKeys[index].currentState?.onCorrect();

                  setState(() {
                    selectedOptionIndex = -1;
                  });

                  remainingPairCount--;
                  if (remainingPairCount == 0) {
                    _onEndGame(context);
                  }
                case OnClickAction.wrong:
                  cardKeys[selectedOptionIndex].currentState?.onWrong();
                  cardKeys[index].currentState?.onWrong();

                  setState(() {
                    selectedOptionIndex = -1;
                  });

                  _onWrongAnswer(context);
                  break;
              }
            }));
  }

  @override
  Widget build(BuildContext context) {
    int columnCount = widget.question.pairing.display.columns!;
    int cardCount = options.length;

    final cards = List.generate(cardCount, (i) => _buildCard(options[i], i));

    final rows = <Widget>[];
    for (int i = 0; i < cards.length; i += columnCount) {
      rows.add(
        Row(
          mainAxisSize: MainAxisSize.min, // Shrinks the row to fit its children
          mainAxisAlignment:
              MainAxisAlignment.center, // Center the row's children
          children: cards.sublist(
            i,
            (i + columnCount > cards.length) ? cards.length : i + columnCount,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final rows = <Widget>[];
        for (int i = 0; i < cards.length; i += columnCount) {
          rows.add(
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: cards.sublist(
                  i,
                  (i + columnCount > cards.length)
                      ? cards.length
                      : i + columnCount,
                ),
              ),
            ),
          );
        }

        return Center(
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize
                  .min, // Use max to fill the vertical space if needed
              mainAxisAlignment:
                  MainAxisAlignment.spaceEvenly, // Distribute rows evenly
              children: [
                ...rows,
                const SizedBox(height: 50), // Add bottom spacing if needed
              ],
            ),
          ),
        );
      },
    );
  }
}
