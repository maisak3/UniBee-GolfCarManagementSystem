import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:custom_clippers/custom_clippers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get_connect/http/src/utils/utils.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grouped_list/grouped_list.dart';
import 'Notifications.dart';
import 'affiliateInfo.dart';
import 'globals.dart' as globals;
import 'package:intl/intl.dart';

class chatScreen extends StatefulWidget {
  final String aEmail;
  final String aName;

  const chatScreen({
    super.key,
    required this.aEmail,
    required this.aName,
  });

  @override
  State<chatScreen> createState() => _chatScreenState(aEmail, aName);
}

class _chatScreenState extends State<chatScreen> {
  List<Message> messageWidgets = [];
  final aEmail;
  final aName;
  final messageTextController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  late User signedInUser;
  String? messageText;

  _chatScreenState(this.aEmail, this.aName);

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    // Notifications.init();

    getCurrentUser();
  }

  String formattedDate(timeStamp, String format) {
    var dateFromTimeStamp =
        DateTime.fromMillisecondsSinceEpoch(timeStamp.seconds * 1000);
    return DateFormat(format).format(dateFromTimeStamp);
  }

  void getCurrentUser() {
    try {
      final user = _auth.currentUser;
      if (user != null) signedInUser = user;
    } catch (err) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: BackButton(
            onPressed: () {
              globals.affiliateEmail = "";
              Navigator.pop(context);
            },
          ),
          iconTheme: IconThemeData(
            color: Colors.black, //change your color here
          ),
          backgroundColor: Color(0xFFFDD051),
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: Color(0xFFFDD051),
                child: Icon(
                  Icons.person,
                  color: Colors.black,
                  size: 40,
                ),
                radius: 25.0,
              ),
              //Image.asset('images/logo.png', height: 25),
              SizedBox(width: 10),
              Text(
                aName!,
                style: GoogleFonts.alice(fontSize: 25, color: Colors.black),
                // style: TextStyle(
                //   color: Colors.black,
                // ),
              )
            ],
          ),
        ),
        body: GestureDetector(
          onTap: () {
            FocusScope.of(context).requestFocus(FocusNode());
          },
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('messages')
                      .orderBy('time')
                      .snapshots(),
                  builder: (context, snapshot) {
                    //  List<MessageLine> messageWidgets = [];
                    if (!snapshot.hasData) {}

                    try {
                      final messages = snapshot.data!.docs;
                      messageWidgets.clear();
                      for (var message in messages) {
                        if ((message.get('sender') == signedInUser.email &&
                                message.get('receiver') == aEmail) ||
                            (message.get('sender') == aEmail &&
                                message.get('receiver') ==
                                    signedInUser.email)) {
                          final messageText = message.get('text');
                          final messageSender = message.get('sender');
                          final messageTime =
                              formattedDate(message.get('time'), 'hh:mm a');
                          // print(messageTime);
                          final currentUser = signedInUser.email;

                          final messageWidget = Message(
                            sender: messageSender,
                            text: messageText,
                            time: formattedDate(message.get('time'),
                                'EEE MMM dd HH:mm:ss yyyy'),
                            messageTime: messageTime,
                            isMe: currentUser == messageSender,
                            // date: DateTime.fromMillisecondsSinceEpoch(
                            //     message.get('time') * 1000)
                          );

                          if ((message.get('sender') == aEmail &&
                                  message.get('receiver') ==
                                      signedInUser.email) &&
                              (message.get('status') == "new")) {
                            _firestore
                                .collection("messages")
                                .doc(message.id)
                                .update({
                              'status': "old",
                            });
                            _firestore
                                .collection("messages")
                                .doc(message.id)
                                .update({
                              'unread': false,
                            });
                          }

                          messageWidgets.add(messageWidget);
                          // messageWidgets
                          //     .sort((a, b) => a.date.compareTo(b.date));
                        }
                      }
                      if (messageWidgets.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 200),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text("No messages here yet...",
                                  style: GoogleFonts.alice(
                                      fontSize: 15, color: Colors.black)),
                              Text(
                                  "send a message or tap on the greeting below",
                                  style: GoogleFonts.alice(
                                      fontSize: 15, color: Colors.black)),
                              SizedBox(
                                height: 10,
                              ),
                              TextButton(
                                  onPressed: () {
                                    _firestore.collection('messages').add({
                                      'text': "Hello!",
                                      'sender': signedInUser.email,
                                      'receiver': aEmail,
                                      'time': FieldValue.serverTimestamp(),
                                      'status': "new",
                                      'unread': true,
                                    });
                                  },
                                  child: Image.asset('assets/hello.png'))
                            ],
                          ),
                        );
                      }
                    } catch (err) {}
                    // messageWidgets.add(Container(
                    //   height: 50,
                    // ));
                    return Expanded(
                        child: GroupedListView<Message, DateTime>(
                      reverse: true,
                      order: GroupedListOrder.DESC,
                      // useStickyGroupSeparators: true,

                      // floatingHeader: true,
                      elements: messageWidgets,
                      // groupBy: (element) => DateTime(2023),
                      groupBy: (message) => DateTime(
                          HttpDate.parse(message.time).year,
                          HttpDate.parse(message.time).month,
                          HttpDate.parse(message.time).day),
                      groupHeaderBuilder: (Message message) => SizedBox(
                          height: 40,
                          child: Center(
                            child: Card(
                                color: Color(0xFFEB9880),
                                // Theme.of(context).primaryColorDark,
                                child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                        DateFormat.EEEE().format(
                                            HttpDate.parse(message.time)),
                                        // formattedDate(message.time, 'dd MMM, yyyy'),
                                        style: GoogleFonts.alice(
                                            fontSize: 15, color: Colors.white)
                                        // style: const TextStyle(color: Colors.white),
                                        ))),
                          )),
                      itemBuilder: (context, Message message) =>
                          MessageLine(message: message),
                      // Align(
                      //   alignment: message.isMe
                      //       ? Alignment.centerRight
                      //       : Alignment.centerLeft,
                      //   child: Card(
                      //     elevation: 8,
                      //     child: Padding(
                      //         padding: const EdgeInsets.all(12),
                      //         child: Text(message.text)), //
                      //   ),
                      // ),
                      // reverse: true,
                      padding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                      // children: messageWidgets
                    ));
                  },
                ),
                Container(
                    height: 65,
                    decoration: BoxDecoration(
                        border: Border(
                      top: BorderSide(
                        color: Color(0xFFFDD051),
                        width: 2,
                      ),
                    )),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Color(0x7fd9d9d9),
                                // boxShadow: [
                                //   BoxShadow(
                                //     blurRadius: 10,
                                //     spreadRadius: 2,
                                //     offset: Offset(0, 3),
                                //     color: Colors.grey.withOpacity(0.5),
                                //   )
                                // ],
                              ),
                              child: TextFormField(
                                  controller: messageTextController,
                                  onChanged: (value) {
                                    messageText = value;
                                  },
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 10,
                                      horizontal: 20,
                                    ),
                                    hintText: 'Write your message here...',
                                    border: InputBorder.none,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.deny(
                                        RegExp(r'^\s')),
                                  ]),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // _scrollController.animateTo(
                            //     _scrollController.position.maxScrollExtent,
                            //     duration: Duration(milliseconds: 300),
                            //     curve: Curves.easeOut);
                            if (messageText != null && messageText != "") {
                              _firestore.collection('messages').add({
                                'text': messageText,
                                'receiver': aEmail,
                                'sender': signedInUser.email,
                                'time': FieldValue.serverTimestamp(),
                                'status': "new",
                                'unread': true,
                              });
                              messageTextController.clear();
                              messageText = null;
                            }
                          },
                          child: CircleAvatar(
                            backgroundColor: Color(0xFFFDD051),
                            child: Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 28,
                            ),
                            radius: 30,
                          ),
                        )
                      ],
                    ))
              ],
            ),
          ),
        ));
  }
}

class Message {
  final String sender;
  final String text;
  final String time;
  final bool isMe;
  final String? messageTime;
  // final DateTime date;

  Message({
    required this.sender,
    required this.text,
    required this.time,
    required this.isMe,
    this.messageTime,
    // required this.date
  });
}

class MessageLine extends StatelessWidget {
  const MessageLine({required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment:
            message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          ClipPath(
            clipper: message.isMe
                ? LowerNipMessageClipper((MessageType.send))
                : LowerNipMessageClipper(MessageType.receive),
            child: Material(
              elevation: 5,
              borderRadius: message.isMe
                  ? BorderRadius.only(
                      topLeft: Radius.circular(30),
                      bottomLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    )
                  : BorderRadius.only(
                      topRight: Radius.circular(30),
                      topLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
              color: message.isMe ? Color(0xff204854) : Color(0xffb9d4d3),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                child: Text('${message.text}',
                    style: GoogleFonts.alice(
                        fontSize: 17,
                        color: message.isMe ? Colors.white : Colors.black45)
                    // style: TextStyle(
                    //     fontSize: 15,
                    //     color: message.isMe ? Colors.white : Colors.black45),
                    ),
              ),
            ),
          ),
          SizedBox(
            height: 5,
          ),
          Text(
            '${message.messageTime}',
            style: TextStyle(fontSize: 12, color: Colors.black45),
          ),
        ],
      ),
    );
  }
}
