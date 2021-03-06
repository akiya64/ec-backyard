Attribute VB_Name = "Module1"
Option Explicit

Const MAKER_QTY_PATH As String = "\\server02\商品部\ネット販売関連\z在庫\ロゴスメーカー在庫表.csv"
Const SAVE_FOLDER As String = "\\server02\商品部\ネット販売関連\発注関連\手配書作成\" '最後必ず\マーク

'PickingSheetNames(2)の並びと同じ、手配依頼商品数カウンタ
Dim ItemCount(2) As Integer

Sub ロゴス手配リスト作成()

'マクロ起動ボタン削除、再抽出ボタン削除
ActiveSheet.Shapes("ButtonExtractLogos").Delete

'シートに本日日付を入れる
Worksheets("ロゴス本日分").Range("A1").Value = Format(Date, "m月d日")

'各ピッキングシートをコピーして、ロゴス手配でマークされている商品をコピー

'モール名、ピッキングシート呼び出しとシート名に使う文字列 配列
Dim PickingSheetNames(2) As String
PickingSheetNames(0) = "Amazon"
PickingSheetNames(1) = "楽天"
PickingSheetNames(2) = "Yahoo"

Dim PickingSheetName As Variant

For Each PickingSheetName In PickingSheetNames
    
    Dim Name As String
    
    '反復子がVariant型（VBAの仕様）なのでCopySheet関数へ渡せるストリング型にキャスト
    Name = CStr(PickingSheetName)
    
    On Error Resume Next
        
        Call CopySheet(Name)
        Call ExtractLogosItems(Name)
    
        If Err Then
        
            MsgBox Prompt:=Name & " 棚無しピッキングシート無し、処理を続行します。"
        
        End If
    
    On Error GoTo 0
continue:

Next

'最後にコピーしたシートがActiveなので本日分シートに戻る
Worksheets("ロゴス本日分").Activate


'ロゴス手配品の有無を確認
If ActiveSheet.UsedRange.Rows.Count = 1 Then

    MsgBox Prompt:="ロゴス ピッキングシートでの手配依頼商品は０点です。" & vbLf & "アップロード用ファイルは生成されません。"
    Exit Sub

Else
    MsgBox Prompt:="ロゴス手配依頼 抽出完了" & vbLf & _
                "Amazon分：" & ItemCount(0) & "点" & vbLf & _
                "楽天分：" & ItemCount(1) & "点" & vbLf & _
                "ヤフー分：" & ItemCount(2) & "点"

End If

'品番、メーカー在庫を引っ張るVlookup式を入れる
Call InsertVlookup

With ActiveSheet
    
    .UsedRange.Columns.AutoFit
    .Columns("C").ColumnWidth = 50
   
End With

'再抽出ボタン、CSV再保存ボタンを配置
'CSV再保存ボタン配置
With ActiveSheet.Buttons.Add( _
        Range("H3").Left, _
        Range("H3").Top, _
        Range("H3:I4").Width, _
        Range("H3:I4").Height _
        )
    .OnAction = "B2B用CSV保存"
    .Characters.Text = "B2B用CSV 再保存"
End With

'Server02の手配書作成フォルダにxlsx形式で保存
Application.DisplayAlerts = False
ThisWorkbook.SaveAs FileName:=SAVE_FOLDER & "ロゴス" & Format(Date, "mmdd") & ".xlsx"

ThisWorkbook.Worksheets("ロゴス本日分").Activate

'品番が取得できていない商品があればCSV生成を一旦保留、ボタンで手動生成とする
If HasProductCode Then

    Call B2B用CSV保存
    MsgBox Prompt:="B2B用CSVを保存しました。", Buttons:=vbInformation

Else
    
    MsgBox Prompt:="ロゴス品番が取得できていない商品があります。" & vbLf & "確認後、再保存ボタンでCSVを生成して下さい。", Buttons:=vbCritical

End If

End Sub

Private Sub InsertVlookup()
'品番をロゴス品番シートから引っ張ってくるVlookup式を入れる

Worksheets("ロゴス本日分").Activate

Dim i As Integer

i = 2

Do Until IsEmpty(Cells(i, 2))
        
    Dim c As Range, pc As Range
    Set c = Cells(i, 2) 'コードセル
    Set pc = Cells(i, 5) '品番セル
    
    c.NumberFormatLocal = "@"
    c.Value = CStr(c.Value)
      
    'セットコードを分解する
    If c.Value Like "77777*" Then
        Call MarkAsTiedItem(c)
        Call InsertComponentItems(c)
        GoTo continue
    End If
    
    '品番をロゴス品番シートから拾うVlookup式を入れる
    
    Dim LastRow As Long
    LastRow = Worksheets("ロゴス品番シート").UsedRange.Rows.Count
    
    If Not IsEmpty(pc) Then GoTo continue
         
    '6ケタで引っ張るVlookup
    pc.Formula = "=Vlookup(" & c.Address & ",ロゴス品番シート!$A$1:$C$" & LastRow & ",3,FALSE)"
    
    If IsError(pc.Value) Then
    
        'Janで引っ張るVlookup
        pc.Formula = "=Vlookup(" & c.Address & ",ロゴス品番シート!$B$1:$C$" & LastRow & ",2,FALSE)"
    
    End If
    
    '品番シートでもダメなら、ロゴスメーカー在庫表からJANで引っ張る
    If IsError(pc.Value) Then
        
        On Error Resume Next
            Dim CurRow As Double
            CurRow = WorksheetFunction.Match(pc.Value, Worksheets("メーカー在庫表").Range("B1:B8000"), 0)
            
            pc.Value = CStr(Worksheets("メーカー在庫表").Cells(CurRow, 1))
        
            If Err Then
                pc.Value = ""
                Err.Clear
            End If
        
        On Error GoTo 0
    
    End If
    
    'セット内容の商品は商品名が空行になるので、Vlookupで引っ張る
    If Not TypeName(c.Offset(0, 1).Value) = "String" Then
        c.Offset(0, 1).Formula = "=Vlookup(" & pc.Address & ",ロゴス品番シート!$C$1:$D$" & LastRow & ",2,FALSE)"
    End If
    
    'ロゴス メーカー在庫数を引っ張る
    pc.Offset(0, 1).Formula = "=Vlookup(" & pc.Address & ",メーカー在庫表!A:E,4,FALSE)"
    
continue:
    i = i + 1

Loop

End Sub

Private Sub ExtractLogosItems(PickingSheetName As String)
'ロゴス商品の本日手配シートへの抽出

Dim TodayDate As String
TodayDate = Format(Date, "mmdd")

Worksheets(PickingSheetName & TodayDate).Activate

'商品名の列、行番号を特定
Dim FoundCell As Range
Set FoundCell = Range("A1:E20").Find("商品名")

Dim col As Double, nrow As Double
col = FoundCell.Column
nrow = FoundCell.Row

'フィルターするレンジを指定して背景色黄色をフィルター
Dim ProductListRange As Range
Set ProductListRange = Range(Cells(1, 1), Range("A1").CurrentRegion.SpecialCells(xlCellTypeLastCell))
ProductListRange.AutoFilter Field:=col, Criteria1:=RGB(255, 255, 0), Operator:=xlFilterCellColor

'フィルターした後の行数をカウント＝依頼商品数
Dim CountItem As Long
CountItem = WorksheetFunction.Subtotal(3, Range("C:C")) - 1

Call setItemCount(PickingSheetName, CountItem)

'フィルターして表示しているレンジのみ取得
Dim A As Range, b As Range
Set A = ProductListRange.SpecialCells(xlCellTypeVisible)

'商品名の前後1列＝計3列をコピーしたい、1列前＝コード、1列後ろ＝数量
Set b = Cells(nrow, col).Offset(1, -1).Resize(Cells(2, col).SpecialCells(xlCellTypeLastCell).Row, 3)

Dim IntersectRange As Range
Set IntersectRange = Application.Intersect(A, b)

'フィルターして表示している部分をロゴス本日分へコピー
Dim LastRow As Integer
LastRow = Worksheets("ロゴス本日分").Range("A1").SpecialCells(xlCellTypeLastCell).Row

Dim CopyDestinationRange As Range
Set CopyDestinationRange = Worksheets("ロゴス本日分").Cells(LastRow + 1, 1).Offset(0, 1)

'受注無しだとフィルター後のレンジがないのでチェックしてコピー
If Not IntersectRange Is Nothing Then

    CopyDestinationRange.Offset(0, -1).Value = getMallId(PickingSheetName)
    
    IntersectRange.Copy
    CopyDestinationRange.PasteSpecial Paste:=xlPasteValues
    
End If

ActiveSheet.Range("A2").CurrentRegion.AutoFilter

Exit Sub

NoMatch:

    MsgBox PickingSheetName & "のピッキングシートの見出し「商品名」が見つかりませんでした。"

End Sub

Private Sub CopySheet(Mall As String)

Workbooks.Open FileName:=GetPickingFilePath(Mall), ReadOnly:=True

Dim BookName As String
BookName = ActiveWorkbook.Name 'ファイルを開いたら開いたブックがActiveになっている

ActiveWorkbook.Sheets(1).Copy After:=ThisWorkbook.Worksheets("ロゴス本日分")

ActiveSheet.Name = Mall & Format(Date, "mmdd")

Workbooks(BookName).Close SaveChanges:=False

End Sub

Private Function GetPickingFilePath(MallName As String) As String
'ピッキングシートの-a＝棚無のファイルを探してフルパスをセット

Dim FileName As String
If MallName = "Amazon" Then
    FileName = "ピッキング"
ElseIf MallName = "楽天" Then
    FileName = "楽天"
ElseIf MallName = "Yahoo" Then
    FileName = "ヤフー"
End If

Const PICKING_FILE_FOLDER As String = "\\Server02\商品部\ネット販売関連\ピッキング\" '末尾\マーク必須

'実行時バインディング ScriptingRuntimeはDictionary配列使うのに必要で参照ONだから、事前バインディングでいいかも。
Dim FSO As Object
Set FSO = CreateObject("Scripting.FileSystemObject")
    
Dim f As Object, Target As Object

'指定フォルダー内のFileNameを含むファイル名を調べて、モール名と-aを含むExcelファイルを一つ取得する。
'楽天の場合、楽天Pシート0627-a.xlsを取得

For Each f In FSO.GetFolder(PICKING_FILE_FOLDER).Files

    If f.Name Like FileName & "*-a.xls*" Then
    
        Set Target = f
    
        Exit For
    End If

Next

GetPickingFilePath = PICKING_FILE_FOLDER & Target.Name

End Function

Private Sub InsertComponentItems(c As Range)
'7777始まりのCellを渡してもらって、Codeをパースして返ってきたDictionaryに対して、行を挿入しつつ6ケタ・数量を出力
'要ScriptingRuntime参照、Dictionary配列の事前バインディングに必須

Dim Items As Dictionary
Set Items = ParseTiedItems(c.Value)

Dim OrderedQty As Integer
OrderedQty = c.Offset(0, 2)

Dim v As Variant

For Each v In Items
    
    Rows(c.Offset(1, 0).Row).Insert (xlShiftDown)
    
    c.Offset(1, 0).Value = v
    c.Offset(1, 2).Value = Items(v) * OrderedQty

Next

End Sub

Private Function ParseTiedItems(SetCode As String) As Dictionary

'TiedItemsでセット商品内容…でいいのかな。言葉をすりあわせる必要がある。
'SetItemsだと、GetSetItemsとかになり凄く紛らわしい get/setメソッドと被るので紛らわしい
'TiedItemsは、梱包で結束完了した商品みたいなイメージになってしまうが

Dim TiedCodeList As Worksheet
Set TiedCodeList = Worksheets("ロゴスセット商品リスト")

'登録コードのレンジ、ここをMatch関数で調べて、Codeの行番号を出す
Dim CodeRange As Range
Set CodeRange = TiedCodeList.Range("A1:A" & TiedCodeList.Cells(2, 1).SpecialCells(xlCellTypeLastCell).Row)

On Error Resume Next

    Dim HitRow As Double
    HitRow = WorksheetFunction.Match(SetCode, CodeRange, 0)

On Error GoTo 0

'コードでヒットした行を、F列->J列->M列・・・と調べて、コードと個数をDictionary配列に格納する
Dim d As Dictionary
Set d = New Dictionary

'F列=6から、セット内容はスタート
Dim i As Integer
i = 6

Do Until TiedCodeList.Cells(HitRow, i) = "" 'IsEmptyだと空白セル拾う場合がある

    Dim CodeCell As Range, Code As String, Qty As Integer
    
    Set CodeCell = TiedCodeList.Cells(HitRow, i)
    
    Code = CodeCell.Value
    Qty = CInt(CodeCell.Offset(0, 1))
    
    d.Add Code, Qty   'セット内容商品でダブりがあるとエラーで止まる。
    
    i = i + 4 'シートでは4列でセット内容1商品

Loop

Set ParseTiedItems = d

End Function

Private Function getMallId(MallName As String) As String

Dim MallId As String

Select Case MallName
    
    Case "Amazon"
        MallId = "A"
    
    Case "楽天"
        MallId = "R"
    
    Case "Yahoo"
        MallId = "Y"
       
    Case Else
        MallId = "S"

End Select

getMallId = MallId

End Function

Private Sub MarkAsTiedItem(c As Range)

With c.Interior
    .Pattern = xlSolid
    .PatternColorIndex = xlAutomatic
    .ThemeColor = xlThemeColorAccent6
    .TintAndShade = 0.599993896298105
    .PatternTintAndShade = 0
End With

End Sub

Private Function HasProductCode() As Boolean

Worksheets("ロゴス本日分").Activate

Dim i As Long, tmp As Boolean
i = 2

'一旦、tmpフラグをTrueでセット、E列＝品番列に空欄かエラーがある場合のみFalseとする。
tmp = True

Do
    If IsError(Cells(i, 5).Value) Then
        
        tmp = False
        Exit Do
        
    ElseIf Cells(i, 5).Value = "" Then
        
        tmp = False
        Exit Do
    
    End If
    
    i = i + 1

Loop Until Cells(i, 2).Value = ""

HasProductCode = tmp

End Function

Sub B2B用CSV保存()

'CSVファイルを開いていれば閉じる
Application.DisplayAlerts = False

Dim wb As Workbook
For Each wb In Workbooks
    If InStr(wb.Name, "ロゴス発注登録CSV") > 0 Then wb.Close
Next

Workbooks.Add

'CSVシートの行カウンタ
Dim i As Long
i = 1

With ThisWorkbook.Worksheets("ロゴス本日分")
    
    Dim LastRow As Long
    LastRow = .UsedRange.Rows.Count
    
    '品番/数量を流し込み
    Dim k As Long
    
    For k = 1 To LastRow - 1
        
        If .Range("E1").Offset(k, 0).Value <> "" Then
        
            Cells(i, 1).Value = .Range("E1").Offset(k, 0).Value
            Cells(i, 2).Value = .Range("E1").Offset(k, -1).Value
            
            i = i + 1
        
        End If
        
    Next

End With


    
ActiveWorkbook.SaveAs FileName:=SAVE_FOLDER & "ロゴス発注登録CSV" & Format(Date, "mmdd"), FileFormat:=xlCSV

Application.DisplayAlerts = True

End Sub

Private Sub setItemCount(ByVal MallName As String, ByVal Count As Long)

Select Case MallName
    
    Case "Amazon"
        ItemCount(0) = Count
    
    Case "楽天"
        ItemCount(1) = Count
    
    Case "Yahoo"
        ItemCount(2) = Count
    
    End Select

End Sub
