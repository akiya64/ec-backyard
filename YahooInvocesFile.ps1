#CSVファイルとしてUpdateFileを出力する関数
function OutPut-Csv ($Orders){

$OutputFolder = $HOME + "\Desktop\ヤフー\"
$TodayDate = Get-Date -Format "MMdd"

    If (Test-Path $OutputFolder) {

        $OutputFullPath = $OutputFolder + "ヤフー送り状番号一括" + $TodayDate + ".csv"

    }else{
        $OutputFolder = $OutputFolder -replace "ヤフー*"
        $OutputFullPath = $OutputFolder + "ヤフー送り状番号一括" + $TodayDate + ".csv"
    }

    $Orders | Export-Csv $OutputFullPath -Encoding Default -NoTypeInformation
    
    #ホームへ戻って、終了メッセージを表示
    Set-Location $HOME

    $CompleteMessage = "合計" + $Orders.Count.Tostring() + "件 処理しました。`n`nファイル生成完了。ウィンドウを閉じてください。"
    echo $CompleteMessage
}

#メイン処理

echo "ヤフーへの一括アップロード用CSVファイルを生成します。`n"

#本日の送り状番号を格納する配列を用意
$UpdateOrders = New-Object System.Collections.ArrayList

#佐川の送り状番号ダンプCSVの読込
#佐川の送り状システムのファイル出力先フォルダへ移動、ローカルでなく何故か社内サーバ
Set-Location "\\Server02\商品部\ネット販売関連\出荷通知\出荷通知_楽天" 

#送り状システムのダンプするデータにはヘッダーがないためWPSで処理できない。ヘッダー用の文字列配列を定義
$Header = "受注日","受注受付日","発送日","何かの番号","送り状番号","受注番号","空列1","注文者郵便場号","注文者住所","空列2","注文者電話番号","注文者名","受注番号-2","空列3","届け先郵便番号","届け先住所１","空列4","届け先電話番号","届け先名","送り状種別番号","送り状","明細番号","処理状況","商品コード","商品名","単価","数量","小計","空列5","空列6","注文番号"

#ヤフーの注文番号フォーマットで送り状番号の入っている注文を抽出
$SagawaInvoices = Get-Content .\出荷一覧詳細.csv
$SagawaYahooInvoices = $SagawaInvoices | ConvertFrom-Csv -Header $Header | where {$_.注文番号 -like "100*" -and $_.送り状番号 -ne ""} | sort 送り状番号 -Unique | Select-Object 注文番号,送り状番号,発送日

#YahooInvoicesをイテレートして、UpdateOrdersに追記

$SagawaYahooInvoices | ForEach {

    #CSV 1行に相当する配列を用意
    $Order = New-Object PSObject | Select-Object OrderId,ShipMethod,ShipInvoiceNumber1,ShipDate,ShipStatus

    $Order.OrderId = $_.注文番号
    $Order.ShipMethod = "postage1"
    $Order.ShipInvoiceNumber1 = $_.送り状番号
    $Order.ShipDate = $_.発送日
    $Order.ShipStatus = "2"
    
    echo $_.注文番号 $_.送り状番号
    
    [void]$UpdateOrders.add($Order)
}
$SagawaCount = "佐川急便：" + ($SagawaYahooInvoices | Measure-Object).Count.Tostring() + "件`n"
Echo $SagawaCount

#ゆうパケ読込 フォルダが開けなければ、ここでCSV出力して終了

try{
    Set-Location "\\YAMATOSYS\Users\yamatosys\Desktop\ゆうパケット"
}
catch{

    $UpdateOrders
    echo "ゆうパケファイルが開けませんでした。`n佐川送り状番号のみでファイルを作成しました。"
    exit
}

#ヤフーの注文番号フォーマットで送り状番号の入っている注文を抽出
$YupakeInvoices = Get-Content .\ゆうパケット問い合わせ番号.csv

# フリー項目０３=注文番号 フリー項目０４＝モール識別記号
$YupakeYahooInvoices = $YupakeInvoices | ConvertFrom-Csv | where {$_.フリー項目０３ -like "100*" -and $_.フリー項目０４ -eq "Y"} | sort お問い合わせ番号 -Unique | Select-Object フリー項目０３,お問い合わせ番号

# ゆうパケで取得した件数が1未満 ＝ ゆうパケ発送がなければ、ここでCSV出力
if (($YupakeYahooInvoices | Measure-Object).count -lt 1 ){
    OutPut-Csv $UpdateOrders
    exit
}

#YupakeYahooInvoicesをイテレートして、UpdateOrdersに追記

$YupakeYahooInvoices | ForEach {

    #CSV 1行に相当するオブジェクトを用意
    $Order = New-Object PSObject | Select-Object OrderId,ShipMethod,ShipInvoiceNumber1,ShipDate,ShipStatus

    $Order.OrderId = $_.フリー項目０３
    $Order.ShipMethod = "postage3"
    $Order.ShipInvoiceNumber1 = $_.お問い合わせ番号
    $Order.ShipDate = Get-Date -Format "yyyy/MM/dd"
    $Order.ShipStatus = "2"
    
    echo $_.フリー項目０３ $_.お問い合わせ番号
    
    [void]$UpdateOrders.add($Order)
}
$YupakeCount = "ゆうパケット：" + ($YupakeYahooInvoices | Measure-Object).Count.Tostring() + "件`n"
Echo $YupakeCount

# 佐川・ゆうパケ 両方有りのCSV出力
OutPut-Csv $UpdateOrders