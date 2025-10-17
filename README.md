# 💻 CodeBeam — beam your code from iPhone to PC

![PowerShell](https://img.shields.io/badge/PowerShell-7+-blue?logo=powershell)
![iOS Shortcut](https://img.shields.io/badge/iOS-Shortcut-lightgrey?logo=apple)
![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)

**CodeBeam** は、iPhoneの共有シートからワンタップで  
Windows PC にコードやテキストを直接書き込むためのツールです。  

ChatGPTで生成したコードをコピーせずに即反映。  
サーバーもクラウドも不要。LAN内で完結する、最小限で安全なリモート開発環境。

---

## 🚀 機能
- iOSショートカットからSSH経由で PowerShell スクリプトを実行  
- 指定フォルダ（$Root配下）だけに安全にファイル操作  
- `mkdir` / `create` / `delete` / `write` / `append` をサポート  
- 上書き時は自動バックアップ `.bak_YYYYMMDD-HHMMSS`  
- ログ出力・ドライラン・拡張子ホワイトリスト機能あり  

---

## 📦 インストール

### 1️⃣ クローン
```bash
git clone https://github.com/yourname/codebeam.git
cd codebeam
```

### 2️⃣ スクリプト配置
`safe_ops.ps1` を PC に配置（例: `C:\code_drop\safe_ops.ps1`）。  
必要に応じて `$Root` を自分のプロジェクトの絶対パスに変更。

### 3️⃣ PowerShell 実行ポリシーを解除（初回のみ）
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

## ⚙️ Windows設定

### OpenSSH Serverを有効化
- 設定 → アプリ → オプション機能 → 「OpenSSH サーバー」を追加  
- サービス → **OpenSSH SSH Server** を起動＆自動起動に設定  

### IPアドレス確認
```bash
ipconfig
```
→ IPv4 アドレスをメモ（例: `192.168.1.23`）

---

## 🧠 使用例（PC側）

```bash
# ディレクトリ作成
powershell -File safe_ops.ps1 mkdir "notes"

# ファイル新規作成
powershell -File safe_ops.ps1 create "notes/test.txt"

# 内容を書き込み（上書き）
echo "Hello" | powershell -File safe_ops.ps1 write "notes/test.txt" overwrite -Backup

# 内容を追記
echo " World" | powershell -File safe_ops.ps1 write "notes/test.txt" append

# 削除
powershell -File safe_ops.ps1 delete "notes/test.txt"
```

## 🧪 動作例
1. ChatGPTでコード生成  
2. 「共有」→「Send Code to PC」  
3. 保存パス入力→`overwrite`選択  
4. 数秒後にPCのフォルダに反映  
5. iPhone通知「wrote: src/pages/index.tsx」

---

## 🔐 セキュリティ
- `$Root` 外は操作不可（トラバーサル防止）  
- 許可拡張子のみ書き込み  
- SSH鍵認証推奨  
- `ForceCommand` + 専用ユーザーでコマンド制限可  
- LAN内使用を推奨（ポート開放不要）

---

## 🤝 Contributing
PR・Issue歓迎です。  
安全性改善、Rust常駐版、Mac/Linux対応など提案ください。

---

## ⚠️ Disclaimer
CodeBeamはローカルLAN内での利用を前提としています。  
外部ネットワーク経由での使用、ポート開放、企業PC環境での利用は**自己責任**でお願いします。

---

## 📄 ライセンス
MIT License © 2025 CodeBeam Project

---

## 🗓️ 今後の展開
- Rust常駐版（クロスプラットフォームCLI）  
- Git連携モード（自動commit & push）  
- WebSocket通信による常駐サーバーモード  

---

**Beam your code. Instantly. Safely. Locally.**
