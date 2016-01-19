VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Invoices"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'�����̏W���N���X�ADictionary�̊g���Ƃ��ł���Ƃ����̂����B

'fetchReportXlsx() �萔�錾���Ă���p�X�̏o�׈ꗗ�ڍ�.xlsx��ǂݍ���ő����Dictionaly���쐬
'fetchReportCsv()�@�萔�錾���Ă���p�X�̏o�׈ꗗ�ڍ�.csv��ǂݍ���ő����Dictionaly���쐬

'�o�׈ꗗ�ڍ�.csv�̃p�X
Const REPORT_CSV_PATH As String = "\\server02\���i��\�l�b�g�̔��֘A\�o�גʒm\�o�גʒm_�y�V\�o�׈ꗗ�ڍ�.csv"

'�o�׈ꗗ�ڍ�.xlsx�̃p�X�ƃt�@�C����
Const REPORT_XLSX_FOLDER As String = "\\server02\���i��\�l�b�g�̔��֘A\�o�גʒm\�o�גʒm_�y�V\���o�׈ꗗ�ڍ�\"
Const REPORT_XLSX_BASENAME As String = "�o�׈ꗗ�ڍ�"

'�����ԍ����L�[�Ƃ����AInvoice�I�u�W�F�N�g�̎����z��
Public InvoiceNumberList As Dictionary

Public Sub fetchReportXlsx()
'�o�׏ڍ׈ꗗ�G�N�Z���t�@�C���̕�����InvoiceList�𐶐�

Application.ScreenUpdating = False

'�t�@�C�����͏o�׈ꗗ�ڍ�_150603.xlsx�̌`
Dim FileName As String
FileName = REPORT_XLSX_BASENAME & "_" & Format(Date, "yymmdd") & ".xlsx"

'�e�X�g�p�̃p�X
'FileName = REPORT_XLSX_BASENAME & "_" & "151006" & ".xlsx"

Dim Path As String
Path = REPORT_XLSX_FOLDER & FileName

findReportFile (Path)

'�u�b�N���J�������A����󃌃|�[�g���[�N�u�b�N���擾
Dim InvoiceReportWb As Workbook
Dim wb As Workbook

'�J���Ă���u�b�N�̒��ɏo�׈ꗗ�ڍׂ��Ȃ����`�F�b�N
'�J���Ă�΂��̂܂܎g���΂����A�J���ĂȂ���ΊJ���ăZ�b�g
For Each wb In Workbooks
    If wb.Name = FileName Then
        Set InvoiceReportWb = wb
    End If
Next wb

'���[�N�u�b�N���J���ăZ�b�g
If InvoiceReportWb Is Nothing Then

    Set InvoiceReportWb = Workbooks.Open(Path)
    
    Dim IsOpenReport As Boolean
    IsOpenReport = True
        
End If


ShippingFileProgress.ProgressBar.Value = 2
ShippingFileProgress.ShowCurrentProcess.Caption = "�o�׈ꗗ�ڍ� �ǂݍ��ݒ�"


'�o�׈ꗗ�ڍׂŒ����ԍ���AE1��
'���傢���傢���o�����Ȃ��񂪂���B
'�����\�[�g�Ń��t�[�̒����ԍ��t�H�[�}�b�g100######����ɗ���͂������A
'���M���Ȃ��̂ŁA���s���Ԃ��x���Ȃ��Ă��S�s���ׂ܂��B�|��CSV�Ǎ���肸���Ƒ��������B

'Invoce�I�u�W�F�N�g������Dictionary��������
Set InvoiceNumberList = New Dictionary

Dim MaxRow As Long
MaxRow = InvoiceReportWb.Sheets(1).Range("AE1").SpecialCells(xlCellTypeLastCell).Row

Dim i As Long

'�S�Ă̍s�𒲂ׂ�
For i = 2 To MaxRow
    
    '������C��A�����ԍ�E��A�����ԍ�AE��
    
    With InvoiceReportWb.Sheets(1)
        
        Dim CurrentId As String
        CurrentId = .Range("AE" & i).Value
        
        Dim CurrentInvoiceNum As String
        CurrentInvoiceNum = .Range("E" & i).Value
        
        Dim CurrentShipDate As Date
        CurrentShipDate = .Range("C" & i).Value
        
    End With
    
    '���t�[�̒����ԍ��̌`���Ȃ�AInvoice�C���X�^���X�𐶐�����InvoiceNumberList �ɒǉ�
    If CurrentId Like "10######" And Len(CurrentInvoiceNum) > 0 Then
            
        Dim invoice As invoice
        Set invoice = New invoice
        
        invoice.Id = CurrentId
        invoice.InvoiceNumber = CurrentInvoiceNum
        invoice.ShippingDate = CurrentShipDate
        
        On Error Resume Next
        
            InvoiceNumberList.Add CurrentId, invoice
        
        On Error GoTo 0
                  
    End If

Next

checkInvoiceList

'���̃��W���[���Ńu�b�N���J���Ă���Ε���B
If IsOpenReport Then InvoiceReportWb.Close SaveChanges:=False

Application.ScreenUpdating = True

End Sub

Private Function findReportFile(Path As String) As String
'�o�׏ڍׂ̃p�X��Ԃ��܂��B

Dim FSO As FileSystemObject
Set FSO = New FileSystemObject

Dim res As Long 'MsgBox����̕Ԃ�l���󂯂�

If FSO.FileExists(Path) Then '�o�׏ڍ׈ꗗ�t�@�C���̑��݃`�F�b�N
    
    Dim dtc As Date
    
    dtc = FSO.GetFile(Path).DateLastModified

    res = MsgBox(FSO.GetFileName(Path) & vbLf _
                & "�ŏI�X�V�F" & Format(dtc, "mm��dd�� hh:mm") & vbLf _
                & "���̃t�@�C�����琶�����܂����H" _
                , vbYesNo + vbQuestion)
                
    If res <> 6 Then

        MsgBox prompt:="�o�׈ꗗ�t�@�C���̓Ǎ����L�����Z������܂����B", Buttons:=vbInformation
        End

    End If

    findReportFile = Path

Else

    MsgBox prompt:="�{���̏o�׈ꗗ�t�@�C��������܂���B", Buttons:=vbCritical
    End

End If

End Function

Private Sub checkInvoiceList()
'����󃊃X�g�̌������`�F�b�N����0���Ȃ�}�N���I��

If InvoiceNumberList.Count = 0 Then

    MsgBox prompt:="�{���̏o�ׂ͂���܂���B", Buttons:=vbCritical
    End

End If

End Sub

Public Sub fetchReportCsv()
 '�o�׏ڍ�CSV��ǂݍ����InvoiceList�����܂��B
 
Dim Path As String
Path = findReportFile(REPORT_CSV_PATH)

Set InvoiceNumberList = New Dictionary

Dim FSO As FileSystemObject
Set FSO = New FileSystemObject

Dim TS As Textstream
Set TS = FSO.OpenTextFile(Path, ForReading)

Dim LineBuf() As String

Do Until TS.AtEndOfStream

    LineBuf = Split(TS.ReadLine, ",")
    
    Dim tmp() As Variant
    '30��ڂ̒����ԍ�=tmp(0)�A4��ڂ̑����ԍ�tmp(1)�@2��ڂ̔�����tmp(2)
    tmp() = Array(LineBuf(30), LineBuf(4), LineBuf(2))

    Dim j As Long
    For j = 0 To UBound(tmp())
        tmp(j) = Trim(Replace(tmp(j), Chr(34), "")) 'chr(34)�� " [���p��d���p��]�炵��
    
    Next
    
    '�����ԍ���10�n�܂�̐���8�P�^�����t�[�̒����ԍ��t�H�[�}�b�g
    '���A�����ԍ��������Ă��钍���ԍ��̂�InvoiceList�Ɋi�[����

    If tmp(0) Like "10######" And Len(tmp(1)) > 0 Then
        
        Dim invoice As invoice
        Set invoice = New invoice
        
        invoice.Id = tmp(0)
        invoice.InvoiceNumber = tmp(1)
        invoice.ShippingDate = CDate(tmp(2))
        
        On Error Resume Next
        
            InvoiceNumberList.Add tmp(0), invoice
        
        On Error GoTo 0
        
    End If
        
Loop

checkInvoiceList

End Sub