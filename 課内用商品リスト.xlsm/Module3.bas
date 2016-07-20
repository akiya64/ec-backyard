Attribute VB_Name = "Module3"
Sub 商魂データの取込()

    With Application
        .Calculation = xlCalculationManual
        .ScreenUpdating = False
    End With
    '''''''''''''''''''''''
    Dim top As Worksheet
    Set top = ThisWorkbook.Worksheets("トップ")
    Dim data As Worksheet
    Set data = ThisWorkbook.Worksheets("商品情報")
    Dim config As Worksheet
    Set config = ThisWorkbook.Worksheets("設定")
    Dim master As Worksheet
    Set master = ThisWorkbook.Worksheets("m")
    ''''''''''''''''''''''''''''''''''''''''''
    '６桁上のものを一度整理
    For a = master.Range("A500000").End(xlUp).Row To 2 Step -1
        With master
            .Cells(a, 1).NumberFormat = "@"
            .Cells(a, 1).Value = Right(master.Cells(a, 1).Value, 6)
        End With
    Next a
    
    
    
    '例外処理以外を設定
    Dim bairitsu As String
    Dim skurow As String
    For i = 2 To data.Range("B500000").End(xlUp).Row
        With data
            If data.Cells(i, 27).Value = "-" Then
                .Cells(i, 28).Value = "変更しない"
            ElseIf data.Cells(i, 27).Value <> "" And data.Cells(i, 27).Value > Date And IsDate(data.Cells(i, 27).Value) Then
                .Cells(i, 28).Value = "商魂取り込まない"
            Else
            'その他のみ取込
                '倍率決定
                bairitsu = 1
                If data.Cells(i, 7).Value <> "" And IsNumeric(data.Cells(i, 7).Value) Then
                    bairitsu = data.Cells(i, 7).Value
                End If
                
                'JANで引っ張り
                If Not IsError(Application.Match(data.Cells(i, 1).Value, master.Range("C:C"), 0)) Then
                    skurow = Application.Match(data.Cells(i, 1).Value, master.Range("C:C"), 0)
                    If Application.RoundUp(bairitsu * master.Cells(skurow, 6).Value, 0) <> data.Cells(i, 13).Value Then
                        .Cells(i, 13).Value = Application.RoundUp(bairitsu * master.Cells(skurow, 6).Value, 0)
                        .Cells(i, 14).Value = Format(Date, "yyyy/mm/dd")
                    End If
                    
                    If InStr(data.Cells(i, 4).Value, "廃") = 0 Or InStr(data.Cells(i, 4).Value, "処分") = 0 Or InStr(data.Cells(i, 4).Value, "中止") = 0 Then
                        If InStr(master.Cells(skurow, 15).Value, "廃") > 0 Then
                            .Cells(i, 4).Value = data.Cells(i, 4).Value & " 廃番"
                        ElseIf InStr(master.Cells(skurow, 15).Value, "処分") > 0 Then
                            .Cells(i, 4).Value = data.Cells(i, 4).Value & " 処分品完売"
                        ElseIf InStr(master.Cells(skurow, 15).Value, "中止") > 0 Then
                            .Cells(i, 4).Value = data.Cells(i, 4).Value & " 販売中止"
                        End If
                    End If
                End If
                
                'SKUで引っ張り
                skurow = ""
                If Not IsError(Application.Match(data.Cells(i, 2).Value, master.Range("A:A"), 0)) Then
                    skurow = Application.Match(data.Cells(i, 2).Value, master.Range("A:A"), 0)
                    If Application.RoundUp(bairitsu * master.Cells(skurow, 6).Value, 0) <> data.Cells(i, 13).Value Then
                        .Cells(i, 13).Value = Application.RoundUp(bairitsu * master.Cells(skurow, 6).Value, 0)
                        .Cells(i, 14).Value = Format(Date, "yyyy/mm/dd")
                    End If
                    
                    If InStr(data.Cells(i, 4).Value, "廃") = 0 Or InStr(data.Cells(i, 4).Value, "処分") = 0 Or InStr(data.Cells(i, 4).Value, "中止") = 0 Then
                        If InStr(master.Cells(skurow, 15).Value, "廃") > 0 Then
                            .Cells(i, 4).Value = data.Cells(i, 4).Value & " 廃番"
                        ElseIf InStr(master.Cells(skurow, 15).Value, "処分") > 0 Then
                            .Cells(i, 4).Value = data.Cells(i, 4).Value & " 処分品完売"
                        ElseIf InStr(master.Cells(skurow, 15).Value, "中止") > 0 Then
                            .Cells(i, 4).Value = data.Cells(i, 4).Value & " 販売中止"
                        End If
                    End If
                End If
                
                
                
                
                
                
                
                
                
                
                
                
                
                
                
            End If
    
        End With
    Next i
    

    '''''''''''''''''''''''
    With Application
        .Calculation = xlCalculationAutomatic
        .ScreenUpdating = True
    End With

End Sub

