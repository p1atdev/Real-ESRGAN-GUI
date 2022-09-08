
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as path;

void main() {
  runApp(const RealESRGanGUIApp());
}

class RealESRGanGUIApp extends StatelessWidget {
  const RealESRGanGUIApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Real-ESRGAN-GUI',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Hiragino Sans',
        snackBarTheme: SnackBarThemeData(
          contentTextStyle: TextStyle(fontFamily: 'Hiragino Sans'),
        ),
      ),
      home: const MainWindowPage(title: 'Real-ESRGAN-GUI'),
    );
  }
}

class MainWindowPage extends StatefulWidget {
  const MainWindowPage({super.key, required this.title});

  final String title;

  @override
  State<MainWindowPage> createState() => _MainWindowPageState();
}

class _MainWindowPageState extends State<MainWindowPage> {

  // 入力ファイル
  XFile? inputFile;

  // 入力ファイルフォームのコントローラー
  TextEditingController inputFileController = TextEditingController();

  // 出力ファイルフォームのコントローラー
  TextEditingController outputFileController = TextEditingController();

  // モデルの種類 (デフォルト: realesr-animevideov3)
  String modelType = 'realesr-animevideov3';

  // 拡大率 (デフォルト: 4倍)
  String upscaleRatio = '4x';

  // 出力形式 (デフォルト: jpg (ただし入力ファイルの形式に合わせられる))
  String outputFormat = 'jpg';

  // 変換の進捗状況 (デフォルト: 0%)
  double progress = 0;

  void updateOutputFileName() {

    if (inputFile != null) {

      // 出力形式が入力ファイルと同じなら、拡張子には入力ファイルと同じものを使う
      var extension = outputFormat;
      if (extension == path.extension(inputFile!.path).toLowerCase().replaceAll('jpeg', 'jpg').replaceAll('.', '')) {
        extension = path.extension(inputFile!.path).replaceAll('.', '');
      }

      // 出力ファイルのパスを (入力画像のファイル名)-upscale-4x.jpg みたいなのに設定
      // 4x の部分は拡大率によって変わる
      // jpg の部分は出力形式によって変わる
      outputFileController.text = '${path.withoutExtension(inputFile!.path)}-upscale-${upscaleRatio}.${extension}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Container(
            margin: EdgeInsets.only(top: 32, left: 24, right: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: [
                    // Expanded で挟まないとエラーになる
                    Expanded(
                      child: TextField(
                        controller: inputFileController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: '入力ファイル',
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        child: Text('ファイルを選択', style: TextStyle(fontSize: 16)),
                        // ファイル選択ボタンが押されたとき
                        onPressed: () async {

                          // 選択を許可する拡張子の一覧
                          final imageTypeGroup = XTypeGroup(
                            label: 'images',
                            extensions: <String>['jpg', 'jpeg', 'png', 'webp'],
                          );

                          // ファイルピッカーを開き、選択されたファイルを格納
                          inputFile = await openFile(acceptedTypeGroups: <XTypeGroup>[imageTypeGroup]);

                          // もし入力ファイルが入っていれば、フォームにファイルパスを設定
                          if (inputFile != null) {
                            setState(() {

                              // 入力ファイルフォームのテキストを更新
                              inputFileController.text = inputFile!.path;

                              // 出力形式を入力ファイルの拡張子から取得
                              // 拡張子が .jpeg だった場合も jpg に統一する
                              outputFormat = path.extension(inputFile!.path).replaceAll('.', '').toLowerCase();
                              if (outputFormat == 'jpeg') outputFormat = 'jpg';

                              // 出力ファイルフォームのテキストを更新
                              updateOutputFileName();

                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 28),
                TextField(
                  controller: outputFileController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: '出力ファイル',
                  ),
                ),
                SizedBox(height: 28),
                Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text('利用モデル:', style: TextStyle(fontSize: 16))
                    ),
                    Expanded(
                      child: DropdownButtonFormField(
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                        value: modelType,
                        items: [
                          DropdownMenuItem(
                            value: 'realesr-animevideov3',
                            child: Text('realesr-animevideov3 (イラストやアニメ向け: 高速でおすすめ)'),
                          ),
                          DropdownMenuItem(
                            value: 'realesrgan-x4plus-anime',
                            child: Text('realesrgan-x4plus-anime (イラストやアニメ向け: ちょっと遅い)'),
                          ),
                          DropdownMenuItem(
                            value: 'realesrgan-x4plus',
                            child: Text('realesrgan-x4plus (汎用的なモデル)'),
                          ),
                        ],
                        onChanged: (String? value) {
                          setState(() {

                            // 利用モデルが変更されたらセット
                            modelType = value ?? 'realesr-animevideov3';

                          });
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 28),
                Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text('出力形式:', style: TextStyle(fontSize: 16))
                    ),
                    Expanded(
                      child: DropdownButtonFormField(
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                        value: upscaleRatio,
                        items: [
                          DropdownMenuItem(
                            value: '4x',
                            child: Text('4倍の解像度に拡大'),
                          ),
                          DropdownMenuItem(
                            value: '3x',
                            child: Text('3倍の解像度に拡大'),
                          ),
                          DropdownMenuItem(
                            value: '2x',
                            child: Text('2倍の解像度に拡大'),
                          ),
                        ],
                        onChanged: (String? value) {
                          setState(() {

                            // 拡大率が変更されたらセット
                            upscaleRatio = value ?? '4x';

                            // 出力ファイルフォームのテキストを更新
                            updateOutputFileName();
                          });
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 28),
                Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text('出力形式:', style: TextStyle(fontSize: 16))
                    ),
                    Expanded(
                      child: DropdownButtonFormField(
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                        value: outputFormat,
                        items: [
                          DropdownMenuItem(
                            value: 'jpg',
                            child: Text('JPEG 形式'),
                          ),
                          DropdownMenuItem(
                            value: 'png',
                            child: Text('PNG 形式'),
                          ),
                          DropdownMenuItem(
                            value: 'webp',
                            child: Text('WebP 形式'),
                          ),
                        ],
                        onChanged: (String? value) {
                          setState(() {

                            // 出力形式が変更されたらセット
                            outputFormat = value ?? 'jpg';

                            // 出力ファイルフォームのテキストを更新
                            updateOutputFileName();

                          });
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 28),
              ],
            ),
          ),
          Spacer(),
          Column(
            children: [
              Center(
                child: SizedBox(
                  width: 200,
                  height: 54,
                  child: ElevatedButton(
                    child: Text('拡大開始', style: TextStyle(fontSize: 20)),
                    // 拡大開始ボタンが押されたとき
                    onPressed: () async {

                      // バリデーション
                      if (inputFile == null) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: const Text('入力ファイルが指定されていません！'),
                          action: SnackBarAction(
                            label: '閉じる',
                            onPressed: () {
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            },
                          ),
                        ));
                        return;
                      }
                      if (outputFileController.text == '') {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: const Text('出力ファイルが指定されていません！'),
                          action: SnackBarAction(
                            label: '閉じる',
                            onPressed: () {
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            },
                          ),
                        ));
                        return;
                      }

                      // プログレスバーを一旦 0% に戻す
                      progress = 0;

                      // realesrgan-ncnn-vulkan コマンドを実行
                      // ref: https://api.dart.dev/stable/2.18.0/dart-io/Process-class.html
                      var process = await Process.start('C:/Applications/realesrgan-ncnn-vulkan/realesrgan-ncnn-vulkan.exe', [
                        // 入力ファイル
                        '-i', inputFile!.path,
                        // 出力ファイル
                        '-o', outputFileController.text,
                        // 利用モデル
                        '-n', modelType,
                        // 拡大率 (4x の x は除く)
                        '-s', upscaleRatio.replaceAll('x', ''),
                        // 出力形式
                        '-f', outputFormat,
                      ]);

                      // 標準エラー出力を受け取ったとき
                      process.stderr.transform(utf8.decoder).forEach((line) {

                        // 22.00% みたいな進捗ログを取得
                        var progressMatch = RegExp(r'([0-9]+\.[0-9]+)%').firstMatch(line);

                        // プログレスバーを更新 (進捗ログを取得できたときのみ)
                        if (progressMatch != null) {
                          setState(() {
                            progress = double.parse(progressMatch.group(1) ?? '0');
                          });
                        }
                      });

                      // プロセスの終了を待つ
                      var exitCode = await process.exitCode;

                      // プログレスバーを 100% に設定
                      progress = 100;

                      // 終了コードが0以外ならエラーを表示
                      if (exitCode != 0) {
                        progress = 0;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: const Text('画像の拡大に失敗しました…'),
                          action: SnackBarAction(
                            label: '閉じる',
                            onPressed: () {
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            },
                          ),
                        ));
                      }
                    },
                  ),
                ),
              ),
              SizedBox(height: 28),
              LinearProgressIndicator(
                value: progress / 100,  // 100 で割った (0~1 の範囲) 値を与える
                minHeight: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }
}