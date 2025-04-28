import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

void showAppMessage(BuildContext context, String message,
    {bool isError = false}) {
  Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_LONG, // Duração da mensagem
    gravity: ToastGravity.TOP, // Posiciona no topo
    timeInSecForIosWeb: 3, // Duração em segundos (para iOS e web)
    backgroundColor: isError ? Colors.red : Colors.green, // Cor de fundo
    textColor: Colors.white, // Cor do texto
    fontSize: 16.0, // Tamanho da fonte
    webPosition: "center", // Posição em web (opcional, ajusta para o centro)
    webBgColor: isError ? "#FF0000" : "#008000", // Cor de fundo em formato web
  );
}
