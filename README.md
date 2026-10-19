<p align="right"><a href="README.en.md">🇺🇸 English</a> | <b>🇯🇵 日本語</b></p>

<h1 align="center">
  <img src="shell/assets/branding/mugen-shell_logo.png" width="200" alt="mugen-shell logo" /><br/>
  mugen-shell
</h1>

<p align="center"><i>Quickshell + Hyprland で組んだ、夢幻シェル。</i></p>


https://github.com/user-attachments/assets/bb69bbe1-e069-4ca7-a48d-6ac7036e9d77


Hyprland + Quickshell デスクトップ向けの私の dotfiles を、Arch のパッケージと Nix flake で入れられる形にまとめたものです。

---

## 機能

- **アプリランチャー**: ジャンルとお気に入り、自分で作るグループ
- **カレンダー**: 予定の時刻に通知
- **タイマー**: 残り時間をバーに表示
- **天気**: API キー不要、場所は自動
- **音楽**: 再生中の曲の操作とアルバムアート
- **クリップボード**: 画像も残る履歴を検索
- **通知**: おやすみモード、クリックで送り元のアプリへ
- **スクリーンショット**: 範囲・ウィンドウ・全画面と、撮った画像の一覧
- **壁紙と配色**: 画像と動画の壁紙、スライドショー、その色をアプリにも
- **ライト / ダーク**: GTK アプリも一緒に切り替え
- **ロック画面**: 時計や天気と、キー入力で動くアニメーション
- **システム操作**: 音、明るさ、WiFi、Bluetooth、IME など
- **キーボード操作**: キーバインドでパネルを開いて操作できる
- **カスタマイズ**: バーの色や形、透明度、アニメーションの速さなどを設定画面から変えられる
- **Yura**: バーやチャットパネルから話しかけられる AI アシスタント

それぞれの詳しい説明は [FEATURES.md](FEATURES.md) にあります。

---

## Yura

デスクトップのちょっとした手伝いをするアシスタントです。音量やタイマー、予定の確認など、mugen-shell の操作を頼めます。バーの入力欄と、チャットパネルから使えます。

- モデル: Ollama のローカルモデル、Claude、Gemini、OpenAI 互換 API
- デスクトップの操作: 「音量 30 にして」「5 分タイマー計って」で、音量が変わり、タイマーが動き出します
- 外部の MCP サーバに対応しています。外部ツールの書き込みは、既定では実行前に確認します

設定は [SETUP.md](SETUP.md#mugen-ai-の設定) にまとめました。

---

## インストール

手順は [SETUP.md](SETUP.md) にあります。

インストールせずに試すにはデモ VM を使います。ユーザー名とパスワードはどちらも `mugen` です (ロック解除も同じパスワード)。

```sh
nix build "github:tmy7533018/mugen-shell#nixosConfigurations.vm.config.system.build.vm" && ./result/bin/run-mugen-vm-vm
```

---

## クレジット

mugen-shell は [Hyprland](https://hypr.land/) と [Quickshell](https://quickshell.org/) をはじめ、多くのプロジェクトの上に成り立っています。全リストは [SETUP.md → クレジット](SETUP.md#クレジット) にあります。

---

## ライセンス

MIT License
