/****** Object:  Table [dbo].[ai_sq_jobTrigger]    Script Date: 11/6/2024 11:44:47 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ai_sq_jobTrigger] (
    [Job_Id] INT IDENTITY(1,1) NOT NULL,  -- Auto-incrementing Job_Id
    [Submission_num] NVARCHAR(100) NOT NULL,
    [StartDate] DATETIME NULL,
    [EndDate] DATETIME NULL,
    [Batch_ID] INT NULL,
    [Job_status] NVARCHAR(50) NULL,
    PRIMARY KEY CLUSTERED ([Job_Id] ASC)
        WITH (
            STATISTICS_NORECOMPUTE = OFF, 
            IGNORE_DUP_KEY = OFF, 
            OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF
        ) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[ai_sq_jobTrigger]
WITH CHECK ADD CHECK (
    [Job_status] = 'completed triage' 
    OR [Job_status] = 'running triage' 
    OR [Job_status] = 'uploaded'
)
GO

/****** Object:  Table [dbo].[ai_sq_fileDetails]    Script Date: 11/6/2024 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ai_sq_fileDetails] (
    [Object_Id] NVARCHAR(255) NOT NULL,
    [Submission_num] NVARCHAR(100) NOT NULL,  -- Added Submission_num column
    [UploadedFileName] NVARCHAR(255) NULL,
    [Batch_Type] NVARCHAR(100) NOT NULL, -- Renamed File_source to Batch_Type
    [SavedFilePath] NVARCHAR(255) NULL,
    [SavedFileName] NVARCHAR(255) NULL,
    [CreateDate] DATETIME NULL,
    [ModifyDate] DATETIME NULL,
    [ContentType] NVARCHAR(255) NULL,
    [Doc_Class] NVARCHAR(255) NULL,
    [OBU] NVARCHAR(100) NULL,
    [AccountName] NVARCHAR(255) NULL,
    [AccountNumber] NVARCHAR(255) NULL,
    [Status] NVARCHAR(255) NULL,
    [Status_UpdateTime] DATETIME NULL,
    CONSTRAINT CHK_FileDetails_Status CHECK (
        [Status] IN ('Uploaded', 'In Progress', 'Processed')  -- Remove This check
    )
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[ai_sq_fileDetails]
WITH CHECK ADD CHECK (
    [Batch_Type] = 'User_Upload' 
    OR [Batch_Type] = 'Schedule' -- Make it Schedule.
)
GO


/****** Object:  Table [dbo].[ai_sq_fileBinary]    Script Date: 11/6/2024 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ai_sq_fileBinary] (
    [Object_Id] NVARCHAR(100) NOT NULL,
    [Byte_object] VARBINARY(MAX) NULL
    -- Add SUbmission_num
) ON [PRIMARY]
TEXTIMAGE_ON [PRIMARY]
GO


/****** Object:  Table [dbo].[ai_sq_scoredSubmission]    Script Date: 11/8/2024 12:55:29 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ai_sq_scoredSubmission](
	[Submission_num] [nvarchar](100) NOT NULL,
	[Source] [nvarchar](50) NOT NULL, -- Rename to Batch_Type
	[Score_Date] [datetime] NOT NULL,
	[Score] [nvarchar](10) NOT NULL,
	[User_Upload_Status] [nvarchar](100) NULL -- Rename to Scored_Status
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[ai_sq_scoredSubmission] ADD  DEFAULT (getdate()) FOR [Score_Date]
GO

ALTER TABLE [dbo].[ai_sq_scoredSubmission]  WITH CHECK ADD CHECK  (([Score]='Green' OR [Score]='Amber' OR [Score]='Red'))
GO

ALTER TABLE [dbo].[ai_sq_scoredSubmission]  WITH CHECK ADD CHECK  (([Source]='User_Upload' OR [Source]='Scheduled'))
GO


