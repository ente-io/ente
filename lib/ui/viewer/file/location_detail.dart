import "package:flutter/material.dart";
import "package:photos/ente_theme_data.dart";
import "package:photos/services/location_service.dart";
import "package:photos/ui/common/gradient_button.dart";
import "package:photos/utils/lat_lon_util.dart";

class CreateLocation extends StatefulWidget {
  const CreateLocation({super.key});

  @override
  State<StatefulWidget> createState() {
    return CreateLocationState();
  }
}

class CreateLocationState extends State<CreateLocation> {
  TextEditingController locationController = TextEditingController();
  List<TextEditingController> centerPointController = List.from(
    [TextEditingController(text: "0.0"), TextEditingController(text: "0.0")],
  );
  List<double> centerPoint = List.of([0, 0]);
  final List<double> values = [2, 10, 20, 40, 80, 200, 400, 1200];
  int slider = 0;

  Dialog selectCenterPoint(BuildContext context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ), //this right here
        child: SizedBox(
          height: 300.0,
          width: 300.0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(15),
                child: TextField(
                  controller: centerPointController[0],
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Longitude',
                    hintText: 'Enter Longitude',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(15),
                child: TextField(
                  controller: centerPointController[1],
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Latitude',
                    hintText: 'Enter Latitude',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const Padding(padding: EdgeInsets.only(top: 50.0)),
              TextButton(
                onPressed: () {
                  setState(() {
                    centerPoint = List.of([
                      double.parse(centerPointController[0].text),
                      double.parse(centerPointController[1].text)
                    ]);
                  });
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Select',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.iconColor,
                    fontSize: 18.0,
                  ),
                ),
              )
            ],
          ),
        ),
      );
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 0, 0),
              child: const Align(
                alignment: Alignment.centerLeft,
                child: Text.rich(
                  TextSpan(text: "Add Location"),
                  textAlign: TextAlign.start,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.all(15),
              child: TextField(
                controller: locationController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.subTextColor,
                  hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  border: const OutlineInputBorder(),
                  hintText: 'Enter Your Location',
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
                borderRadius: const BorderRadius.all(Radius.circular(10)),
              ),
              child: ListTile(
                horizontalTitleGap: 2,
                leading: const Icon(Icons.location_on_rounded),
                title: const Text(
                  "Center Point",
                ),
                subtitle: Text(
                  "${convertLatLng(centerPoint[0], true)}, ${convertLatLng(centerPoint[1], false)}",
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .defaultTextColor
                            .withOpacity(0.5),
                      ),
                ),
                trailing: IconButton(
                  onPressed: () async {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) =>
                          selectCenterPoint(context),
                    );
                  },
                  icon: const Icon(Icons.edit),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Container(
                    height: 65,
                    width: 70,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).focusColor,
                      borderRadius: const BorderRadius.all(Radius.circular(5)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          values[slider].round().toString(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Text(
                          "Km",
                          style: TextStyle(
                            fontWeight: FontWeight.w200,
                          ),
                        )
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(left: 20),
                            child: Text(
                              "Radius",
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 5,
                                    activeTrackColor: Theme.of(context)
                                        .colorScheme
                                        .inverseBackgroundColor,
                                    inactiveTrackColor: Theme.of(context)
                                        .colorScheme
                                        .subTextColor,
                                    thumbColor: Theme.of(context)
                                        .colorScheme
                                        .inverseBackgroundColor,
                                  ),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: Slider(
                                      value: slider.toDouble(),
                                      min: 0,
                                      max: values.length - 1,
                                      divisions: values.length - 1,
                                      label: values[slider].toString(),
                                      onChanged: (double value) {
                                        setState(() {
                                          slider = value.toInt();
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 200),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                child: GradientButton(
                  onTap: () async {
                    await LocationService.instance.addLocation(
                      locationController.text,
                      centerPoint[0],
                      centerPoint[1],
                      values[slider].toInt(),
                    );
                    Navigator.pop(context);
                  },
                  text: "Add Location",
                  iconData: Icons.location_on,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
