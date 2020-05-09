import 'dart:convert';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:polka_wallet/common/components/currencyWithIcon.dart';
import 'package:polka_wallet/common/components/roundedButton.dart';
import 'package:polka_wallet/common/components/roundedCard.dart';
import 'package:polka_wallet/common/consts/settings.dart';
import 'package:polka_wallet/common/regInputFormatter.dart';
import 'package:polka_wallet/page-acala/homa/homaHistoryPage.dart';
import 'package:polka_wallet/page/account/txConfirmPage.dart';
import 'package:polka_wallet/service/substrateApi/api.dart';
import 'package:polka_wallet/store/acala/types/stakingPoolInfoData.dart';
import 'package:polka_wallet/store/acala/types/txHomaData.dart';
import 'package:polka_wallet/store/app.dart';
import 'package:polka_wallet/utils/format.dart';
import 'package:polka_wallet/utils/i18n/index.dart';

class HomaRedeemPage extends StatefulWidget {
  HomaRedeemPage(this.store);

  static const String route = '/acala/homa/redeem';
  final AppStore store;

  @override
  _HomaRedeemPageState createState() => _HomaRedeemPageState(store);
}

class _HomaRedeemPageState extends State<HomaRedeemPage> {
  _HomaRedeemPageState(this.store);

  final AppStore store;

  final GlobalKey<RefreshIndicatorState> _refreshKey =
      new GlobalKey<RefreshIndicatorState>();

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountPayCtrl = new TextEditingController();
  final TextEditingController _amountReceiveCtrl = new TextEditingController();

  int _radioSelect = 0;
  int _eraSelected = 0;

  Future<void> _refreshData() async {
    webApi.acala.fetchTokens(store.account.currentAccount.pubKey);
    await webApi.acala.fetchHomaStakingPool();
    if (_amountReceiveCtrl.text.isEmpty) {
      await _updateReceiveAmount(0);
    }
  }

  Future<void> _updateReceiveAmount(double input) async {
    if (mounted) {
      setState(() {
        _amountReceiveCtrl.text = Fmt.priceFloor(
          input * store.acala.stakingPoolInfo.liquidExchangeRate,
          lengthFixed: 3,
        );
      });
    }
  }

  void _onSupplyAmountChange(String v) {
    String supply = v.trim();
    if (supply.isEmpty) {
      return;
    }
    _updateReceiveAmount(double.parse(supply));
  }

  void _onRadioChange(int value) {
    if (value == 1) {
      final Map dicAssets = I18n.of(context).assets;
      StakingPoolInfoData pool = store.acala.stakingPoolInfo;
      if (pool.freeList.length == 0) return;

      showCupertinoModalPopup(
        context: context,
        builder: (_) => Container(
          height: MediaQuery.of(context).copyWith().size.height / 3,
          child: WillPopScope(
            child: CupertinoPicker(
              backgroundColor: Colors.white,
              itemExtent: 58,
              scrollController: FixedExtentScrollController(
                initialItem: _eraSelected,
              ),
              children: pool.freeList.map((i) {
                return Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                      'Era ${i.era}, ${dicAssets['available']} ${Fmt.priceFloor(i.free)}'),
                );
              }).toList(),
              onSelectedItemChanged: (v) {
                setState(() {
                  _eraSelected = v;
                });
              },
            ),
          ),
        ),
      );
    }
    setState(() {
      _radioSelect = value;
    });
    print(value);
  }

  void _onSubmit() {
    if (_formKey.currentState.validate()) {
      int decimals = store.settings.networkState.tokenDecimals;
      String pay = _amountPayCtrl.text.trim();
      String receive = _amountReceiveCtrl.text.trim();
      String strategy = TxHomaData.redeemTypeNow;
      if (_radioSelect == 2) {
        strategy = TxHomaData.redeemTypeWait;
      }
      int era = 0;
      StakingPoolInfoData pool = store.acala.stakingPoolInfo;
      if (pool.freeList.length > 0) {
        era = pool.freeList[_eraSelected].era;
      }
      var args = {
        "title": I18n.of(context).acala['homa.mint'],
        "txInfo": {
          "module": 'homa',
          "call": 'redeem',
        },
        "detail": jsonEncode({
          "amountPay": pay,
          "amountReceive": receive,
          "strategy": _radioSelect == 1 ? 'Era $era' : strategy,
        }),
        "params": [
          Fmt.tokenInt(pay, decimals: decimals).toString(),
          _radioSelect == 1 ? {"Target": era} : strategy
        ],
        "onFinish": (BuildContext txPageContext, Map res) {
//          print(res);
          res['action'] = TxHomaData.actionRedeem;
          res['amountReceive'] = receive;
          store.acala.setHomaTxs([res]);
          Navigator.popUntil(
              txPageContext, ModalRoute.withName(HomaRedeemPage.route));
          _refreshKey.currentState.show();
        }
      };
      Navigator.of(context).pushNamed(TxConfirmPage.route, arguments: args);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  @override
  void dispose() {
    _amountPayCtrl.dispose();
    _amountReceiveCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(_) {
    return Observer(
      builder: (BuildContext context) {
        final Map dic = I18n.of(context).acala;
        final Map dicAssets = I18n.of(context).assets;
        int decimals = store.settings.networkState.tokenDecimals;

        final double inputWidth = MediaQuery.of(context).size.width / 3;

        BigInt balance = Fmt.balanceInt(store.assets.tokenBalances['LDOT']);

        StakingPoolInfoData pool = store.acala.stakingPoolInfo;

        Color primary = Theme.of(context).primaryColor;
        Color grey = Theme.of(context).unselectedWidgetColor;

        double available = pool.communalFree;
        String eraSelectText = dic['homa.era'];
        if (pool.freeList.length > 0) {
          StakingPoolFreeItemData item = pool.freeList[_eraSelected];
          available = item.free;
          eraSelectText +=
              ': ${item.era} (${dicAssets['available']}: ${Fmt.priceFloor(pool.freeList[_eraSelected].free, lengthMax: 3)} DOT)';
        }

        return Scaffold(
          appBar: AppBar(title: Text(dic['homa.redeem']), centerTitle: true),
          body: SafeArea(
            child: RefreshIndicator(
              key: _refreshKey,
              onRefresh: _refreshData,
              child: ListView(
                padding: EdgeInsets.all(16),
                children: <Widget>[
                  RoundedCard(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            CurrencyWithIcon(
                              'LDOT',
                              textWidth: 48,
                              textStyle: Theme.of(context).textTheme.display4,
                            ),
                            Icon(
                              Icons.repeat,
                              color: Theme.of(context).primaryColor,
                            ),
                            CurrencyWithIcon(
                              'DOT',
                              textWidth: 48,
                              textStyle: Theme.of(context).textTheme.display4,
                            ),
                          ],
                        ),
                        Form(
                          key: _formKey,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Container(
                                width: inputWidth,
                                child: TextFormField(
                                  decoration: InputDecoration(
                                    hintText: dic['dex.pay'],
                                    labelText: dic['dex.pay'],
                                    suffix: GestureDetector(
                                      child: Icon(
                                        CupertinoIcons.clear_thick_circled,
                                        color: Theme.of(context).disabledColor,
                                        size: 18,
                                      ),
                                      onTap: () {
                                        WidgetsBinding.instance
                                            .addPostFrameCallback(
                                                (_) => _amountPayCtrl.clear());
                                      },
                                    ),
                                  ),
                                  inputFormatters: [
                                    RegExInputFormatter.withRegex(
                                        '^[0-9]{0,6}(\\.[0-9]{0,$decimals})?\$')
                                  ],
                                  controller: _amountPayCtrl,
                                  keyboardType: TextInputType.numberWithOptions(
                                      decimal: true),
                                  validator: (v) {
                                    if (v.isEmpty) {
                                      return dicAssets['amount.error'];
                                    }
                                    if (double.parse(v.trim()) >=
                                        Fmt.bigIntToDouble(balance,
                                            decimals: decimals)) {
                                      return dicAssets['amount.low'];
                                    }
                                    if (double.parse(v.trim()) >= available) {
                                      return dic['homa.pool.low'];
                                    }
                                    return null;
                                  },
                                  onChanged: _onSupplyAmountChange,
                                ),
                              ),
                              Container(
                                width: inputWidth,
                                child: TextFormField(
                                  decoration: InputDecoration(
                                    labelText: dic['dex.receive'],
                                    suffix: Container(
                                      height: 21,
                                      width: 8,
                                    ),
                                  ),
                                  controller: _amountReceiveCtrl,
                                  readOnly: true,
                                ),
                              )
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            '${dicAssets['balance']}: ${Fmt.token(balance, decimals: decimals)} LDOT',
                            style: TextStyle(
                                color: Theme.of(context).unselectedWidgetColor),
                          ),
                        ),
                        Divider(),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    dic['dex.rate'],
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .unselectedWidgetColor),
                                  ),
                                  Text(
                                      '1 LDOT = ${Fmt.priceFloor(pool.liquidExchangeRate, lengthMax: 3)} DOT'),
                                ],
                              ),
                              GestureDetector(
                                child: Container(
                                  child: Column(
                                    children: <Widget>[
                                      Icon(Icons.history, color: primary),
                                      Text(
                                        dic['loan.txs'],
                                        style: TextStyle(
                                            color: primary, fontSize: 14),
                                      )
                                    ],
                                  ),
                                ),
                                onTap: () => Navigator.of(context)
                                    .pushNamed(HomaHistoryPage.route),
                              ),
                            ])
                      ],
                    ),
                  ),
                  RoundedCard(
                    margin: EdgeInsets.only(top: 16),
                    padding: EdgeInsets.fromLTRB(0, 8, 8, 8),
                    child: Column(
                      children: <Widget>[
                        GestureDetector(
                          child: Row(
                            children: <Widget>[
                              Radio(
                                value: 0,
                                groupValue: _radioSelect,
                                onChanged: (v) => _onRadioChange(v),
                              ),
                              Text(
                                  '${dic['homa.now']} (${dicAssets['available']}: ${Fmt.priceFloor(pool.communalFree)} DOT)'),
                            ],
                          ),
                          onTap: () => _onRadioChange(0),
                        ),
                        GestureDetector(
                          child: Row(
                            children: <Widget>[
                              Radio(
                                value: 1,
                                groupValue: _radioSelect,
                                onChanged: (v) => _onRadioChange(v),
                              ),
                              Text(
                                eraSelectText,
                                style: pool.freeList.length == 0
                                    ? TextStyle(color: grey)
                                    : null,
                              ),
                            ],
                          ),
                          onTap: () => _onRadioChange(1),
                        ),
                        GestureDetector(
                          child: Row(
                            children: <Widget>[
                              Radio(
                                value: 2,
                                groupValue: _radioSelect,
                                onChanged: (v) => _onRadioChange(v),
                              ),
                              Text(
                                  '${dic['homa.unbond']} (${pool.bondingDuration.toInt()} Era ≈ ${pool.unbondingDuration / 1000 ~/ SECONDS_OF_DAY} ${dic['homa.redeem.day']})'),
                            ],
                          ),
                          onTap: () => _onRadioChange(2),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: RoundedButton(
                      text: dic['homa.redeem'],
                      onPressed: _onSubmit,
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}