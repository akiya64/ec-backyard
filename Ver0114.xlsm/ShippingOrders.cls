VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "ShippingOrders"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Const SERVER02_YAHOO_SHIPPMET_PATH As String = "\\server02\���i��\�l�b�g�̔��֘A\�o�גʒm\�o�גʒm_���t�[\"
Const CSV_BASE_NAME As String = "���t�[�����ԍ��ꊇ"

Public Orders As Dictionary

Public Sub createShippingList(UndispatchOrders As Dictionary, Invoices As Invoices)
'Order�̓����Ă���Dictionary��InvoiceList�I�u�W�F�N�g���󂯎���āA
'InvoiceList�̒���ID1�����ɂ��āA�Ή����钍���ԍ������������X�g�ɂ��邩���ׂ�
'����΁A�������X�g�ɉ����āA�����ԍ��A����������

Set Orders = New Dictionary

Dim v As Variant
For Each v In Invoices.InvoiceNumberList
    
    Dim Id As String
    Id = Invoices.InvoiceNumberList(v).Id

    'undispatchOrder���X�g�ɊY��OrderId������΁A�������X�g�ɉ�����
    If UndispatchOrders.Exists(Id) Then
        
        On Error Resume Next
            
            Orders.Add Id, UndispatchOrders(Id)
        
        On Error GoTo 0
    
    Else
    
    'Todo:�o�׏ڍׂ̒����ԍ����A���c���X�g�ɂȂ��ꍇ
    
        
    End If
    
    '�������X�g�̊Y�������ԍ��ɁA�����ԍ��Ɣ���������
    If Orders.Exists(Id) Then
        
        With Orders(Id)
            
            If .InvoiceNumber = "" Then
               .InvoiceNumber = Invoices.InvoiceNumberList(Id).InvoiceNumber
               .ShippingDate = Invoices.InvoiceNumberList(Id).ShippingDate
            End If
        
        End With
    
    End If
     
Next

'�������X�g���o���Ă��邩�`�F�b�N
If Orders.Count = 0 Then
    
    MsgBox prompt:="�{���̏o�ׂ͂���܂���B" & vbLf & "���c�Ǘ��V�[�g�A�o�׏ڍ׃t�@�C�����m�F���Ă��������B" _
    , Buttons:=vbExclamation
    
    End

End If

End Sub

Public Sub putCsv()
'Orders�����t�[�ɃA�b�v���[�h�ł���CSV�`���ŏ��������܂��B

'1�DFSO�I�u�W�F�N�g��csv�t�@�C����p��
'2�D�e�L�X�g�X�g���[���I�u�W�F�N�g�ōs�ǋL
'�Q�l�Fhttp://www.asahi-net.or.jp/~ef2o-inue/vba_o/sub05_110_050.html

Dim day As String
day = Format(Date, "mm") & Format(Date, "dd")

Dim DefaultOutputDir As String
DefaultOutputDir = Environ("HOMEDRIVE") & Environ("HOMEPATH") & "\Desktop\���t�["

'�ۑ���t�H���_�̃`�F�b�N
Dim OutputPath As String

If Dir(DefaultOutputDir, vbDirectory) = "���t�[" Then '���t�[�t�H���_���f�X�N�g�b�v�ɂ��鎞

    OutputPath = DefaultOutputDir & "\" & CSV_BASE_NAME & day & ".csv"


Else
    
    MsgBox "�f�X�N�g�b�v���Ɂu���t�[�v�t�H���_������܂���B" & vbLf & "�f�X�N�g�b�v�֕ۑ����܂��B"
    OutputPath = Replace(DefaultOutputDir, "���t�[", "") & CSV_BASE_NAME & day & ".csv"

End If

'OutputPath = SERVER02_YAHOO_SHIPPMET_PATH & CSV_BASE_NAME & day & ".csv"


Dim FSO As FileSystemObject
Set FSO = New FileSystemObject

Dim res As Integer

'�{���̃t�@�C�������邩�`�F�b�N
If FSO.FileExists(OutputPath) Then
    res = MsgBox("���t�[�����ԍ��ꊇ" & day & ".csv" & vbLf & "���ɑ��݂��܂��A�㏑�����܂����H", _
    vbYesNo + vbExclamation)
    
    If res <> 6 Then

        MsgBox prompt:="�����𒆎~���܂����B", Buttons:=vbInformation
        End

    End If

End If

Dim TS As Object
Set TS = FSO.CreateTextFile(FileName:=OutputPath, OverWrite:=True)

'�w�b�_�[��p�ӂ��ċL��
Dim Header As String
Header = "OrderId,ShipMethod,ShipInvoiceNumber1,ShipDate,ShipStatus"

TS.WriteLine Header

'disableFlg���`�F�b�N����CSV�֏o��
Dim v As Variant
For Each v In Orders
       
    '�����s�t���O���^�Ȃ̂ɁA�����ԍ����������ꍇ�͒��c�V�[�g�Ɂu�������O�v�������߂�
    If Orders(v).CanNotShipping Then
        
        OrderSheet.writeExceptShippingNotification (Orders(v).Id)
    
    Else
        
        '1�s���̕���������
        Dim RowText As String
        
        RowText = Orders(v).Id
        RowText = RowText & "," & "postage1"
        RowText = RowText & "," & Orders(v).InvoiceNumber
        RowText = RowText & "," & Format(Orders(v).ShippingDate, "yyyy/mm/dd")
        RowText = RowText & "," & "2"
        
        'CSV�֒ǋL
        TS.WriteLine RowText
    
    End If
Next

TS.Close

End Sub