/* import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

abstract class TutorialHelper {
  const TutorialHelper._();

  static TutorialCoachMark getTutorialCoachMark(
    List<TargetFocus> targets,
  ) {
    return TutorialCoachMark(
      targets: targets,
      colorShadow: const Color(0xff00a3ab),
      // alignSkip: Alignment.bottomRight,
      // textSkip: "SKIP",
      // paddingFocus: 10,
      opacityShadow: 0.9,
      onClickTarget: (target) {
        print(target);
      },
      onClickTargetWithTapPosition: (target, tapDetails) {
        print("target: $target");
        print(
          "clicked at position local: ${tapDetails.localPosition} - global: ${tapDetails.globalPosition}",
        );
      },
      onClickOverlay: (target) {
        print(target);
      },
      onSkip: () {
        print("skip");
        return true;
      },
      onFinish: () {
        print("finish");
      },
    );
  }

  static List<TargetFocus> songPageTargets(
    GlobalKey waveFormButton,
    // GlobalKey songController,
    GlobalKey loopTimeline,
    // GlobalKey keyButton2,
    // GlobalKey keyButton3,
    // GlobalKey keyButton4,
    // GlobalKey keyButton5,
  ) {
    

    return [
      TargetFocus(
        identify: "Target 1",
        keyTarget: waveFormButton,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        contents: [
          TargetContent(
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  "Navigate through the song with dragging and dropping",
                  style: titleStyle,
                ),
                Padding(
                  padding: EdgeInsets.only(top: 10.0),
                  child: Text(
                    "Use your fingers to drag and drop the whole song to the left or right",
                    style: contentStyle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      /*TargetFocus(
        identify: "Target 2",
        keyTarget: songController,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        contents: [
          TargetContent(
            align: ContentAlign.left,
            child: Container(
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    "Play and pause the song or an activated loop",
                    style: titleStyle,
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Text(
                      "If no loop is activated, the song will play",
                      style: contentStyle,
                    ),
                  ),
                ],
              ),
            ),
          ),
          TargetContent(
            align: ContentAlign.top,
            child: Container(
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    "Multiples content",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20.0,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Text(
                      "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Proin pulvinar tortor eget maximus iaculis.",
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),*/
      TargetFocus(
        identify: "Target 3",
        keyTarget: loopTimeline,
        contents: [
          TargetContent(
            align: ContentAlign.right,
            child: Container(
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    "Title lorem ipsum",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20.0,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Text(
                      "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Proin pulvinar tortor eget maximus iaculis.",
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ];
  }
}
 */
