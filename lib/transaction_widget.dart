import 'package:flutter/widgets.dart';
import 'package:lonely_flutter/new_transaction_widget.dart';

String formatThousands(int v) {
  return formatThousandsStr(v.toString());
}

String formatThousandsStr(String v){
  String priceInText = "";
  int counter = 0;
  for(int i = (v.length - 1);  i >= 0; i--){
    counter++;
    String str = v[i];
    if((counter % 3) != 0 && i !=0){
      priceInText = "$str$priceInText";
    }else if(i == 0 ){
      priceInText = "$str$priceInText";

    }else{
      priceInText = ",$str$priceInText";
    }
  }
  return priceInText.trim();
}

class TransactionWidget extends StatefulWidget {
  const TransactionWidget({super.key, required this.transaction});

  final Transaction transaction;

  @override
  State<StatefulWidget> createState()  => _TransactionWidgetState();
}

class _TransactionWidgetState extends State<TransactionWidget> {
  @override
  Widget build(BuildContext context) {
    return Row(
        children: <Widget>[
          Text(
            widget.transaction.transactionType == TransactionType.buy ? '매수' : '매도'
          ),
          Text(
            '종목명 (${widget.transaction.stockId})',
          ),
          Text(
            '단가: ${formatThousands(widget.transaction.price)}원',
          ),
          Text(
            '수량: ${formatThousands(widget.transaction.count)}주',
          ),
        ]);
  }
}
