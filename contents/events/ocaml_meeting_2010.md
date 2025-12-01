---
page_title: OCaml Meeting 2010 in Nagoya
---

![around](http://ocaml.jp/?plugin=ref&page=um2010&src=a4.png)

↑special thanks to camlspotter!

（このイベントは終了致しました。発表資料や動画が置いてありますので、ご参照ください。ご参加頂いた皆様、ありがとうございました。）

OCamlのさらなる普及とユーザー間の幅広い交流を目指して、好評を博した昨年に引き続き、今年も OCaml Meeting 2010 を開催したいと思います。

OCamlの特徴は、なんといっても強力な静的型システムにあります。型安全性を保ちながら、構造的な部分型への変換、多相バリアント、再帰モジュールといった柔軟な設計とプログラミングを実現できる仕組みを持っている言語は類がありません。加えて、定理証明支援器Coqとの連携による高信頼化、多くのCPUアーキテクチャに対応した高速なネイティブコードを出力できるコンパイラ、C言語へのバインディングによる過去資産の継承など、実用的な機能も兼ね備えています。このようなOCamlの特徴と、それらがフランスINRIA国立研究所によって安定して提供されているという運用体制は、ソフトウェアの不具合を減らし、社会インフラとしてのコンピューターシステムの品質を向上させるものと信じています。

嬉しいことに、近年関数型言語が話題になってくると共にOCamlも注目を集めています。OCamlをベースに開発されたMicrosoft F#も4月にリリースされ、システム開発の現場においても再認識がなされています。6月には第一級のモジュール機能など多くの新機能が実装されたVersion3.12のリリースも予定されています。このような話題豊富な流れの中で、今年はOCamlの主要開発者の一人、Jacques Garrigue 氏にご協力を頂けることになり、氏の活動拠点でもある名古屋での開催を決定しました。地理的に日本の中央に位置するこの場所で、OCamlホビーユーザーからプログラマ・研究者に至るまで、より幅広い交流を目指していきたいと考えています。（小笠原）

### 日時・場所

* 日程：2010/08/28(土)
* 会場：名古屋大学　多元数理科学研究科　理1号館 509号室
* 交通アクセス：[http://www.math.nagoya-u.ac.jp/ja/direction/campus.html](http://www.math.nagoya-u.ac.jp/ja/direction/campus.html)

### プログラム(現時点での予定です)

* 9:30 開場
* 9:50 オープニング挨拶とプログラムのご案内
* 10:00 やってみようOCaml / Walk with OCaml
    * 今井 宜洋(有限会社ITプランニング)
    * [発表資料(SlideShare)](http://www.slideshare.net/yoshihiro503/ocamlmeeting2010)
* 10:35 Break
* 10:45 F# の流技 / Fluent Feature in F#
    * いげ太
    * [発表資料(SlideShare)](http://www.slideshare.net/igeta/fluent-featureinfsharpom2010)
* 11:20 OCaml 3.12における第一級モジュールと合成可能なシグネチャについて / First-class modules and composable signatures in OCaml 3.12
    * Jacques Garrigue(名古屋大学)
    * [発表資料(PDF)](http://www.math.nagoya-u.ac.jp/~garrigue/papers/ocamlum2010.pdf)
* 11:55 Lunch break
    * 昼食は各自周辺でおとり下さい。[周辺ランチ情報](http://maps.google.co.jp/maps/ms?gl=jp&hl=ja&brcurrent=3,0x6003700811fdc32b:0xedafba947ba12fc,0&ie=UTF8&msa=33&msid=115812227863470895801.00048bcd2861befe0a0f0&abauth=4c47e17aF97PoY4-YkDByYP6kdP4X-CO9f0)
* 13:30 デザインレシピ、モジュール、抽象データ型 / Design Recipe, module, and abstract data type
    * 浅井 健一(お茶の水女子大学)
* 14:05 Spot Your White Caml -- How to Make Yourself Happy in OCaml Projects
    * 古瀬 淳
    * [発表資料(SlideShare)](http://www.slideshare.net/camlspotter/um2010)
* 14:40 Break
* 15:00 OCaml でプログラミングコンテスト / Programming Contest in OCaml
    * 川中 真耶 a.k.a. mayah(東京大学)
    * [発表資料](http://mayah.jp/scratchleaf/2010/ocaml-user-meeting-in-nagoya-2010)
* 15:35 Break
* 15:50 Lightning Sessions
    * FFTW/genfft誰得ハッキングガイド / The Hitchhacker's Guide to the FFTW/genfft
        * 桜庭 俊(京都大学)
        * [発表資料(SlideShare)](http://www.slideshare.net/chunjp/fftw)
    * OCaml版Hoogle、OCamlAPISearchの紹介
        * mzp(ocaml-nagoya)
    * どーOCaml
        * 小笠原 啓(有限会社ITプランニング)
    * ゴルフ用楽打モジュール
        * 中野 圭介(電気通信大学)
* 16:30 Golfコンテスト結果発表と表彰
* 16:45 終了挨拶
* 16:55 終了

### OCaml Golf Competition

中野さん/浜地さんのご協力のにより、今年もGolf Competitionを開催致します！

```text
===== 問題 (Problem) =====
入力の各行に含まれる単語を，長さが短い順に列べよ．ただし，長さが同じ単語については
ASCII 文字列としての大小を比較するものとする．
For given words in the input, sort them by their length in increasing
order. For words of the same length, sort them as ASCII strings.
```

```text
たとえば，入力が
OCaml
Meeting
2010
in
Nagoya
なら，出力は
in
2010
OCaml
Nagoya
Meeting
となる．
```

* 回答はこちら → [http://golf.shinh.org/p.rb?Sort+by+Length+for+OCaml+Golf+Competition](http://golf.shinh.org/p.rb?Sort+by+Length+for+OCaml+Golf+Competition)
* OCaml Meeting ですので OCaml で考えてください。
* 優勝者にはささやかな賞品を用意しております。お楽しみに！
* 去年の中野さんのGolfに関する発表資料を見ればかなり有利になると思われます。
* Meeting 当日も開始時に問題を紹介します。

* 今年の優勝者はtanakhさん！おめでとうございます！
* 賞品は、UAE輸入、らくだのミルクで作られたチョコレートでした。

### どーOCaml

OCamlでファイルを扱うには？文字列処理は？そんなFAQ的な疑問にお答えするため、4つのお題とそれらへの回答を掲載できるサイトを用意しました。OCamlビギナーは回答を見てぜひ参考にしてみてください。エキスパートの方は、模範回答へのご協力をお願いします！Let's どーOCaml！

* [http://ocaml.jp/cgi/docaml/docaml.cgi](http://ocaml.jp/cgi/docaml/docaml.cgi)

### ライトニングトーク募集中!!

ライントニングトークをしていただける人を募集します!
一人お話5分+質問タイム2分。
OCaml に関係あれば開発からグループ紹介まで基本的に何でも歓迎です。
希望の方は以下のアドレスまでご連絡ください。

```ocaml
# String.concat "." ["ogasawara@itpl"; "co"; "jp";];;
```

### 参加方法

参加人数を把握させて頂く為にイベント開催支援ツール：ATND（アテンド）にて参加をご表明下さい。参加は無料です。

* URLは→[http://atnd.org/events/4873](http://atnd.org/events/4873)

### 名大周辺ランチ情報

名大周辺か地下鉄で一駅の本山まで出ると色々あります。

* Google Mapに[めぼしい店](http://maps.google.co.jp/maps/ms?gl=jp&hl=ja&brcurrent=3,0x6003700811fdc32b:0xedafba947ba12fc,0&ie=UTF8&msa=33&msid=115812227863470895801.00048bcd2861befe0a0f0&abauth=4c47e17aF97PoY4-YkDByYP6kdP4X-CO9f0)をメモっておきました。

### 懇親会

手羽先もおいしい[釜飯と串焼き とりでん 四谷通り店](http://r.gnavi.co.jp/n245534/)を予定しています。

* 場所 [釜飯と串焼き とりでん 四谷通り店](http://r.gnavi.co.jp/n245534/)
* 日時 8/28 18:00から2時間
* 予算は3000円～4000円(コース)

参加を希望される方は、ATND（アテンド）にて参加をご表明下さい。

* URLは→[http://atnd.org/events/7009](http://atnd.org/events/7009)

### 会場の電源・ネットワークについて

* 延長コードを出来る限り配備してコンセントを増やしておきますが、それでも相当足りない事が予想されます。譲り合って使って頂けると幸いです。
* 大学の無線LANは動画配信で重くなると思われますので、当日希望された方にのみ接続情報をお知らせします。可能な方はモバイル回線の持参をお願い致します。

その他、ご意見・連絡事項などありましたら、`# String.concat "." ["ogasawara@itpl"; "co"; "jp"];;` までご連絡下さい。

### アンケート集計結果

[um2010/アンケート等結果](http://ocaml.jp/?um2010/%E3%82%A2%E3%83%B3%E3%82%B1%E3%83%BC%E3%83%88%E7%AD%89%E7%B5%90%E6%9E%9C)