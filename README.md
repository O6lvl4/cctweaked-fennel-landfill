# CCTweaked Fennel Landfill

エンダータートル用自動埋め立て・整地システム

## 使い方

### 相対移動版（推奨・GPSなし）
```bash
# CCTweaked内で
wget https://raw.githubusercontent.com/O6lvl4/cctweaked-fennel-landfill/main/landfill_relative.lua
landfill_relative
```

### GPS版（GPSサーバー設置必要）
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

### 相対移動版
- 範囲: 500x500ブロック（開始位置から）
- GPSサーバー不要
- y63をフラット化、y62以下を土で埋め立て
- y63にブロックがある列はスキップ
- エンダーチェストから自動土補給

### GPS版
- 範囲: (-1786,-141) から (-1286,-641)
- GPSサーバー4台が必要
- 座標指定での正確な移動