CREATE PROCEDURE dbo.sp_InsertOrUpdateJobTriggerNew
    @JsonData NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Job_Id INT;
    DECLARE @Submission_num NVARCHAR(100);
    DECLARE @StartDate DATETIME;
    DECLARE @EndDate DATETIME;
    DECLARE @Batch_ID INT;
    DECLARE @Job_status NVARCHAR(50);
    DECLARE @Message NVARCHAR(200);

    BEGIN TRY
        -- Parse JSON data and populate variables
        SET @Job_Id = JSON_VALUE(@JsonData, '$.Job_Id'); -- If NULL, this indicates an insert operation
        SET @Submission_num = JSON_VALUE(@JsonData, '$.Submission_num');
        SET @StartDate = JSON_VALUE(@JsonData, '$.StartDate');
        SET @EndDate = JSON_VALUE(@JsonData, '$.EndDate');
        SET @Batch_ID = JSON_VALUE(@JsonData, '$.Batch_ID');
        SET @Job_status = JSON_VALUE(@JsonData, '$.Job_status');

        -- Check for required fields (e.g., Submission_num is mandatory)
        IF @Submission_num IS NULL
        BEGIN
            SET @Message = 'Error: Submission_num is required.';
            THROW 50001, @Message, 1;
        END

        -- Check if it's an update or insert based on the presence of Job_Id
        IF EXISTS (SELECT 1 FROM dbo.ai_sq_jobTrigger WHERE Job_Id = @Job_Id)
        BEGIN
            -- Update existing record
            IF @Job_status = 'completed triage'
            BEGIN
                -- Set EndDate to current date/time if not provided
                SET @EndDate = COALESCE(@EndDate, GETDATE());
            END

            UPDATE dbo.ai_sq_jobTrigger
            SET
                Submission_num = COALESCE(@Submission_num, Submission_num),
                StartDate = COALESCE(@StartDate, StartDate),
                EndDate = COALESCE(@EndDate, EndDate),
                Batch_ID = COALESCE(@Batch_ID, Batch_ID),
                Job_status = COALESCE(@Job_status, Job_status)
            WHERE Job_Id = @Job_Id;

            SET @Message = CONCAT('Record updated successfully. Job_Id = ', @Job_Id);
        END
        ELSE
        BEGIN
            -- Insert new record
            IF @Job_status = 'uploaded'
            BEGIN
                -- Set StartDate to current date/time if not provided
                SET @StartDate = COALESCE(@StartDate, GETDATE());
            END

            INSERT INTO dbo.ai_sq_jobTrigger (Submission_num, StartDate, EndDate, Batch_ID, Job_status)
            VALUES (@Submission_num, @StartDate, @EndDate, @Batch_ID, @Job_status);

            -- Retrieve the newly created Job_Id
            SET @Job_Id = SCOPE_IDENTITY();
            SET @Message = CONCAT('Record inserted successfully. Job_Id = ', @Job_Id);
        END
    END TRY
    BEGIN CATCH
        -- Error handling
        SET @Message = ERROR_MESSAGE();
        -- Return error message and set Job_Id to NULL to indicate failure
        SET @Job_Id = NULL;
    END CATCH

    -- Return the Job_Id and status message
    SELECT @Job_Id AS Job_Id, @Message AS StatusMessage;
END
GO
