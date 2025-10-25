# CCTweaked Enderturtle Leveling

エンダータートル用自動整地システム

## 使い方

```bash
# CCTweaked内で
wget https://raw.githubusercontent.com/[username]/enderturtle-leveling/main/enderturtle-leveling.fnl
fennel enderturtle-leveling.fnl
```

## 仕様

- 範囲: (-1786,-141) から (-1286,-641)
- y63をフラット化、y62以下を土で埋め立て
- y63にブロックがある列はスキップ
- エンダーチェストから自動土補給