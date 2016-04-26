USE [QPTreasureDB]
GO
/****** Object:  StoredProcedure [dbo].[GSP_GR_EfficacyUserID]    Script Date: 04/26/2016 10:00:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

----------------------------------------------------------------------------------------------------

-- I D ��¼
ALTER PROC [dbo].[GSP_GR_EfficacyUserID]
	@dwUserID INT,								-- �û� I D
	@strPassword NCHAR(32),						-- �û�����
	@strClientIP NVARCHAR(15),					-- ���ӵ�ַ
	@strMachineID NVARCHAR(32),					-- ������ʶ
	@wKindID SMALLINT,							-- ��Ϸ I D
	@wServerID SMALLINT,						-- ���� I D
	@strErrorDescribe NVARCHAR(127) OUTPUT		-- �����Ϣ
--WITH ENCRYPTION 
AS

-- ��������
SET NOCOUNT ON

-- ������Ϣ
DECLARE @UserID INT
DECLARE @FaceID SMALLINT
DECLARE @CustomID INT
DECLARE @NickName NVARCHAR(31)
DECLARE @UnderWrite NVARCHAR(63)

-- ��չ��Ϣ
DECLARE @GameID INT
DECLARE @GroupID INT
DECLARE @UserRight INT
DECLARE @Gender TINYINT
DECLARE @MasterRight INT
DECLARE @MasterOrder SMALLINT
DECLARE @MemberOrder SMALLINT
DECLARE @GroupName NVARCHAR(31)

-- ���ֱ���
DECLARE @Score BIGINT
DECLARE @Grade BIGINT
DECLARE @Insure BIGINT
DECLARE @WinCount INT
DECLARE @LostCount INT
DECLARE @DrawCount INT
DECLARE @FleeCount INT
DECLARE @UserMedal INT
DECLARE @Experience INT
DECLARE @LoveLiness INT

-- ִ���߼�
BEGIN

	-- ��������
	DECLARE @EnjoinLogon INT

	-- ϵͳ��ͣ
	SELECT @EnjoinLogon=StatusValue FROM QPAccountsDB.dbo.SystemStatusInfo WHERE StatusName=N'EnjoinLogon'
	IF @EnjoinLogon IS NOT NULL AND @EnjoinLogon<>0
	BEGIN
		SELECT @strErrorDescribe=StatusString FROM QPAccountsDB.dbo.SystemStatusInfo WHERE StatusName=N'EnjoinLogon'
		RETURN 2
	END

	-- Ч���ַ
	SELECT @EnjoinLogon=EnjoinLogon FROM ConfineAddress(NOLOCK) WHERE AddrString=@strClientIP AND GETDATE()<EnjoinOverDate
	IF @EnjoinLogon IS NOT NULL AND @EnjoinLogon<>0
	BEGIN
		SET @strErrorDescribe=N'��Ǹ��֪ͨ����ϵͳ��ֹ�������ڵ� IP ��ַ����Ϸ��¼Ȩ�ޣ�����ϵ�ͻ����������˽���ϸ�����'
		RETURN 4
	END
	
	-- Ч�����
	SELECT @EnjoinLogon=EnjoinLogon FROM ConfineMachine(NOLOCK) WHERE MachineSerial=@strMachineID AND GETDATE()<EnjoinOverDate
	IF @EnjoinLogon IS NOT NULL AND @EnjoinLogon<>0
	BEGIN
		SET @strErrorDescribe=N'��Ǹ��֪ͨ����ϵͳ��ֹ�����Ļ�������Ϸ��¼Ȩ�ޣ�����ϵ�ͻ����������˽���ϸ�����'
		RETURN 7
	END
 
	-- ��ѯ�û�
	DECLARE @Nullity BIT
	DECLARE @StunDown BIT
	DECLARE @LogonPass AS NCHAR(32)
	DECLARE	@MachineID NVARCHAR(32)
	DECLARE @MoorMachine AS TINYINT
	SELECT @UserID=UserID, @GameID=GameID, @NickName=NickName, @UnderWrite=UnderWrite, @LogonPass=LogonPass, @FaceID=FaceID, @CustomID=CustomID,
		@Gender=Gender, @Nullity=Nullity, @StunDown=StunDown, @UserMedal=UserMedal, @Experience=Experience, @LoveLiness=LoveLiness, @UserRight=UserRight,
		@MasterRight=MasterRight, @MasterOrder=MasterOrder, @MemberOrder=MemberOrder, @MoorMachine=MoorMachine, @MachineID=LastLogonMachine
	FROM QPAccountsDB.dbo.AccountsInfo(nolock) WHERE UserID=@dwUserID

	-- ��ѯ�û�
	IF @UserID IS NULL
	BEGIN
		SET @strErrorDescribe=N'�����ʺŲ����ڻ������������������֤���ٴγ��Ե�¼��'
		RETURN 1
	END	

	-- �ʺŽ�ֹ
	IF @Nullity<>0
	BEGIN
		SET @strErrorDescribe=N'�����ʺ���ʱ���ڶ���״̬������ϵ�ͻ����������˽���ϸ�����'
		RETURN 2
	END	

	---- �ʺŽ�ֹ
	--IF @MemberOrder=5
	--BEGIN
	--	SET @strErrorDescribe=N'�����ʺű���ֹ��¼��'
	--	RETURN 2
	--END

	-- �ʺŹر�
	IF @StunDown<>0
	BEGIN
		SET @strErrorDescribe=N'�����ʺ�ʹ���˰�ȫ�رչ��ܣ��������¿�ͨ����ܼ���ʹ�ã�'
		RETURN 2
	END	
	
	-- �̶�����
	IF @MoorMachine=1
	BEGIN
		IF @MachineID<>@strMachineID
		BEGIN
			SET @strErrorDescribe=N'�����ʺ�ʹ�ù̶�������¼���ܣ�������ʹ�õĻ���������ָ���Ļ�����'
			RETURN 1
		END
	END

	-- �����ж�
	IF @LogonPass<>@strPassword AND @strClientIP<>N'0.0.0.0' AND @strPassword<>N''
	BEGIN
		SET @strErrorDescribe=N'�����ʺŲ����ڻ������������������֤���ٴγ��ԣ�'
		RETURN 3
	END

	-- �̶�����
	IF @MoorMachine=2
	BEGIN
		SET @MoorMachine=1
		SET @strErrorDescribe=N'�����ʺųɹ�ʹ���˹̶�������¼���ܣ�'
		UPDATE QPAccountsDB.dbo.AccountsInfo SET MoorMachine=@MoorMachine, LastLogonMachine=@strMachineID WHERE UserID=@UserID
	END

	-- ��ʼ����
	SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
	BEGIN TRAN

	-- ��Ϸ��Ϣ
	DECLARE @AllLogonTimes INT
	DECLARE @GameUserRight INT
	DECLARE @GameMasterRight INT
	DECLARE @GameMasterOrder SMALLINT
	SELECT @Score=Score, @Insure=InsureScore, @WinCount=WinCount, @LostCount=LostCount, @DrawCount=DrawCount, @DrawCount=DrawCount,
		@FleeCount=FleeCount, @GameUserRight=UserRight, @GameMasterRight=MasterRight, @GameMasterOrder=MasterOrder, @AllLogonTimes=AllLogonTimes
	FROM GameScoreInfo(nolock) WHERE UserID=@dwUserID

	-- ��Ϣ�ж�
	IF @Score IS NULL
	BEGIN
		-- ��������
		INSERT INTO GameScoreInfo (UserID, LastLogonIP, LastLogonMachine, RegisterIP, RegisterMachine)
		VALUES (@dwUserID, @strClientIP, @strMachineID, @strClientIP, @strMachineID)

		-- ��Ϸ��Ϣ
		SELECT @Score=Score, @Insure=InsureScore, @WinCount=WinCount, @LostCount=LostCount, @DrawCount=DrawCount, @DrawCount=DrawCount,
			@FleeCount=FleeCount, @GameUserRight=UserRight, @GameMasterOrder=MasterOrder, @GameMasterRight=MasterRight, @AllLogonTimes=AllLogonTimes
		FROM GameScoreInfo(nolock) WHERE UserID=@dwUserID
	END

	-- �쳣�ж�
	IF @Score<0
	BEGIN
		-- ��������
		ROLLBACK TRAN
		SET TRANSACTION ISOLATION LEVEL READ COMMITTED

		-- ������Ϣ
		SET @strErrorDescribe=N'��Ǹ��֪ͨ�㣬������Ϸ�����ݳ������쳣���������ϵ�ͻ����������˽���ϸ�����'
		RETURN 14
	END

	-- ��ѯ����
	IF @strClientIP<>N'0.0.0.0'
	BEGIN
		-- �������
		DELETE GameScoreLocker WHERE UserID=@dwUserID AND ServerID=@wServerID

		-- ��ѯ����
		DECLARE @LockKindID INT
		DECLARE @LockServerID INT
		SELECT @LockKindID=KindID, @LockServerID=ServerID FROM GameScoreLocker WHERE UserID=@dwUserID

		-- �����ж�
		IF @LockKindID IS NOT NULL AND @LockServerID IS NOT NULL
		BEGIN

			-- ��������
			ROLLBACK TRAN
			SET TRANSACTION ISOLATION LEVEL READ COMMITTED

			-- ��ѯ����
			IF @LockKindID<>0
			BEGIN
				-- ��ѯ��Ϣ
				DECLARE @KindName NVARCHAR(31)
				DECLARE @ServerName NVARCHAR(31)
				SELECT @KindName=KindName FROM QPPlatformDB.dbo.GameKindItem WHERE KindID=@LockKindID
				SELECT @ServerName=ServerName FROM QPPlatformDB.dbo.GameRoomInfo WHERE ServerID=@LockServerID

				-- ������Ϣ
				IF @KindName IS NULL SET @KindName=N'δ֪��Ϸ'
				IF @ServerName IS NULL SET @ServerName=N'δ֪����'
				SET @strErrorDescribe=N'������ [ '+@KindName+N' ] �� [ '+@ServerName+N' ] ��Ϸ�����У�����ͬʱ�ڽ������Ϸ���䣡'
				RETURN 4

			END
			ELSE
			BEGIN
				-- ��ʾ��Ϣ
				SELECT [ErrorDescribe]=N'�����ڽ��б��չ��������У���ʱ�޷��������Ϸ���䣡'
				RETURN 4
			END
		END
	END

	-- ��������
	SET @Grade=0
	SET @GroupID=0
	SET @GroupName=''

	-- Ȩ�ޱ�־
	SET @UserRight=@UserRight|@GameUserRight
	SET @UserRight=@UserRight&~256
	SET @MasterRight=@MasterRight|@GameMasterRight

	-- Ȩ�޵ȼ�
	IF @GameMasterOrder>@MasterOrder SET @MasterOrder=@GameMasterOrder

	-- �����¼
	INSERT RecordUserInout (UserID, EnterScore, EnterGrade, EnterInsure, EnterUserMedal,EnterLoveliness, KindID, ServerID, EnterClientIP, EnterMachine)
	VALUES (@UserID, @Score, @Grade, @Insure, @UserMedal, @Loveliness, @wKindID, @wServerID, @strClientIP, @strMachineID)

	-- ��¼��ʶ
	DECLARE @InoutIndex BIGINT
	SET @InoutIndex=SCOPE_IDENTITY()

	-- ��������
	IF @strClientIP<>N'0.0.0.0'
	BEGIN
		-- ��������
		INSERT GameScoreLocker (UserID, ServerID, KindID, EnterID, EnterIP, EnterMachine) VALUES (@dwUserID, @wServerID, @wKindID, @InoutIndex, @strClientIP, @strMachineID)
		IF @@ERROR<>0
		BEGIN
			-- ��������
			ROLLBACK TRAN
			SET TRANSACTION ISOLATION LEVEL READ COMMITTED

			-- ������Ϣ
			SET @strErrorDescribe=N'��Ǹ��֪ͨ�㣬��Ϸ����������ʧ�ܣ�����ϵ�ͻ����������˽���ϸ�����'
			RETURN 14
		END
	END

	--������Ϣ
	UPDATE GameScoreInfo SET AllLogonTimes=AllLogonTimes+1, LastLogonDate=GETDATE(), 
		LastLogonIP=@strClientIP,LastLogonMachine=@strMachineID WHERE UserID=@dwUserID

	-- ��¼ͳ��
	DECLARE @DateID INT
	SET @DateID=CAST(CAST(GETDATE() AS FLOAT) AS INT)

	-- �����¼
	IF @AllLogonTimes>0
	BEGIN
		UPDATE SystemStreamInfo SET LogonCount=LogonCount+1 WHERE DateID=@DateID AND KindID=@wKindID AND ServerID=@wServerID
		IF @@ROWCOUNT=0 INSERT SystemStreamInfo (DateID, KindID, ServerID, LogonCount) VALUES (@DateID, @wKindID, @wServerID, 1)
	END
	ELSE
	BEGIN
		UPDATE SystemStreamInfo SET RegisterCount=RegisterCount+1 WHERE DateID=@DateID AND KindID=@wKindID AND ServerID=@wServerID
		IF @@ROWCOUNT=0 INSERT SystemStreamInfo (DateID, KindID, ServerID, RegisterCount) VALUES (@DateID, @wKindID, @wServerID, 1)
	END

	-- ��������
	COMMIT TRAN
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED

IF (@Score+@Insure=0) SET @Score=1
	-- �������
	SELECT @UserID AS UserID, @GameID AS GameID, @GroupID AS GroupID, @NickName AS NickName, @UnderWrite AS UnderWrite,  @FaceID AS FaceID,
		@CustomID AS CustomID, @Gender AS Gender, @GroupName AS GroupName, @MasterOrder AS MemberOrder, @UserRight AS UserRight, @MasterRight AS MasterRight,
		@MasterOrder AS MasterOrder, @MemberOrder AS MemberOrder, @Score AS Score,  @Grade AS Grade, @Insure AS Insure,  @WinCount AS WinCount,
		@LostCount AS LostCount, @DrawCount AS DrawCount, @FleeCount AS FleeCount, @UserMedal AS UserMedal, @Experience AS Experience, @LoveLiness AS LoveLiness,
		@InoutIndex AS InoutIndex

END

RETURN 0
