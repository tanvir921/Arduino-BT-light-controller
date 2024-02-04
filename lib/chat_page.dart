import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial_ble/flutter_bluetooth_serial_ble.dart';
import 'package:speech_to_text_google_dialog/speech_to_text_google_dialog.dart';

class ChatPage extends StatefulWidget {
  final BluetoothDevice server;

  const ChatPage({required this.server});

  @override
  _ChatPage createState() => new _ChatPage();
}

class _Message {
  int whom;
  String text;

  _Message(this.whom, this.text);
}

class _ChatPage extends State<ChatPage> {
  static final clientID = 0;
  BluetoothConnection? connection;

  List<_Message> messages = List<_Message>.empty(growable: true);
  String _messageBuffer = '';
  String? voiceMessage;

  final TextEditingController textEditingController =
      new TextEditingController();
  final ScrollController listScrollController = new ScrollController();

  bool isConnecting = true;
  bool get isConnected => (connection?.isConnected ?? false);

  bool isDisconnecting = false;
  bool btnValue = false;

  @override
  void initState() {
    super.initState();

    BluetoothConnection.toAddress(widget.server.address).then((_connection) {
      print('Connected to the device');
      connection = _connection;
      setState(() {
        isConnecting = false;
        isDisconnecting = false;
      });

      connection!.input!.listen(_onDataReceived).onDone(() {
        // Example: Detect which side closed the connection
        // There should be `isDisconnecting` flag to show are we are (locally)
        // in middle of disconnecting process, should be set before calling
        // `dispose`, `finish` or `close`, which all causes to disconnect.
        // If we except the disconnection, `onDone` should be fired as result.
        // If we didn't except this (no flag set), it means closing by remote.
        if (isDisconnecting) {
          print('Disconnecting locally!');
        } else {
          print('Disconnected remotely!');
        }
        if (this.mounted) {
          setState(() {});
        }
      });
    }).catchError((error) {
      print('Cannot connect, exception occured');
      print(error);
    });
  }

  @override
  void dispose() {
    // Avoid memory leak (`setState` after dispose) and disconnect
    if (isConnected) {
      isDisconnecting = true;
      connection?.dispose();
      connection = null;
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final List<Row> list = messages.map((_message) {
    //   return Row(
    //     mainAxisAlignment: _message.whom == clientID
    //         ? MainAxisAlignment.end
    //         : MainAxisAlignment.start,
    //     children: <Widget>[
    //       Container(
    //         padding: const EdgeInsets.all(12.0),
    //         margin: const EdgeInsets.only(bottom: 8.0, left: 8.0, right: 8.0),
    //         width: 222.0,
    //         decoration: BoxDecoration(
    //             color:
    //                 _message.whom == clientID ? Colors.blueAccent : Colors.grey,
    //             borderRadius: BorderRadius.circular(7.0)),
    //         child: Text(
    //             (text) {
    //               return text == '/shrug' ? '¯\\_(ツ)_/¯' : text;
    //             }(_message.text.trim()),
    //             style: const TextStyle(color: Colors.white)),
    //       ),
    //     ],
    //   );
    // }).toList();

    final serverName = widget.server.name ?? "Unknown";

    return Scaffold(
        appBar: AppBar(
          title: Text('Smart Light Controller'),
          centerTitle: true,
        ),
        body: isConnecting
            ? Center(
                child: Text(
                'Connecting to $serverName, please wait...',
                style: TextStyle(
                  fontSize: 20,
                ),
              ))
            : isConnected
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Center(
                        child: Icon(
                          Icons.lightbulb,
                          size: 250,
                          color: btnValue == true
                              ? Colors.yellow.shade600
                              : Colors.grey.shade400,
                          
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Center(
                            child: SizedBox(
                              height: 150,
                              width: 150,
                              child: Transform.scale(
                                  scale: 2.8,
                                  child: Switch(
                                    value: btnValue,
                                    onChanged: (value) {
                                      setState(() {
                                        btnValue = value;
                                        value == true
                                            ? _sendMessage('1')
                                            : _sendMessage('0');
                                        value == true
                                            ? ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                                const SnackBar(
                                                  width: 200,
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                  content: Text(
                                                    'Light Turned ON',
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.all(
                                                              Radius.circular(
                                                                  50))),
                                                ),
                                              )
                                            : ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                                const SnackBar(
                                                  width: 200,
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                  content: Text(
                                                    'Light Turned OFF',
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.all(
                                                              Radius.circular(
                                                                  50))),
                                                ),
                                              );
                                      });
                                    },
                                  )),
                            ),
                          ),
                          Center(
                            child: GestureDetector(
                              onTap: () {
                                _sendVoiceMessage();
                              },
                              child: Container(
                                height: 90,
                                width: 150,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(
                                    15,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.mic,
                                    color: Colors.white,
                                    size: 50,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Container(
                      //   margin: const EdgeInsets.all(8.0),
                      //   child: IconButton(
                      //       icon: const Icon(Icons.mic),
                      //       onPressed: isConnected ? () => _sendVoiceMessage() : null),
                      // ),

                      // Flexible(
                      //   child: ListView(
                      //       padding: const EdgeInsets.all(12.0),
                      //       controller: listScrollController,
                      //       children: list),
                      // ),
                      // Row(
                      //   children: <Widget>[
                      //     Flexible(
                      //       child: Container(
                      //         margin: const EdgeInsets.only(left: 16.0),
                      //         child: TextField(
                      //           style: const TextStyle(fontSize: 15.0),
                      //           controller: textEditingController,
                      //           decoration: InputDecoration.collapsed(
                      //             hintText: isConnecting
                      //                 ? 'Wait until connected...'
                      //                 : isConnected
                      //                     ? 'Type your message...'
                      //                     : 'Chat got disconnected',
                      //             hintStyle: const TextStyle(color: Colors.grey),
                      //           ),
                      //           enabled: isConnected,
                      //         ),
                      //       ),
                      //     ),
                      //     Container(
                      //       margin: const EdgeInsets.all(8.0),
                      //       child: IconButton(
                      //           icon: const Icon(Icons.send),
                      //           onPressed: isConnected
                      //               ? () => _sendMessage(textEditingController.text)
                      //               : null),
                      //     ),
                      //     const SizedBox(
                      //       width: 5,
                      //     ),
                      //     Container(
                      //       margin: const EdgeInsets.all(8.0),
                      //       child: IconButton(
                      //           icon: const Icon(Icons.mic),
                      //           onPressed:
                      //               isConnected ? () => _sendVoiceMessage() : null),
                      //     ),
                      //   ],
                      // )
                    ],
                  )
                : Center(
                    child: Text(
                      'Disconnected from $serverName',
                      style: TextStyle(
                        fontSize: 20,
                      ),
                    ),
                  ));
  }

  void _onDataReceived(Uint8List data) {
    // Allocate buffer for parsed data
    int backspacesCounter = 0;
    data.forEach((byte) {
      if (byte == 8 || byte == 127) {
        backspacesCounter++;
      }
    });
    Uint8List buffer = Uint8List(data.length - backspacesCounter);
    int bufferIndex = buffer.length;

    // Apply backspace control character
    backspacesCounter = 0;
    for (int i = data.length - 1; i >= 0; i--) {
      if (data[i] == 8 || data[i] == 127) {
        backspacesCounter++;
      } else {
        if (backspacesCounter > 0) {
          backspacesCounter--;
        } else {
          buffer[--bufferIndex] = data[i];
        }
      }
    }

    // Create message if there is new line character
    String dataString = String.fromCharCodes(buffer);
    int index = buffer.indexOf(13);
    if (~index != 0) {
      setState(() {
        messages.add(
          _Message(
            1,
            backspacesCounter > 0
                ? _messageBuffer.substring(
                    0, _messageBuffer.length - backspacesCounter)
                : _messageBuffer + dataString.substring(0, index),
          ),
        );
        _messageBuffer = dataString.substring(index);
      });
    } else {
      _messageBuffer = (backspacesCounter > 0
          ? _messageBuffer.substring(
              0, _messageBuffer.length - backspacesCounter)
          : _messageBuffer + dataString);
    }
  }

  void _sendMessage(String text) async {
    text = text.trim();
    textEditingController.clear();

    if (text.length > 0) {
      try {
        connection!.output.add(Uint8List.fromList(utf8.encode(text + "\r\n")));
        await connection!.output.allSent;

        setState(() {
          messages.add(_Message(clientID, text));
        });

        Future.delayed(const Duration(milliseconds: 333)).then((_) {
          listScrollController.animateTo(
              listScrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 333),
              curve: Curves.easeOut);
        });
      } catch (e) {
        // Ignore error, but notify state
        setState(() {});
      }
    }
  }

  void _sendVoiceMessage() async {
    bool isServiceAvailable = await SpeechToTextGoogleDialog.getInstance()
        .showGoogleDialog(onTextReceived: (data) async {
      setState(() {
        voiceMessage = data.toString() == 'light on'
            ? '1'
            : data.toString() == 'light off'
                ? '0'
                : null;
      });

      setState(() {
        voiceMessage == '1' ? btnValue = true : btnValue = false;
      });

      if (voiceMessage != null && voiceMessage!.length > 0) {
        try {
          // Wait for speech recognition to complete before sending the message
          await _sendBluetoothMessage(voiceMessage!);
        } catch (e) {
          // Handle any errors during Bluetooth message sending
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Error sending message to Bluetooth'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height - 100,
              left: 16,
              right: 16,
            ),
          ));
        }
      }
    });

    if (!isServiceAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Service is not available'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 100,
          left: 16,
          right: 16,
        ),
      ));
    }
  }

// A separate method for sending the Bluetooth message
  Future<void> _sendBluetoothMessage(String message) async {
    // Send the Bluetooth message logic goes here
    connection!.output.add(Uint8List.fromList(utf8.encode(message + "\r\n")));
    await connection!.output.allSent;

    setState(() {
      messages.add(_Message(clientID, message));
    });

    // Scroll to the end of the list
    Future.delayed(const Duration(milliseconds: 333)).then((_) {
      listScrollController.animateTo(
        listScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 333),
        curve: Curves.easeOut,
      );
    });
  }
}
