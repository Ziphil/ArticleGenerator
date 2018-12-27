<div align="center">
<h1>Article Generator (仮称)</h1>
</div>

## 概要
Article Generator (仮称) は、インタラクティブな数学書を原稿データから生成する Ruby 製スクリプトです。
定義や定理などを断片的に記述しておくと、それぞれの断片を依存関係に応じて適切な順番に並べ替え、HTML 形式の数学書を生成します。

## デモ
このリポジトリ内に含まれるサンプルデータを HTML に変換したものを公開しています。

- [デモページ](https://ziphil.github.io/ArticleGeneratorDemo/index.html)

## 利用方法
### ライブラリの準備
HTML の生成スクリプトは Ruby で書かれているので、実行するにはバージョン 2.4.0 以降の Ruby が必要です。
また、以下の gem を使用しているので、あらかじめインストールしておく必要があります。

- [Kramdown](https://kramdown.gettalong.org/)

さらに、生成された HTML を正しく表示するには、以下のライブラリをあらかじめダウンロードしておく必要があります。

- [MathJax](https://www.mathjax.org/)
- [vis.js](http://visjs.org/)
- [jQuery](https://jquery.com/)

### 原稿データの用意
定義, 定理 (命題や補題などの定理に類するものを含む), 定理の証明のそれぞれごとに 1 つのファイルを用意します。
各ファイルには MarkDown 形式で原稿を記述して、拡張子を `.mdz` にして保存してください。
標準的な MarkDown 記法に加え、`$` もしくは `$$` で囲むことで LaTeX 形式の数式を記述できます。
`$` で囲まれた部分はインライン数式となり、`$$` で囲まれた部分は別行立て数式になります。

各原稿ファイルの最初の行には、そのファイルがどのような種類であるかを指定するヘッダーを書く必要があります。
ヘッダーは以下の形式です。

| 種類 | ヘッダー |
|:----:|:--------:|
| 定義 | `%DEF` or `%DEF: 定義の名前` |
| 定理 | `%THM` or `%THM: 定理の名前` |
| 命題 | `%PROP` or `%PROP: 命題の名前` |
| 補題 | `%LEM` or `%LEM: 補題の名前` |
| 系 | `%COR` or `%COR: 系の名前` |
| 補足 | `%SUPP` |
| 証明 | `%PROOF<定理などのファイル名>` |

補足と証明以外は、種類を表す英大文字の直後に `?` を挿入することで、生成される HTML に初期状態では表示されなくなります。
このようなファイルの内容は、ポップアップでのみ表示されます。

原稿の中に `[リンクテキスト]<参照先ファイル名>` と記述すると、生成される HTML では、ポップアップを表示するリンクに変換されます。
このリンクをクリックすると、参照先ファイルの内容がその場にポップアップとして表示されます。
また、生成される HTML での原稿データの並び順は、各ファイルに含まれる参照先ファイルよりも後にそのファイルが表示されるようになります。
参照先が循環している場合は、エラーが発生します。

### HTML の生成
以下のコードで HTML を生成できます。

```ruby
source_directory = "foo/bar/source"
output_directory = "foo/bar/out"
option = {
  :mathjax_directory => "mathjax",
  :vis_directory => "vis",
  :jquery_path => "jquery/jquery.js"
}
manager = ArticleFileManager.new(source_directory, output_directory, option)
manager.convert
```

第 3 引数の `option` には、生成の際のオプションデータを格納したハッシュテーブルを渡します。
以下のキーが有効です。

| キー | 意味 |
|:----:|:----:|
| `mathjax_directory` | MathJax のディレクトリ |
| `vis_directory` | vis.js のディレクトリ |
| `jquery_path` | jQuery のパス |
| `comprehensive` | `true` にすると `?` が付いたファイルも最初から表示 |
| `show_name` | `true` にすると出力結果に原稿ファイル名を表示 |