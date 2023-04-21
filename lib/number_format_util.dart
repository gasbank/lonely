String formatThousands(int v) {
  return formatThousandsStr(v.toString());
}

String formatThousandsStr(String v) {
  if (v.isEmpty) {
    return '';
  }

  final vv = v.split('.');
  if (vv.length == 2) {
    return '${formatIntThousandsStr(vv[0])}.${vv[1]}';
  } else if (vv.length == 1) {
    return formatIntThousandsStr(vv[0]);
  } else {
    return '***';
  }
}

String formatIntThousandsStr(String v) {
  if (v.isEmpty) {
    return '';
  }

  if (v[0] == '-') {
    return '-${formatPositiveIntThousandsStr(v.substring(1))}';
  } else {
    return formatPositiveIntThousandsStr(v);
  }
}

String formatPositiveIntThousandsStr(String v) {
  String priceInText = "";
  int counter = 0;
  for (int i = (v.length - 1); i >= 0; i--) {
    counter++;
    String str = v[i];
    if ((counter % 3) != 0 && i != 0) {
      priceInText = "$str$priceInText";
    } else if (i == 0) {
      priceInText = "$str$priceInText";
    } else {
      priceInText = ",$str$priceInText";
    }
  }
  return priceInText.trim();
}
