必要環境: iOS8以上

# - インストール - #


### Mac側

- App StoreでXcode7を検索してインストール
- [**ForestUpdater.zip**](https://github.com/f-tools/forest/releases/download/test_release/ForestUpdater.zip)を実行し、更新チェック -> ダウンロード -> Xcodeでプロジェクトを開くボタンを押す
- iOSデバイスをMacにつなぐ
- Xcode左上部でデバイスを選択(「iOS Device」等)
- Xcode左上部の音楽再生ボタンによく似た実行ボタンを押す (Apple ID の入力を求められる)

### iPhone側
- 設定 > 一般 > プロファイルから自分のApple IDのアプリの実行許可を行う(iOS9以降)


<br/>
<br/>
# - 開発 - #

### gitからビルド ###
```bash
git clone https://github.com/f-tools/forest.git
cd forest
pod install # (事前にCocoaPodsのインストールが必要)
# Forest.xcworkspaceをXcodeで開いてビルド
```


### 実装予定
* タブレットモードにタブ機能を追加

### 言語 (Objective-C / Swift)

Swiftを導入しようと試みたが、規模が大きくなるとビルド時間が問題になるようなので中止し、とりあえずObjective-Cで行くことにした。
ただしSwiftの開発状況によっては今後段階的にForestでもSwiftを取り入れることは考えたい。

### Gitブランチモデル

GitHub Flowに公開用のreleaseブランチを加えた形、 [GitLab Flow](http://postd.cc/gitlab-flow/) に近いモデル
\[feature/XXXX, master, release\]

コミットメッセージを日本語で書く。特に機能の追加時には。簡単なものや面倒な時は英語でもOK。

開発ドキュメントがほとんどないが、少しずつ書いていく予定。
