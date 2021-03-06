import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polka_wallet/page/profile/account/exportResultPage.dart';
import 'package:polka_wallet/service/substrateApi/api.dart';
import 'package:polka_wallet/store/account.dart';
import 'package:polka_wallet/utils/format.dart';
import 'package:polka_wallet/utils/i18n/index.dart';

class ExportAccountPage extends StatelessWidget {
  ExportAccountPage(this.store);
  static final String route = '/profile/export';
  static final String exportTypeKeystore = 'keystore';
  final AccountStore store;

  final TextEditingController _passCtrl = new TextEditingController();

  void _showPasswordDialog(BuildContext context, String seedType) {
    final Map<String, String> dic = I18n.of(context).profile;
    final Map<String, String> accDic = I18n.of(context).account;

    Future<void> onOk() async {
      var res = await webApi.account.checkAccountPassword(_passCtrl.text);
      if (res == null) {
        showCupertinoDialog(
          context: context,
          builder: (BuildContext context) {
            return CupertinoAlertDialog(
              title: Text(dic['pass.error']),
              content: Text(dic['pass.error.txt']),
              actions: <Widget>[
                CupertinoButton(
                  child: Text(I18n.of(context).home['ok']),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          },
        );
      } else {
        Navigator.of(context).pop();
        String seed = await store.decryptSeed(
            store.currentAccount.pubKey, seedType, _passCtrl.text.trim());
        Navigator.of(context).pushNamed(ExportResultPage.route, arguments: {
          'key': seed,
          'type': seedType,
        });
      }
    }

    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text(dic['delete.confirm']),
          content: Padding(
            padding: EdgeInsets.only(top: 16),
            child: CupertinoTextField(
              placeholder: dic['pass.old'],
              controller: _passCtrl,
              clearButtonMode: OverlayVisibilityMode.editing,
              onChanged: (v) {
                return Fmt.checkPassword(v.trim())
                    ? null
                    : accDic['create.password.error'];
              },
              obscureText: true,
            ),
          ),
          actions: <Widget>[
            CupertinoButton(
              child: Text(I18n.of(context).home['cancel']),
              onPressed: () {
                Navigator.of(context).pop();
                _passCtrl.clear();
              },
            ),
            CupertinoButton(
              child: Text(I18n.of(context).home['ok']),
              onPressed: onOk,
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var dic = I18n.of(context).profile;
    return Scaffold(
      appBar: AppBar(
        title: Text(dic['export']),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            title: Text('Keystore'),
            trailing: Icon(Icons.arrow_forward_ios, size: 18),
            onTap: () {
              Map json = AccountData.toJson(store.currentAccount);
              json.remove('name');
              Navigator.of(context)
                  .pushNamed(ExportResultPage.route, arguments: {
                'key': jsonEncode(json),
                'type': exportTypeKeystore,
              });
            },
          ),
          FutureBuilder(
            future: store.checkSeedExist(
                store.seedTypeMnemonic, store.currentAccount.pubKey),
            builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
              if (snapshot.hasData && snapshot.data == true) {
                return ListTile(
                  title: Text('Mnemonic'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 18),
                  onTap: () =>
                      _showPasswordDialog(context, store.seedTypeMnemonic),
                );
              } else {
                return Container();
              }
            },
          ),
          FutureBuilder(
            future: store.checkSeedExist(
                store.seedTypeRaw, store.currentAccount.pubKey),
            builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
              if (snapshot.hasData && snapshot.data == true) {
                return ListTile(
                  title: Text('Raw Seed'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 18),
                  onTap: () => _showPasswordDialog(context, store.seedTypeRaw),
                );
              } else {
                return Container();
              }
            },
          ),
        ],
      ),
    );
  }
}
