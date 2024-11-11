/****** Object:  StoredProcedure [dbo].[sp_InsertOrUpdateScoredSubmission]    Script Date: 11/8/2024 12:47:45 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_InsertOrUpdateScoredSubmission]
    @ScoredSubmissionJson NVARCHAR(MAX)
AS
BEGIN
    -- Declare variables to hold the individual properties from the input JSON
    DECLARE @Object_Id NVARCHAR(255),
            @Source NVARCHAR(50),
            @Score NVARCHAR(10),
            @Submission_num NVARCHAR(100),
			@User_Upload_Status NVARCHAR(100);

    -- Parse the input JSON into variables
    SELECT 
        @Object_Id = Object_Id,
        @Source = Source,
        @Score = Score
    FROM OPENJSON(@ScoredSubmissionJson)
    WITH (
        Object_Id NVARCHAR(255),
        Source NVARCHAR(50),
        Score NVARCHAR(10)
    );

    -- Validate Score value
    IF @Score NOT IN ('Red', 'Amber', 'Green')
    BEGIN
        RAISERROR('Invalid Score value. Valid values are: Red, Amber, Green.', 16, 1);
        RETURN;
    END

	-- Determine Object_Id based on Batch_Type
    IF @Score = 'Red'
    BEGIN
        SET @User_Upload_Status = 'No Response';
    END
	ELSE IF @Score IN ('Amber', 'Green')
	BEGIN
         SET @User_Upload_Status = 'Completed';
    END
	ELSE
	BEGIN
        SET @User_Upload_Status = NULL;
    END

    -- Fetch the Submission_num from ai_sq_fileDetails using the Object_Id
    SELECT @Submission_num = Submission_num
    FROM dbo.ai_sq_fileDetails
    WHERE Object_Id = @Object_Id;

    -- Check if Submission_num was found, if not, raise an error
    IF @Submission_num IS NULL
    BEGIN
        RAISERROR('No Submission_num found for the given Object_Id', 16, 1);
        RETURN;
    END

    -- Attempt to update the record if it exists
    UPDATE dbo.ai_sq_scoredSubmission
    SET 
        Source = COALESCE(@Source, Source),  -- Update Source if it's not NULL
        Score = COALESCE(@Score, Score),    -- Update Score if it's not NULL
        Score_Date = GETDATE(),              -- Update Score_Date to the current timestamp
        User_Upload_Status = COALESCE(@User_Upload_Status, User_Upload_Status)   -- Update User_Upload_Status to the current timestamp
    WHERE Submission_num = @Submission_num;

    -- If no records were updated (i.e., record does not exist), perform an insert
    IF @@ROWCOUNT = 0
    BEGIN
        INSERT INTO dbo.ai_sq_scoredSubmission (Submission_num, Source, Score, Score_Date, User_Upload_Status)
        VALUES (@Submission_num, @Source, @Score, GETDATE(), @User_Upload_Status);
    END

    -- Return the updated or inserted record
    SELECT * 
    FROM dbo.ai_sq_scoredSubmission
    WHERE Submission_num = @Submission_num;
END
GO
