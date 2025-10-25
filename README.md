# CCTweaked Fennel Landfill

エンダータートル用自動埋め立て・整地システム

## 使い方

### Luaファイル直接実行（推奨）
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

- 範囲: (-1786,-141) から (-1286,-641)
- y63をフラット化、y62以下を土で埋め立て
- y63にブロックがある列はスキップ
- エンダーチェストから自動土補給