# CCTweaked Fennel Landfill

エンダータートル用自動埋め立て・整地システム

## 使い方

### 超シンプル版（推奨・上昇禁止）
```bash
# CCTweaked内で
wget https://raw.githubusercontent.com/O6lvl4/cctweaked-fennel-landfill/main/landfill.lua
landfill
```

### Fennelファイル実行
```bash
# CCTweaked内で（Fennelが必要）
wget https://raw.githubusercontent.com/O6lvl4/cctweaked-fennel-landfill/main/landfill.fnl
fennel landfill.fnl
```

## 仕様

### 超シンプル版
- 範囲: 5x5ブロック（テスト用）
- y=63から開始、絶対に上昇しない
- y=63の下にブロックがある列はスキップ
- y=62から下向きに土で埋め立て
- エンダーチェストから自動土補給