import 'package:flutter/material.dart';
import 'package:realearn_companion/domain/connection.dart';

import '../routes.dart';
import 'normal_scaffold.dart';
import 'space.dart';

class EnterConnectionDataWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return NormalScaffold(
      child: SingleChildScrollView(
        child: Column(children: [
          Text(
            "Please enter the connection data!",
            style: Theme.of(context).textTheme.headline6,
            textAlign: TextAlign.center,
          ),
          Space(),
          EnterConnectionDataForm(),
        ]),
      ),
    );
  }
}

class EnterConnectionDataForm extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return EnterConnectionDataFormState();
  }
}

class EnterConnectionDataFormState extends State<EnterConnectionDataForm> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController hostController;
  TextEditingController httpPortController;
  TextEditingController httpsPortController;
  TextEditingController sessionIdController;

  @override
  void initState() {
    super.initState();
    hostController = TextEditingController(text: "192.168.");
    httpPortController = TextEditingController(text: "39080");
    httpsPortController = TextEditingController(text: "39443");
    sessionIdController = TextEditingController(text: "");
  }

  @override
  Widget build(BuildContext context) {
    return Form(
        key: _formKey,
        child: Column(children: <Widget>[
          TextFormField(
            keyboardType: TextInputType.number,
            controller: hostController,
            decoration: InputDecoration(
                filled: true,
                labelText: 'Host',
                helperText: "IP address of the computer running REAPER",
                hintText: '192.168.x.y'),
            validator: (value) {
              if (!isValidIpAddressOrHostName(value)) {
                return 'Please enter an IP address or a host name';
              }
              return null;
            },
          ),
          Space(),
          PortField(
            controller: httpPortController,
            labelText: 'HTTP port',
            helperText: "HTTP port of the ReaLearn server",
            hintText: '39080',
          ),
          Space(),
          PortField(
            controller: httpsPortController,
            labelText: 'HTTPS port',
            helperText: "HTTPS port of the ReaLearn server",
            hintText: '39443',
          ),
          Space(),
          TextFormField(
            decoration: InputDecoration(
                filled: true,
                labelText: 'ReaLearn instance ID',
                helperText: "ID of a particular ReaLearn instance"),
            validator: (value) {
              if (value.isEmpty) {
                return 'Please enter a valid instance ID';
              }
              return null;
            },
          ),
          Space(),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState.validate()) {
                var connectionArgs = ConnectionArgs(
                  host: hostController.value.text,
                  httpPort: httpPortController.value.text,
                  httpsPort: httpsPortController.value.text,
                  sessionId: sessionIdController.value.text,
                );
                Navigator.pushNamed(context,
                    "$controllerRoutingRoute?${connectionArgs.toQueryString()}");
              }
            },
            child: Text('Connect'),
          ),
        ]));
  }
}

var portNumberErrorMsg = 'Please enter a valid port number';

var hostNamePattern = RegExp(
    r"^([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])(\.([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]{0,61}[a-zA-Z0-9]))*$");

bool isValidIpAddressOrHostName(String value) {
  // IP addresses are also valid host names!
  return hostNamePattern.hasMatch(value);
}

bool isValidPortNumber(String value) {
  var number = int.tryParse(value);
  return number != null && number >= 0 && number <= 65535;
}

class PortField extends StatelessWidget {
  final String labelText;
  final String helperText;
  final String hintText;
  final TextEditingController controller;

  const PortField(
      {Key key,
      this.labelText,
      this.helperText,
      this.hintText,
      this.controller})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      keyboardType: TextInputType.number,
      controller: controller,
      decoration: InputDecoration(
          filled: true,
          labelText: labelText,
          helperText: helperText,
          hintText: hintText),
      validator: (value) {
        if (!isValidPortNumber(value)) {
          return portNumberErrorMsg;
        }
        return null;
      },
    );
  }
}
