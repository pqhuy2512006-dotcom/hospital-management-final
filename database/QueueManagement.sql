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
-- 2. PROCEDURE TIẾP NHẬN BỆNH NHÂN (MỖI LẦN CHỈ KHÁM MỘT BỆNH NHÂN)
-- =========================================================================
CREATE OR ALTER PROCEDURE sp_TiepNhanBenhNhan
    @MaLichHen VARCHAR(15),
    @MaPhieuKham VARCHAR(15), -- Frontend truyền xuống hoặc tự sinh
    @MaBacSi VARCHAR(15),
    @MaKhoa VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @TrangThai VARCHAR(20);
        DECLARE @MaBenhNhan VARCHAR(15);
        DECLARE @MaBacSiLichHen VARCHAR(15);

        SELECT @TrangThai = TrangThai,
               @MaBenhNhan = MaBenhNhan,
               @MaBacSiLichHen = MaBacSi
        FROM dbo.LichHen WITH (UPDLOCK, HOLDLOCK)
        WHERE MaLichHen = @MaLichHen;

        IF @TrangThai IS NULL
            THROW 50011, N'Không tìm thấy lịch hẹn.', 1;

        IF @TrangThai NOT IN ('DaDatLich', 'DangChoKham')
            THROW 50012, N'Lịch hẹn không ở trạng thái chờ khám để tiếp nhận.', 1;

        IF @MaBacSiLichHen IS NULL OR @MaBacSiLichHen <> @MaBacSi
            THROW 50013, N'Lịch hẹn không thuộc bác sĩ này.', 1;

        IF EXISTS (
            SELECT 1
            FROM dbo.LichHen WITH (UPDLOCK, HOLDLOCK)
            WHERE MaBacSi = @MaBacSi
              AND TrangThai = 'DangKham'
        )
            THROW 50014, N'Không thể bắt đầu khám: bác sĩ đang khám một bệnh nhân khác.', 1;

        UPDATE dbo.LichHen
        SET TrangThai = 'DangKham'
        WHERE MaLichHen = @MaLichHen
          AND TrangThai IN ('DaDatLich', 'DangChoKham');

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
