# web_sample

[![Package Version](https://img.shields.io/hexpm/v/web_sample)](https://hex.pm/packages/web_sample)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/web_sample/)

```sh
gleam add web_sample@1
```

```gleam
import web_sample

pub fn main() -> Nil {
  // TODO: An example of the project in use
}
```

Further documentation can be found at <https://hexdocs.pm/web_sample>.

## Development

### 開発サーバーで起動（推奨）

```sh
gleam run -m lustre/dev start
```

ブラウザで http://localhost:1234 を開くと、ホットリロード対応でアプリが起動します。

### ビルドのみ

```sh
gleam run -m lustre/dev build
```

`dist/` ディレクトリに `index.html` と `web_sample.js` が生成されます。

### テスト実行

```sh
gleam test
```
