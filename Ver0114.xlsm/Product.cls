VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Product"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
'��1�A�C�e���ɑΉ�����N���X

'�V�[�g����ǂݎ���ăZ�b�g����t�B�[���h

Public OrderId As String

Public Code As String

Public Name As String
Public Jan As String

Public CenterStockState As String

Public ReqQuantity As Long '�K�v��

Public PurchaseDate As Date

Public VenderStatus As String

Public EstimatedArrivalDate As Date

'Product���g�Ń��\�b�h���点�ăZ�b�g����t�B�[���h

Public IsUnavailable As Boolean
Public IsPickingDone As Boolean

Sub setIsUnavailable()
    
    If InStr(CenterStockState, "�p��") > 0 Or _
        InStr(CenterStockState, "����") > 0 Or _
        InStr(CenterStockState, "�I��") > 0 Or _
        InStr(CenterStockState, "���~") > 0 Then
        
        IsUnavailable = True
    
    ElseIf InStr(VenderStatus, "�p��") > 0 Or _
        InStr(VenderStatus, "����") > 0 Or _
        InStr(VenderStatus, "�I��") > 0 Or _
        InStr(VenderStatus, "���~") > 0 Or _
        InStr(VenderStatus, "���i") > 0 Then
        
        IsUnavailable = True
    
    End If
    
End Sub
Sub setIsPickingDone()
    
    If CenterStockState = "" Then
        
        IsPickingDone = True
    
    End If

End Sub