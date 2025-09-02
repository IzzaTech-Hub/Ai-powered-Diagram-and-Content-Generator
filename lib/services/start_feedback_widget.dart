import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../utils/app_sizes.dart';
// import 'package:vidcraft_ai/app/utils/app_sizes.dart';
// import 'package:google_fonts/google_fonts.dart';


class StarFeedbackWidget extends StatefulWidget {
  final double size;
  final BuildContext mainContext;
  final bool isShowText;
  final IconData icon;

  const StarFeedbackWidget({
    Key? key,
    required this.size,
    required this.mainContext,
    this.isShowText = false,
    required this.icon,
  }) : super(key: key);

  @override
  State<StarFeedbackWidget> createState() => _StarFeedbackWidgetState();

  /// Static method to show feedback dialog directly
  static void showFeedbackDialog(BuildContext context) {
    _showFeedbackDialogStatic(context);
  }

  /// Static implementation of feedback dialog
  static void _showFeedbackDialogStatic(BuildContext context) {
    String? selectedFeedback;
    String? feedbackType = "Negative";
    TextEditingController customFeedbackController = TextEditingController();

    final Map<String, List<String>> feedbackOptions = {
      "Positive": [
        "Great content",
        "Easy to understand",
        "Visually appealing", 
        "Informative",
        "Well structured",
        "Other",
      ],
      "Negative": [
        "Confusing Too complex",
        "Not visually appealing",
        "Inappropriate or harmful content",
        "Sexual or adult content",
        "Bug or technical issue",
        "Other",
      ],
    };

    try {
      showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text("Provide Feedback"),
            content: SizedBox(
              width: AppSizes.width(80),
              child: StatefulBuilder(
                builder: (context, setState) {
                  return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Positive/Negative Selection
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Radio<String>(
                              value: "Positive",
                              groupValue: feedbackType,
                              onChanged: (value) {
                                setState(() {
                                  feedbackType = value;
                                  selectedFeedback = null;
                                  customFeedbackController.clear();
                                });
                              },
                            ),
                            const Text("Positive"),
                            const SizedBox(width: 20),
                            Radio<String>(
                              value: "Negative",
                              groupValue: feedbackType,
                              onChanged: (value) {
                                setState(() {
                                  feedbackType = value;
                                  selectedFeedback = null;
                                  customFeedbackController.clear();
                                });
                              },
                            ),
                            const Text("Negative"),
                          ],
                        ),

                        // Feedback Options
                        ...feedbackOptions[feedbackType]!.map((option) {
                          return RadioListTile<String>(
                            title: Text(option),
                            value: option,
                            groupValue: selectedFeedback,
                            onChanged: (value) {
                              setState(() {
                                selectedFeedback = value;
                                if (value != "Other") {
                                  customFeedbackController.clear();
                                }
                              });
                            },
                          );
                        }).toList(),

                        // Show TextField if "Other" is selected
                        if (selectedFeedback == "Other")
                          Padding(
                            padding: const EdgeInsets.only(top: 10.0),
                            child: TextField(
                              controller: customFeedbackController,
                              decoration: const InputDecoration(
                                labelText: "Your feedback",
                                border: OutlineInputBorder(),
                                hintText: "Enter your feedback here...",
                              ),
                              maxLines: 3,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  String finalFeedback = selectedFeedback == "Other"
                      ? customFeedbackController.text
                      : selectedFeedback ?? "";

                  if (finalFeedback.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please provide feedback."),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  try {
                    await FirebaseFirestore.instance
                        .collection('reported_messages')
                        .add({
                          'reason': finalFeedback,
                          'type': feedbackType,
                          'reportedAt': DateTime.now(),
                        });

                    // Close feedback dialog and show success
                    Navigator.of(dialogContext).pop();
                    
                    // Show success dialog
                    if (context.mounted) {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (successContext) {
                          return const AlertDialog(
                            title: Text("Thank You!"),
                            content: Text("Your feedback has been submitted."),
                          );
                        },
                      );

                      // Close success dialog after delay
                      Future.delayed(const Duration(seconds: 1), () {
                        if (context.mounted) {
                          Navigator.of(context).pop(); // Close thank you dialog
                        }
                      });
                    }
                  } catch (e) {
                    print("Error submitting feedback: $e");
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Error submitting feedback. Please try again."),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text("Submit"),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print("Error showing feedback dialog: $e");
    }
  }
}

class _StarFeedbackWidgetState extends State<StarFeedbackWidget> {
  bool isStarred = false; // Track if feedback is given
  String? selectedFeedback; // Selected feedback option
  String? feedbackType = "Negative"; // Default feedback type
  TextEditingController customFeedbackController = TextEditingController();

  final Map<String, List<String>> feedbackOptions = {
    "Positive": [
      "Great content",
      "Easy to understand",
      "Visually appealing",
      "Informative",
      "Well structured",
      "Other",
    ],
    "Negative": [
      // "Difficult to understand",
      "Confusing Too complex",
      "Not visually appealing",
      // "Lacks information",
      // "Not well structured",
      "Inappropriate or harmful content",
      "Sexual or adult content",
      "Bug or technical issue",
      "Other",
    ],
  };
  void showFeedbackDialog(BuildContext mainContext) {
    try {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Provide Feedback"),
            content: SizedBox(
              width: AppSizes.width(80),
              child: StatefulBuilder(
                builder: (context, setState) {
                  return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Positive/Negative Selection
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Radio<String>(
                              value: "Positive",
                              groupValue: feedbackType,
                              onChanged: (value) {
                                setState(() {
                                  feedbackType = value;
                                  selectedFeedback = null;
                                  customFeedbackController.clear();
                                });
                              },
                            ),
                            const Text("Positive"),
                            const SizedBox(width: 20),
                            Radio<String>(
                              value: "Negative",
                              groupValue: feedbackType,
                              onChanged: (value) {
                                setState(() {
                                  feedbackType = value;
                                  selectedFeedback = null;
                                  customFeedbackController.clear();
                                });
                              },
                            ),
                            const Text("Negative"),
                          ],
                        ),

                        // Feedback Options
                        ...feedbackOptions[feedbackType]!.map((option) {
                          return RadioListTile<String>(
                            title: Text(option),
                            value: option,
                            groupValue: selectedFeedback,
                            onChanged: (value) {
                              setState(() {
                                selectedFeedback = value;
                                if (value != "Other") {
                                  customFeedbackController.clear();
                                }
                              });
                            },
                          );
                        }).toList(),

                        // Show TextField if "Other" is selected
                        if (selectedFeedback == "Other")
                          Padding(
                            padding: const EdgeInsets.only(top: 10.0),
                            child: TextField(
                              controller: customFeedbackController,
                              decoration: InputDecoration(
                                labelText: "Your feedback",
                                border: OutlineInputBorder(),
                                hintText: "Enter your feedback here...",
                              ),
                              maxLines: 3,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  String finalFeedback = selectedFeedback == "Other"
                      ? customFeedbackController.text
                      : selectedFeedback ?? "";

                  if (finalFeedback.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text("Please provide feedback."),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  setState(() {
                    isStarred = true;
                  });

                  FirebaseFirestore.instance
                      .collection('reported_messages')
                      .add({
                        'reason': finalFeedback,
                        'type': feedbackType,
                        'reportedAt': DateTime.now(),
                      });

                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text("Thank You!"),
                        content: const Text(
                          "Your feedback has been submitted.",
                        ),
                      );
                    },
                  );

                  // Close dialog after 1.5 seconds
                  Future.delayed(const Duration(seconds: 1), () {
                    Navigator.of(context).pop(); // Close Thank You dialog
                    Navigator.of(context).pop(); // Close original dialog
                  });
                },
                child: const Text("Submit"),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print("Error showing feedback dialog: $e");
      Navigator.of(context).pop(); // Close original feedback dialog
    }
  }

  @override
  Widget build(BuildContext context) {
    double size = widget.size;
    IconData icon = widget.icon;
    final buildContext = widget.mainContext;
    return GestureDetector(
      onTap: () {
        showFeedbackDialog(buildContext);
      },
      child: Row(
        children: [
          widget.isShowText
              ? Text(
                  "Feedback",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                  ),
                  // GoogleFonts.nunitoSans(
                  // ),
                )
              : Container(),
          Container(
            // width: SizeConfig.blockSizeHorizontal * size,
            // height: SizeConfig.blockSizeHorizontal * size,
            // padding: EdgeInsets.all(8),
            padding: EdgeInsets.all(AppSizes.width(1)),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(30)),
            child: Center(
              child: Icon(icon, color: Colors.white, size: size),
            ),
          ),
        ],
      ),
    );
  }
}
