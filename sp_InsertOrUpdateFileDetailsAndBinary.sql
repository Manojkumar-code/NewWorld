CREATE PROCEDURE dbo.sp_ai_sq_upsert_file_details_and_binary
    @JsonData NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Object_Id NVARCHAR(255);
    DECLARE @Submission_num NVARCHAR(100);
    DECLARE @UploadedFileName NVARCHAR(255);
    DECLARE @Batch_Type NVARCHAR(100);
    DECLARE @SavedFilePath NVARCHAR(255);
    DECLARE @SavedFileName NVARCHAR(255);
    DECLARE @CreateDate DATETIME;
    DECLARE @ModifyDate DATETIME;
    DECLARE @ContentType NVARCHAR(255);
    DECLARE @Doc_Class NVARCHAR(255);
    DECLARE @OBU NVARCHAR(100);
    DECLARE @AccountName NVARCHAR(255);
    DECLARE @AccountNumber NVARCHAR(255);
    DECLARE @Status NVARCHAR(255);
    DECLARE @Status_UpdateTime DATETIME;
    DECLARE @Byte_object VARBINARY(MAX);
    DECLARE @Message NVARCHAR(200);

    BEGIN TRY
        -- Parse JSON data and populate variables for ai_sq_fileDetails
        SET @Submission_num = JSON_VALUE(@JsonData, '$.Submission_num');
        SET @UploadedFileName = JSON_VALUE(@JsonData, '$.UploadedFileName');
        SET @Batch_Type = JSON_VALUE(@JsonData, '$.Batch_Type');
        SET @SavedFilePath = JSON_VALUE(@JsonData, '$.SavedFilePath');
        SET @SavedFileName = JSON_VALUE(@JsonData, '$.SavedFileName');
        SET @CreateDate = COALESCE(JSON_VALUE(@JsonData, '$.CreateDate'), GETDATE());
        SET @ModifyDate = GETDATE();
        SET @ContentType = JSON_VALUE(@JsonData, '$.ContentType');
        SET @Doc_Class = JSON_VALUE(@JsonData, '$.Doc_Class');
        SET @OBU = JSON_VALUE(@JsonData, '$.OBU');
        SET @AccountName = JSON_VALUE(@JsonData, '$.AccountName');
        SET @AccountNumber = JSON_VALUE(@JsonData, '$.AccountNumber');
        SET @Status_UpdateTime = GETDATE();

        -- Parse and convert Byte_object from base64 to binary
        DECLARE @Byte_object_base64 NVARCHAR(MAX) = JSON_VALUE(@JsonData, '$.Byte_object');
        SET @Byte_object = CAST('' AS XML).value('xs:base64Binary(sql:variable("@Byte_object_base64"))', 'VARBINARY(MAX)');

        -- Check for required fields
        IF @Submission_num IS NULL OR @Batch_Type IS NULL
        BEGIN
            THROW 50001, 'Error: Submission_num, and Batch_Type are required.', 1;
        END

        -- Determine Object_Id based on Batch_Type
        IF @Batch_Type = 'User_Upload'
        BEGIN
            -- Generate Object_Id based on Submission_num and UploadedFileName
            IF @UploadedFileName IS NULL
            BEGIN
                THROW 50002, 'Error: UploadedFileName is required for User_Upload Batch_Type.', 1;
            END
            SET @Object_Id = CONCAT(CAST(@Submission_num AS NVARCHAR(255)), '_', @UploadedFileName);
            SET @Status = 'Processed';
        END
        ELSE IF @Batch_Type = 'Schedule'
        BEGIN
            -- Take Object_Id from input JSON for Schedule type
            SET @Object_Id = JSON_VALUE(@JsonData, '$.Object_Id');
            IF @Object_Id IS NULL
            BEGIN
                THROW 50003, 'Error: Object_Id is required for Schedule Batch_Type.', 1;
            END
            SET @Status = 'Uploaded';
        END
        ELSE
        BEGIN
            THROW 50004, 'Error: Invalid Batch_Type value. Must be "User_Upload" or "Schedule".', 1;
        END

        -- Validate Status value
        IF @Status NOT IN ('Uploaded', 'In Progress', 'Processed')
        BEGIN
            THROW 50005, 'Error: Invalid Status value.', 1;
        END

        -- Check if ai_sq_fileDetails record exists for update or insert
        IF EXISTS (SELECT 1 FROM dbo.ai_sq_fileDetails WHERE Object_Id = @Object_Id)
        BEGIN
            -- Update ai_sq_fileDetails record
            UPDATE dbo.ai_sq_fileDetails
            SET
                Submission_num = COALESCE(@Submission_num, Submission_num),
                UploadedFileName = COALESCE(@UploadedFileName, UploadedFileName),
                Batch_Type = COALESCE(@Batch_Type, Batch_Type),
                SavedFilePath = COALESCE(@SavedFilePath, SavedFilePath),
                SavedFileName = COALESCE(@SavedFileName, SavedFileName),
                CreateDate = COALESCE(@CreateDate, CreateDate),
                ModifyDate = @ModifyDate,
                ContentType = COALESCE(@ContentType, ContentType),
                Doc_Class = COALESCE(@Doc_Class, Doc_Class),
                OBU = COALESCE(@OBU, OBU),
                AccountName = COALESCE(@AccountName, AccountName),
                AccountNumber = COALESCE(@AccountNumber, AccountNumber),
                Status = COALESCE(@Status, Status),
                Status_UpdateTime = @Status_UpdateTime
            WHERE Object_Id = @Object_Id;

            SET @Message = CONCAT('Record updated successfully in ai_sq_fileDetails. Object_Id = ', @Object_Id);
        END
        ELSE
        BEGIN
            -- Insert new record into ai_sq_fileDetails
            INSERT INTO dbo.ai_sq_fileDetails (Object_Id, Submission_num, UploadedFileName, Batch_Type, SavedFilePath, 
                                               SavedFileName, CreateDate, ModifyDate, ContentType, Doc_Class, OBU, 
                                               AccountName, AccountNumber, Status, Status_UpdateTime)
            VALUES (@Object_Id, @Submission_num, @UploadedFileName, @Batch_Type, @SavedFilePath, 
                    @SavedFileName, @CreateDate, @ModifyDate, @ContentType, @Doc_Class, @OBU, 
                    @AccountName, @AccountNumber, @Status, @Status_UpdateTime);

            SET @Message = CONCAT('Record inserted successfully in ai_sq_fileDetails. Object_Id = ', @Object_Id);
        END

        -- Insert or update ai_sq_fileBinary only for User_Upload
        IF @Batch_Type = 'User_Upload'
        BEGIN
            -- Insert new record into ai_sq_fileBinary
            INSERT INTO dbo.ai_sq_fileBinary (Object_Id, Byte_object)
            VALUES (@Object_Id, @Byte_object);
        END

    END TRY
    BEGIN CATCH
        -- Error handling
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH

    -- Return the Object_Id, status message, and full details of the inserted/updated record
    SELECT 
        @Object_Id AS Object_Id, 
        @Message AS StatusMessage;

    -- Return the Object_Id and status message
     SELECT *
    FROM dbo.ai_sq_fileDetails
    WHERE Object_Id = @Object_Id;
END
GO
