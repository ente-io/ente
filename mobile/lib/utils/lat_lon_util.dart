String convertLatLng(double decimal, bool isLat) {
  final degree = "${decimal.toString().split(".")[0]}°";
  final minutesBeforeConversion =
      double.parse("0.${decimal.toString().split(".")[1]}");
  final minutes = "${(minutesBeforeConversion * 60).toString().split('.')[0]}'";
  final secondsBeforeConversion = double.parse(
    "0.${(minutesBeforeConversion * 60).toString().split('.')[1]}",
  );
  final seconds =
      '${double.parse((secondsBeforeConversion * 60).toString()).toStringAsFixed(0)}" ';
  final dmsOutput =
      "$degree$minutes$seconds${isLat ? decimal > 0 ? 'N' : 'S' : decimal > 0 ? 'E' : 'W'}";
  return dmsOutput;
}
