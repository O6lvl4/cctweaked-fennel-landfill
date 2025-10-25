;; エンダータートル用自動整地システム
;; 指定範囲をy63フラットに整地し、y62以下は土で埋め立て

;; 定数定義
(local TARGET-Y 63)
(local FILL-Y 62)
(local AREA {:min-x -1786 :max-x -1286 :min-z -641 :max-z -141})

;; 現在位置取得
(fn get-position []
  (let [(x y z) (gps.locate)]
    {:x x :y y :z z}))

;; 安全な移動関数
(fn safe-move [direction]
  (var attempts 0)
  (while (and (< attempts 10) (not (direction)))
    (set attempts (+ attempts 1))
    (os.sleep 0.1))
  (> attempts 0))

;; エンダータートル用テレポート移動
(fn teleport-to [x y z]
  (if (turtle.teleport x y z)
      true
      (do
        (print (.. "テレポート失敗: " x " " y " " z))
        false)))

;; ブロック検知関数
(fn detect-block [direction]
  (match direction
    :up (turtle.detectUp)
    :down (turtle.detectDown)
    :front (turtle.detect)))

;; ブロック配置関数
(fn place-block [direction]
  (match direction
    :up (turtle.placeUp)
    :down (turtle.placeDown)
    :front (turtle.place)))

;; ブロック採掘関数
(fn dig-block [direction]
  (match direction
    :up (turtle.digUp)
    :down (turtle.digDown)
    :front (turtle.dig)))

;; エンダーチェストから土ブロック補給
(fn refill-dirt []
  (print "土ブロックを補給中...")
  ;; エンダーチェストを設置
  (turtle.select 1)
  (turtle.placeUp)
  
  ;; エンダーチェストを開いて土を取得
  (for [slot 2 16]
    (turtle.select slot)
    (if (> (turtle.getItemCount) 0)
        (turtle.dropUp 64))  ;; 余分なアイテムを預ける
    (turtle.suckUp 64))     ;; 土を取得
  
  ;; エンダーチェストを回収
  (turtle.select 1)
  (turtle.digUp)
  (print "補給完了"))

;; インベントリに土があるかチェック
(fn has-dirt []
  (for [slot 2 16]
    (turtle.select slot)
    (let [item (turtle.getItemDetail)]
      (if (and item (or (item.name:find "dirt") (item.name:find "土")))
          (lua "return true"))))
  false)

;; 土ブロックを選択
(fn select-dirt []
  (for [slot 2 16]
    (turtle.select slot)
    (let [item (turtle.getItemDetail)]
      (if (and item (or (item.name:find "dirt") (item.name:find "土")))
          (lua "return true"))))
  false)

;; 指定座標の列処理
(fn process-column [x z]
  (print (.. "列処理開始: x=" x " z=" z))
  
  ;; y63の位置にテレポート
  (if (not (teleport-to x TARGET-Y z))
      (do
        (print "テレポート失敗、列をスキップ")
        (lua "return false")))
  
  ;; y63にブロックがあるかチェック
  (if (detect-block :down)
      (do
        (print (.. "y63にブロック発見 (" x "," TARGET-Y "," z ")、列をスキップ"))
        (lua "return false")))
  
  ;; y62から下に向かって処理
  (for [y FILL-Y 1 -1]
    (teleport-to x y z)
    
    ;; 現在位置にブロックがない場合は土を配置
    (if (not (detect-block :down))
        (do
          ;; 土が不足している場合は補給
          (if (not (has-dirt))
              (refill-dirt))
          
          ;; 土を選択して配置
          (if (select-dirt)
              (if (not (place-block :down))
                  (print (.. "配置失敗: " x " " y " " z)))
              (print "土ブロックが見つかりません"))))
    
    (os.sleep 0.05))  ;; 少し待機
  
  true)

;; Y63上のブロッククリア（必要に応じて）
(fn clear-above-y63 [x z]
  (teleport-to x (+ TARGET-Y 1) z)
  (var current-y (+ TARGET-Y 1))
  
  ;; 上方向のブロックを確認・除去
  (while (and (< current-y 320) (detect-block :down))
    (dig-block :down)
    (set current-y (+ current-y 1))
    (teleport-to x current-y z)
    (os.sleep 0.05)))

;; メイン整地ループ
(fn main-leveling []
  (print "=== エンダータートル整地システム開始 ===")
  (print (.. "範囲: x=" AREA.min-x "~" AREA.max-x " z=" AREA.min-z "~" AREA.max-z))
  
  ;; 初期補給
  (refill-dirt)
  
  (var processed-columns 0)
  (var skipped-columns 0)
  
  ;; X軸方向にループ
  (for [x AREA.min-x AREA.max-x]
    (print (.. "X=" x " の処理開始 (" (+ (- x AREA.min-x) 1) "/" (+ (- AREA.max-x AREA.min-x) 1) ")"))
    
    ;; Z軸方向にループ
    (for [z AREA.min-z AREA.max-z]
      ;; Y63上のクリア（オプション）
      ;; (clear-above-y63 x z)
      
      ;; 列処理
      (if (process-column x z)
          (set processed-columns (+ processed-columns 1))
          (set skipped-columns (+ skipped-columns 1)))
      
      ;; 100列ごとに進捗表示
      (if (= (% (+ processed-columns skipped-columns) 100) 0)
          (do
            (print (.. "進捗: 処理済み=" processed-columns " スキップ=" skipped-columns))
            (refill-dirt))))  ;; 定期的に補給
    
    (print (.. "X=" x " 完了")))
  
  (print "=== 整地完了 ===")
  (print (.. "処理した列: " processed-columns))
  (print (.. "スキップした列: " skipped-columns))
  (print (.. "合計: " (+ processed-columns skipped-columns))))

;; 緊急停止機能
(fn emergency-stop []
  (print "緊急停止 - 現在位置に留まります")
  (let [pos (get-position)]
    (print (.. "現在位置: " pos.x " " pos.y " " pos.z))))

;; 実行開始
(print "エンダータートル整地システム")
(print "Ctrl+T で緊急停止")
(print "5秒後に開始...")
(os.sleep 5)

;; メイン実行
(xpcall main-leveling
        (fn [err] 
          (print (.. "エラー発生: " err))
          (emergency-stop)))