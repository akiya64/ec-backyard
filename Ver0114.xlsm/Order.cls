VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Order"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
'����1���̃N���X ���t�^�̏����l�� #00:00:00#

Public Id As String                    '�����ԍ�
Public OrderDate As Date               '�󒍓�
Public InvoiceNumber As String         '�����ԍ�
Public ShippingDate As Date            '������
Public ShippingMethod As String        '�������@
Public BuyerName As String             '�����Җ�

Public IsWaitingPayment As Boolean     '�����҂�

Public Products As Dictionary          '�������i���X�g

Public CanNotShipping As Boolean       '�������ł��遁False�@�ł��Ȃ���True

Public SendMailDate As Date            '�[���A����

Public IsCancel As Boolean             '�L�����Z���t���O�@True=�L�����Z��
Public IsExceptShipping As Boolean     '

Public AlertPiriod As Date             '�A���[�g�̊��


Public Sub Class_Initialize()  '�R���X�g���N�^�A�I�u�W�F�N�g�������Ƀf�t�H���g��AlertPiriod �A���[�g�N�_�����Z�b�g������������



End Sub

Sub setCanNotShipping()
'�����s�\�Ȓ����ł��邩�H
'�A�C�e���̏󋵂��`�F�b�N���Ĕ���=Shipping�s�t���O�𗧂Ă܂��B
    
    Dim v As Variant
    

    For Each v In Products
    
        With Products(v)
        

        '�s�b�L���O�ł��Ă��Ȃ����i�������True
        If Not .IsPickingDone Then
            CanNotShipping = True
            
        End If
        
        '��z�����{���Ȃ�True
        If .PurchaseDate = Date Then
             
            '�������AArrivalDate���{���Ȃ�False
            If DateDiff("d", Products(v).EstimatedArrivalDate, Date) = 0 Then
                
                CanNotShipping = False
            
            Else
                
                CanNotShipping = True
            
            End If
        
        End If

        End With
        
    Next
    
    Call setAlertPiriod        'alert�N�Z�����Z�b�g
    Call cancelCanNotShipping  'CanNotShipping�������ł��邩�`�F�b�N

End Sub

Private Sub setAlertPiriod()  '�A���[�g�̋N�_��

Dim p As New Product

'�f�t�H���g�ň�U�A�󒍓����Z�b�g����
'�����Ȃ���΁A����͎󒍓��ƂȂ�A��������O���o�߂ŃA���[�g�ΏۂƂȂ�

AlertPiriod = OrderDate

Dim v As Variant

For Each v In Products
    Set p = Products(v)
    
    '����DateDiff���܂��A��Ɉ�Ԓx�����t���w���悤�ɃZ�b�g�������̂ŁB

    '�s�b�L���O����Ă��Ȃ����i�Ȃ�A��z���𒲂ׂăZ�b�g
    If Not p.IsPickingDone Then  '
        If DateDiff("d", AlertPiriod, p.PurchaseDate) >= 0 Then
            AlertPiriod = p.PurchaseDate
        End If
    End If
    
    '��z�������i������΁A���ח\������Z�b�g
    If p.PurchaseDate <> #12:00:00 AM# Then
        If DateDiff("d", AlertPiriod, p.PurchaseDate) > 0 Then
            AlertPiriod = p.PurchaseDate
        End If
    End If

    '���ח\�������܂��Ă���΁A���ח\������Z�b�g
    If p.EstimatedArrivalDate <> #12:00:00 AM# Then
        If DateDiff("d", AlertPiriod, p.EstimatedArrivalDate) > 0 Then
            AlertPiriod = p.EstimatedArrivalDate
        End If
    End If

Next

End Sub

Private Sub cancelCanNotShipping()
'Order.IsShippingDisable�������ł������
'Product.IsPicking��False�̏��i�S�Ăɂ���EstimatedArrivalDate�𒴂��Ă���

'��UIsAllProductsAvailable=�S���i�������Ă��邩�t���O��True
'��_�ł����i�󋵂�False=�����s�Ȃ�False�ɂ���BVBA��Boolean�����l��False

Dim IsAllProductsAvailable As Boolean
IsAllProductsAvailable = True

Dim p As Product
Dim v As Variant

For Each v In Products
    
    
    Set p = Products(v)
    
    '�Z���^�[�A���[�J�[�X�e�[�^�X�Ŕp�ԂƂ��Ȃ�True
    '�����ł�������͔������Ȃ��̂ŁA�`�F�b�N�I��
    If p.IsUnavailable Then
        CanNotShipping = True
        Exit Sub
    End If

    'Product���s�b�L���O�ς��ǂ���
    If p.IsPickingDone Then
        
        IsAllProductsAvailable = True
        GoTo continue
        
    End If
    
    'Product���s�b�L���O����Ă��Ȃ��āA���ח\����ɓ��t�������Ă��鎞�A�ǂ��炩��False�Ȃ�Available��False
    If p.IsPickingDone = False And p.EstimatedArrivalDate <> #12:00:00 AM# Then
                            
        'IsAllItemAvailable�Ƃ̘_���a�����A���̎�IsAllProductsAvailable�́A�C�e���[�^�̎w�����i�̈�O�̏��i�܂őS�Ă�Avalable�łȂ����True�������Ȃ�
        'TODO:�������Y��ɁA�ꏤ�i�ł�Available�łȂ���΁ACanNotShipping=False���ł���̂ł͂Ȃ����ƁA�ċA�Ƃ��Z����OR�֐��Ƃ��g����΁B
        
        If DateDiff("d", Date, p.EstimatedArrivalDate) <= 0 And IsAllProductsAvailable Then
            IsAllProductsAvailable = True
            
            GoTo continue
        
        Else
            IsAllProductsAvailable = False
            GoTo continue
        
        End If
    
    Else
    
        IsAllProductsAvailable = False
    
    End If

continue:

Next

'�S�Ă̏��i��Available�Ȃ��CanNotShipping��False�A�o�׉\

If IsAllProductsAvailable Then CanNotShipping = False


End Sub