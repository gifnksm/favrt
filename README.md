favrt
=====

非公式 RT から元発言を探してきて公式 RT する

概要
----

最近多く登場してきている、非公式 RT を行う bot 群。
おもしろい発言を非公式 RT しているのですが、非公式 RT を公式 RT しても、
おもしろい発言をした人には伝わらず、ただ bot の被 RT 数が増加するだけで悔しい気分になってしまいます。

本プログラムはそんな状況を改善するためのものです。
TL 上に流れてくる非公式 RT 発言から元発言を自動的に検索し、
特定のアカウントで逐一公式 RT してくれます。
この公式 RT を行うアカウントをフォローしておけば、
非公式 RT をして悔しい思いをせずに済むのです！

宗教上の理由から非公式 RT できない方にもオススメです。

現在の状況
----------

+ 現在はバージョン 0.1 向け機能を実装しています
+ 以下はあくまでも予定なので、今後変更される可能性があります

### バージョン 0.1 向け機能 ###

+ __設定ファイルの読み込み、書き込み:__ ほぼ完了
+ __Twitter からの投稿取得:__ プロトタイプによる実験完了。実装は未着手
+ __favstar からの投稿取得:__ プロトタイプによる実験完了。実装は未着手
+ __Twitter への投稿:__ プロトタイプによる実験完了。実装は未着手

### 対応時期未定 ###

+ __bot 定義ファイルの追加による、任意 bot の追跡__
+ __デーモン化__
