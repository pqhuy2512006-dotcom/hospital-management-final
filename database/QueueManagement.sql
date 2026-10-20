USE QuanLyBenhVien;
GO

-- =========================================================================
-- 1. CẬP NHẬT TRẠNG THÁI 'DangKham' VÀO BẢNG LICHHEN
-- =========================================================================
DECLARE @StatusCheck SYSNAME;
SELECT TOP (1) @StatusCheck = name
FROM sys.check_constraints
WHERE parent_object_id = OBJECT_ID(N'dbo.LichHen')
  AND definition LIKE N'%TrangThai%';

IF @StatusCheck IS NOT NULL
BEGIN
    DECLARE @sql NVARCHAR(MAX) = N'ALTER TABLE dbo.LichHen DROP CONSTRAINT ' + QUOTENAME(@StatusCheck);
    EXEC(@sql);
END;
GO

-- Thêm lại Constraint với trạng thái 'DangKham'
ALTER TABLE dbo.LichHen
    ADD CONSTRAINT CK_LichHen_TrangThai
    CHECK (TrangThai IN ('DaDatLich', 'DangChoKham', 'DangKham', 'DaKham', 'DaHuy'));
GO

-- =========================================================================
-- 2. PROCEDURE TIẾP NHẬN BỆNH NHÂN (XỬ LÝ ĐI TRỄ > 10 PHÚT)
-- =========================================================================
CREATE OR ALTER PROCEDURE sp_TiepNhanBenhNhan
    @MaLichHen VARCHAR(15),
    @MaPhieuKham VARCHAR(15), -- Frontend truyền xuống hoặc tự sinh
    @MaBacSi VARCHAR(15),
    @MaKhoa VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @GioHen DATETIME;
    DECLARE @TrangThai VARCHAR(20);
    DECLARE @MaBenhNhan VARCHAR(15);
    DECLARE @DelayMinutes INT;
    
    -- Lấy thông tin lịch hẹn
    SELECT @GioHen = CAST(NgayKham AS DATETIME) + CAST(GioKham AS DATETIME),
           @TrangThai = TrangThai,
           @MaBenhNhan = MaBenhNhan
    FROM dbo.LichHen
    WHERE MaLichHen = @MaLichHen;
    
    IF @TrangThai <> 'DangChoKham'
    BEGIN
        RAISERROR(N'Lịch hẹn không ở trạng thái hợp lệ để tiếp nhận.', 16, 1);
        RETURN;
    END

    
    -- Tính số phút trễ (khoảng cách từ lúc hẹn đến hiện tại)
    SET @DelayMinutes = DATEDIFF(MINUTE, @GioHen, GETDATE());
    
    -- Kiểm tra nếu bác sĩ gọi khám quá sớm (trước giờ hẹn)
    IF @DelayMinutes < 0
    BEGIN
        RAISERROR(N'Chưa tới giờ hẹn. Không thể bắt đầu khám sớm hơn lịch trình được xếp!', 16, 1);
        RETURN;
    END

    -- Nếu đến trễ quá 10 phút, TỰ ĐỘNG HỦY
    IF @DelayMinutes > 10
    BEGIN
        UPDATE dbo.LichHen 
        SET TrangThai = 'DaHuy'
        WHERE MaLichHen = @MaLichHen;
        
        RAISERROR(N'Bệnh nhân đã đến trễ quá 10 phút. Lịch hẹn đã bị tự động hủy!', 16, 1);
        RETURN;
    END
    
    -- Nếu hợp lệ (<= 10 phút), tạo phiếu khám và chuyển trạng thái
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Cập nhật Lịch hẹn
        UPDATE dbo.LichHen
        SET TrangThai = 'DangKham'
        WHERE MaLichHen = @MaLichHen;
        
        -- Tạo Phiếu khám (với NgayKham = GETDATE() mặc định làm thời điểm bắt đầu)
        INSERT INTO dbo.PhieuKham (MaPhieuKham, MaBenhNhan, MaBacSi, MaKhoa, MaLichHen, NgayKham)
        VALUES (@MaPhieuKham, @MaBenhNhan, @MaBacSi, @MaKhoa, @MaLichHen, GETDATE());
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

