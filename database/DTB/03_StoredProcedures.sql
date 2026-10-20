-- Stored procedures
USE [QuanLyBenhVien];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE   PROCEDURE dbo.sp_GiuongBenh_Save
    @MaGiuong VARCHAR(15) = NULL,
    @MaPhong VARCHAR(15) = NULL,
    @SoGiuong NVARCHAR(50),
    @DonGiaNgay DECIMAL(18, 2) = 250000
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Nếu chưa có mã giường (tạo mới) -> Tự động sinh mã: [Mã Phòng]-[Số Giường]
    IF @MaGiuong IS NULL OR LTRIM(RTRIM(@MaGiuong)) = ''
    BEGIN
        SET @MaGiuong = @MaPhong + '-' + REPLACE(@SoGiuong, ' ', '');
    END

    -- 2. Kiểm tra nếu ĐÃ TỒN TẠI mã giường -> Chạy UPDATE (Sửa)
    IF EXISTS (SELECT 1 FROM GiuongBenh WHERE MaGiuong = @MaGiuong)
    BEGIN
        UPDATE GiuongBenh
        SET SoGiuong = @SoGiuong,
            DonGiaNgay = @DonGiaNgay
        WHERE MaGiuong = @MaGiuong;
    END
    -- 3. Nếu CHƯA CÓ mã giường -> Chạy INSERT (Tạo mới)
    ELSE
    BEGIN
        INSERT INTO GiuongBenh (MaGiuong, SoGiuong, MaPhong, DonGiaNgay, TrangThai)
        VALUES (@MaGiuong, @SoGiuong, @MaPhong, @DonGiaNgay, 'Trong');
    END
END;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE   PROCEDURE dbo.sp_GiuongBenh_ToggleStatus
    @MaGiuong VARCHAR(15)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE GiuongBenh
    SET TrangThai = CASE 
        WHEN TrangThai = 'BaoTri' THEN 'Trong'
        WHEN TrangThai = 'Trong' THEN 'BaoTri'
        ELSE TrangThai 
    END
    WHERE MaGiuong = @MaGiuong;
END;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE   PROCEDURE dbo.sp_Khoa_Save
    @MaKhoa VARCHAR(10),
    @TenKhoa NVARCHAR(100),
    @MoTa NVARCHAR(300) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM Khoa WHERE MaKhoa = @MaKhoa)
    BEGIN
        UPDATE Khoa 
        SET TenKhoa = @TenKhoa, MoTa = @MoTa
        WHERE MaKhoa = @MaKhoa;
    END
    ELSE
    BEGIN
        INSERT INTO Khoa (MaKhoa, TenKhoa, MoTa, TrangThai)
        VALUES (@MaKhoa, @TenKhoa, @MoTa, 1);
    END
END;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE dbo.sp_Khoa_ToggleStatus  
    @MaKhoa VARCHAR(10)  
AS  
BEGIN  
    SET NOCOUNT ON;  
    DECLARE @CurrentStatus BIT;  
    SELECT @CurrentStatus = ISNULL(TrangThai, 1) FROM Khoa WHERE MaKhoa = @MaKhoa;  
  
    IF @CurrentStatus = 1  
    BEGIN  
        -- Đổi Khoa sang Tạm ngưng (0)  
        UPDATE Khoa SET TrangThai = 0 WHERE MaKhoa = @MaKhoa;  
  
        -- Khóa tất cả Phòng thuộc khoa  
        UPDATE Phong SET TrangThai = 0 WHERE MaKhoa = @MaKhoa;  
  
        -- Khóa tất cả Giường trống thuộc các phòng của khoa này (JOIN qua Phong)  
        UPDATE g  
        SET g.TrangThai = 'BaoTri'  
        FROM GiuongBenh g  
        INNER JOIN Phong p ON g.MaPhong = p.MaPhong  
        WHERE p.MaKhoa = @MaKhoa AND g.TrangThai = 'Trong';  
  
        -- Hủy các lịch hẹn tương lai chưa khám  
        DECLARE @AffectedAppointments TABLE (MaLichHen VARCHAR(15), MaTaiKhoan BIGINT, NgayKham DATE);  
          
        INSERT INTO @AffectedAppointments (MaLichHen, MaTaiKhoan, NgayKham)  
        SELECT lh.MaLichHen, bn.MaTaiKhoan, lh.NgayKham  
        FROM LichHen lh  
        inner JOIN BenhNhan bn ON lh.MaBenhNhan = bn.MaBenhNhan  
        WHERE lh.MaKhoa = @MaKhoa   
          AND lh.NgayKham >= CAST(GETDATE() AS DATE)  
          AND lh.TrangThai = 'DaDatLich';  
  
        UPDATE LichHen   
        SET TrangThai = 'DaHuy'   
        WHERE MaLichHen IN (SELECT MaLichHen FROM @AffectedAppointments);  
  
        -- Bắn thông báo cho bệnh nhân  
        DECLARE @TenKhoa NVARCHAR(100);  
        SELECT @TenKhoa = TenKhoa FROM Khoa WHERE MaKhoa = @MaKhoa;  
  
        INSERT INTO ThongBao (MaTaiKhoan, TieuDe, NoiDung, LoaiThongBao, DaDoc, NgayTao)  
        SELECT   
            aa.MaTaiKhoan,  
            N'Thông báo hủy lịch hẹn do Khoa tạm ngưng tiếp nhận',  
            N'Lịch hẹn ngày ' + CONVERT(VARCHAR, aa.NgayKham, 103) + N' tại ' + @TenKhoa + N' đã được tự động hủy do Khoa tạm ngưng hoạt động. Quý khách vui lòng đặt lại lịch tại khoa khác hoặc liên hệ bộ phận Tiếp đón.',  
            N'LICH_HEN',  
            0,  
            GETDATE()  
        FROM @AffectedAppointments aa  
        WHERE aa.MaTaiKhoan IS NOT NULL;  
    END  
    ELSE  
    BEGIN  
        -- Mở lại hoạt động Khoa (1)  
        UPDATE Khoa SET TrangThai = 1 WHERE MaKhoa = @MaKhoa;  
  
        -- Mở lại tất cả Phòng thuộc khoa  
        UPDATE Phong SET TrangThai = 1 WHERE MaKhoa = @MaKhoa;  
  
        -- Mở lại các giường 'BaoTri' về lại 'Trong' (JOIN qua Phong)  
        UPDATE g  
        SET g.TrangThai = 'Trong'  
        FROM GiuongBenh g  
        INNER JOIN Phong p ON g.MaPhong = p.MaPhong  
        WHERE p.MaKhoa = @MaKhoa AND g.TrangThai = 'BaoTri';  
    END  
END;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE   PROCEDURE dbo.sp_Phong_Save
    @MaPhong VARCHAR(15),
    @TenPhong NVARCHAR(100),
    @LoaiPhong VARCHAR(20),
    @MaKhoa VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM Phong WHERE MaPhong = @MaPhong)
    BEGIN
        UPDATE Phong 
        SET TenPhong = @TenPhong, LoaiPhong = @LoaiPhong, MaKhoa = @MaKhoa
        WHERE MaPhong = @MaPhong;
    END
    ELSE
    BEGIN
        INSERT INTO Phong (MaPhong, TenPhong, LoaiPhong, MaKhoa, TrangThai)
        VALUES (@MaPhong, @TenPhong, @LoaiPhong, @MaKhoa, 1);
    END
END;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE   PROCEDURE dbo.sp_Phong_ToggleStatus
    @MaPhong VARCHAR(15)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @NewStatus BIT;
    SELECT @NewStatus = CASE WHEN ISNULL(TrangThai, 1) = 1 THEN 0 ELSE 1 END 
    FROM Phong 
    WHERE MaPhong = @MaPhong;

    -- Cập nhật trạng thái Phòng
    UPDATE Phong 
    SET TrangThai = @NewStatus
    WHERE MaPhong = @MaPhong;

    -- Nếu Phòng Tạm ngưng (0): Chuyển các giường Trống trong phòng sang 'BaoTri'
    IF @NewStatus = 0
    BEGIN
        UPDATE GiuongBenh
        SET TrangThai = 'BaoTri'
        WHERE MaPhong = @MaPhong AND TrangThai = 'Trong';
    END
    -- Nếu Phòng Mở lại (1): Trả các giường 'BaoTri' về lại 'Trong'
    ELSE
    BEGIN
        UPDATE GiuongBenh
        SET TrangThai = 'Trong'
        WHERE MaPhong = @MaPhong AND TrangThai = 'BaoTri';
    END
END;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER OFF;
GO

-- Stored Procedure: Tá»± Ä‘á»™ng nháº¯c lá»‹ch háº¹n ngÃ y mai
CREATE PROCEDURE dbo.sp_TaoThongBaoNhacLich
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO dbo.ThongBao (MaTaiKhoan, TieuDe, NoiDung, LoaiThongBao)
    SELECT 
        tk.MaTaiKhoan,
        N'Nháº¯c nhá»Ÿ lá»‹ch háº¹n khÃ¡m bá»‡nh',
        N'Báº¡n cÃ³ lá»‹ch khÃ¡m vÃ o ngÃ y mai lÃºc ' + CONVERT(VARCHAR(5), lh.GioKham, 108) + N'. Vui lÃ²ng cÃ³ máº·t Ä‘Ãºng giá» Ä‘á»ƒ Ä‘Æ°á»£c phá»¥c vá»¥ tá»‘t nháº¥t.',
        'NHAC_LICH'
    FROM dbo.LichHen lh
    JOIN dbo.BenhNhan bn ON lh.MaBenhNhan = bn.MaBenhNhan
    JOIN dbo.TaiKhoan tk ON bn.MaTaiKhoan = tk.MaTaiKhoan
    WHERE lh.TrangThai = 'DaDatLich' 
      AND CAST(lh.NgayKham AS DATE) = CAST(DATEADD(DAY, 1, GETDATE()) AS DATE)
      AND NOT EXISTS (
          SELECT 1 FROM dbo.ThongBao tb 
          WHERE tb.MaTaiKhoan = tk.MaTaiKhoan 
            AND tb.LoaiThongBao = 'NHAC_LICH' 
            AND CAST(tb.NgayTao AS DATE) = CAST(GETDATE() AS DATE)
      );
END;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
-- 
CREATE   PROCEDURE dbo.sp_ThongBao_Broadcast
    @TieuDe NVARCHAR(200),
    @NoiDung NVARCHAR(1000),
    @LoaiThongBao VARCHAR(50),
    @TargetRole VARCHAR(20) = 'ALL'
AS
BEGIN
    SET NOCOUNT ON;
    -- Lấy danh sách tài khoản từ VIEW dbo.vw_TaiKhoan theo nhóm chỉ định
    IF @TargetRole IS NULL OR @TargetRole = '' OR UPPER(@TargetRole) = 'ALL'
    BEGIN
        INSERT INTO dbo.ThongBao (MaTaiKhoan, TieuDe, NoiDung, LoaiThongBao, DaDoc, NgayTao)
        SELECT MaTaiKhoan, @TieuDe, @NoiDung, @LoaiThongBao, 0, GETDATE()
        FROM dbo.vw_TaiKhoan
        WHERE TrangThai = 1;
    END
    ELSE IF UPPER(@TargetRole) = 'STAFF'
    BEGIN
        INSERT INTO dbo.ThongBao (MaTaiKhoan, TieuDe, NoiDung, LoaiThongBao, DaDoc, NgayTao)
        SELECT MaTaiKhoan, @TieuDe, @NoiDung, @LoaiThongBao, 0, GETDATE()
        FROM dbo.vw_TaiKhoan
        WHERE TrangThai = 1 AND VaiTro <> 'BenhNhan';
    END
    ELSE
    BEGIN
        INSERT INTO dbo.ThongBao (MaTaiKhoan, TieuDe, NoiDung, LoaiThongBao, DaDoc, NgayTao)
        SELECT MaTaiKhoan, @TieuDe, @NoiDung, @LoaiThongBao, 0, GETDATE()
        FROM dbo.vw_TaiKhoan
        WHERE TrangThai = 1 AND VaiTro = @TargetRole;
    END
    -- Trả về số lượng người nhận thực tế
    SELECT @@ROWCOUNT AS SoNguoiNhan;
END;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE   PROCEDURE dbo.sp_ThongBao_Create
    @MaTaiKhoan BIGINT,
    @TieuDe NVARCHAR(200),
    @NoiDung NVARCHAR(1000),
    @LoaiThongBao VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.ThongBao (MaTaiKhoan, TieuDe, NoiDung, LoaiThongBao, DaDoc, NgayTao)
    VALUES (@MaTaiKhoan, @TieuDe, @NoiDung, @LoaiThongBao, 0, GETDATE());
END;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER OFF;
GO

-- Stored Procedure Ä‘Ã¡nh dáº¥u Ä‘Ã£ Ä‘á»c
CREATE PROCEDURE dbo.sp_ThongBao_MarkRead
    @MaThongBao INT,
    @MaTaiKhoan BIGINT
AS
BEGIN
    UPDATE dbo.ThongBao
    SET DaDoc = 1
    WHERE MaThongBao = @MaThongBao AND MaTaiKhoan = @MaTaiKhoan;
END;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER OFF;
GO

-- =========================================================================
-- 2. PROCEDURE TIáº¾P NHáº¬N Bá»†NH NHÃ‚N (Xá»¬ LÃ ÄI TRá»„ > 10 PHÃšT)
-- =========================================================================
CREATE   PROCEDURE sp_TiepNhanBenhNhan
    @MaLichHen VARCHAR(15),
    @MaPhieuKham VARCHAR(15), -- Frontend truyá»n xuá»‘ng hoáº·c tá»± sinh
    @MaBacSi VARCHAR(15),
    @MaKhoa VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @GioHen DATETIME;
    DECLARE @TrangThai VARCHAR(20);
    DECLARE @MaBenhNhan VARCHAR(15);
    DECLARE @DelayMinutes INT;
    
    -- Láº¥y thÃ´ng tin lá»‹ch háº¹n
    SELECT @GioHen = CAST(NgayKham AS DATETIME) + CAST(GioKham AS DATETIME),
           @TrangThai = TrangThai,
           @MaBenhNhan = MaBenhNhan
    FROM dbo.LichHen
    WHERE MaLichHen = @MaLichHen;
    
    IF @TrangThai <> 'DangChoKham'
    BEGIN
        RAISERROR(N'Lá»‹ch háº¹n khÃ´ng á»Ÿ tráº¡ng thÃ¡i há»£p lá»‡ Ä‘á»ƒ tiáº¿p nháº­n.', 16, 1);
        RETURN;
    END

    
    -- TÃ­nh sá»‘ phÃºt trá»… (khoáº£ng cÃ¡ch tá»« lÃºc háº¹n Ä‘áº¿n hiá»‡n táº¡i)
    SET @DelayMinutes = DATEDIFF(MINUTE, @GioHen, GETDATE());
    
    -- Kiá»ƒm tra náº¿u bÃ¡c sÄ© gá»i khÃ¡m quÃ¡ sá»›m (trÆ°á»›c giá» háº¹n)
    IF @DelayMinutes < 0
    BEGIN
        RAISERROR(N'ChÆ°a tá»›i giá» háº¹n. KhÃ´ng thá»ƒ báº¯t Ä‘áº§u khÃ¡m sá»›m hÆ¡n lá»‹ch trÃ¬nh Ä‘Æ°á»£c xáº¿p!', 16, 1);
        RETURN;
    END

    -- Náº¿u Ä‘áº¿n trá»… quÃ¡ 10 phÃºt, Tá»° Äá»˜NG Há»¦Y
    IF @DelayMinutes > 10
    BEGIN
        UPDATE dbo.LichHen 
        SET TrangThai = 'DaHuy'
        WHERE MaLichHen = @MaLichHen;
        
        RAISERROR(N'Bá»‡nh nhÃ¢n Ä‘Ã£ Ä‘áº¿n trá»… quÃ¡ 10 phÃºt. Lá»‹ch háº¹n Ä‘Ã£ bá»‹ tá»± Ä‘á»™ng há»§y!', 16, 1);
        RETURN;
    END
    
    -- Náº¿u há»£p lá»‡ (<= 10 phÃºt), táº¡o phiáº¿u khÃ¡m vÃ  chuyá»ƒn tráº¡ng thÃ¡i
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Cáº­p nháº­t Lá»‹ch háº¹n
        UPDATE dbo.LichHen
        SET TrangThai = 'DangKham'
        WHERE MaLichHen = @MaLichHen;
        
        -- Táº¡o Phiáº¿u khÃ¡m (vá»›i NgayKham = GETDATE() máº·c Ä‘á»‹nh lÃ m thá»i Ä‘iá»ƒm báº¯t Ä‘áº§u)
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

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE   PROCEDURE dbo.usp_Entity_Delete
    @EntityName SYSNAME,
    @IdValue NVARCHAR(4000)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TableName SYSNAME = CASE @EntityName
        WHEN N'AuditLog' THEN N'AuditLog'
        WHEN N'BenhNhan' THEN N'BenhNhan'
        WHEN N'ChiTietHoaDon' THEN N'ChiTietHoaDon'
        WHEN N'ChiTietKetQuaCLS' THEN N'ChiTietKetQuaCLS'
        WHEN N'ChiTietNhapKho' THEN N'ChiTietNhapKho'
        WHEN N'DichVuCLS' THEN N'DichVuCLS'
        WHEN N'DonThuoc' THEN N'DonThuoc'
        WHEN N'GiuongBenh' THEN N'GiuongBenh'
        WHEN N'HoaDon' THEN N'HoaDon'
        WHEN N'KetQuaCLS' THEN N'KetQuaCLS'
        WHEN N'Khoa' THEN N'Khoa'
        WHEN N'LichHen' THEN N'LichHen'
        WHEN N'LichTruc' THEN N'LichTruc'
        WHEN N'NhanVien' THEN N'NhanVien'
        WHEN N'NoiTru' THEN N'NoiTru'
        WHEN N'PhieuKham' THEN N'PhieuKham'
        WHEN N'PhieuNhapKho' THEN N'PhieuNhapKho'
        WHEN N'Thuoc' THEN N'Thuoc'
        WHEN N'YeuCauChuyenKhoa' THEN N'YeuCauChuyenKhoa'
        ELSE NULL
    END;

    IF @TableName IS NULL
        THROW 50002, 'Entity is not allowed for generic persistence.', 1;

    DECLARE @ObjectId INT = OBJECT_ID(N'dbo.' + QUOTENAME(@TableName), N'U');
    DECLARE @KeyColumn SYSNAME;
    SELECT @KeyColumn = c.name
    FROM sys.key_constraints kc
    JOIN sys.index_columns ic ON ic.object_id = kc.parent_object_id AND ic.index_id = kc.unique_index_id
    JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
    WHERE kc.parent_object_id = @ObjectId AND kc.type = N'PK';

    IF @KeyColumn IS NULL
        THROW 50003, 'Entity table has no primary key.', 1;

    DECLARE @DeleteSql NVARCHAR(MAX) = N'DELETE FROM dbo.' + QUOTENAME(@TableName)
        + N' WHERE ' + QUOTENAME(@KeyColumn) + N' = @Value;';
    EXEC sys.sp_executesql @DeleteSql, N'@Value NVARCHAR(4000)', @Value = @IdValue;
END;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE   PROCEDURE dbo.usp_Entity_Save
    @EntityName SYSNAME,
    @Payload NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    IF ISJSON(@Payload) <> 1
        THROW 50001, 'Entity payload must be valid JSON.', 1;

    DECLARE @TableName SYSNAME = CASE @EntityName
        WHEN N'AuditLog' THEN N'AuditLog'
        WHEN N'BenhNhan' THEN N'BenhNhan'
        WHEN N'ChiTietHoaDon' THEN N'ChiTietHoaDon'
        WHEN N'ChiTietKetQuaCLS' THEN N'ChiTietKetQuaCLS'
        WHEN N'ChiTietNhapKho' THEN N'ChiTietNhapKho'
        WHEN N'DichVuCLS' THEN N'DichVuCLS'
        WHEN N'DonThuoc' THEN N'DonThuoc'
        WHEN N'GiuongBenh' THEN N'GiuongBenh'
        WHEN N'HoaDon' THEN N'HoaDon'
        WHEN N'KetQuaCLS' THEN N'KetQuaCLS'
        WHEN N'Khoa' THEN N'Khoa'
        WHEN N'LichHen' THEN N'LichHen'
        WHEN N'LichTruc' THEN N'LichTruc'
        WHEN N'NhanVien' THEN N'NhanVien'
        WHEN N'NoiTru' THEN N'NoiTru'
        WHEN N'PhieuKham' THEN N'PhieuKham'
        WHEN N'PhieuNhapKho' THEN N'PhieuNhapKho'
        WHEN N'Thuoc' THEN N'Thuoc'
        WHEN N'YeuCauChuyenKhoa' THEN N'YeuCauChuyenKhoa'
        ELSE NULL
    END;

    IF @TableName IS NULL
        THROW 50002, 'Entity is not allowed for generic persistence.', 1;

    DECLARE @ObjectId INT = OBJECT_ID(N'dbo.' + QUOTENAME(@TableName), N'U');
    DECLARE @KeyColumn SYSNAME;
    SELECT @KeyColumn = c.name
    FROM sys.key_constraints kc
    JOIN sys.index_columns ic ON ic.object_id = kc.parent_object_id AND ic.index_id = kc.unique_index_id
    JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
    WHERE kc.parent_object_id = @ObjectId AND kc.type = N'PK';

    IF @KeyColumn IS NULL
        THROW 50003, 'Entity table has no primary key.', 1;

    DECLARE @QualifiedTable NVARCHAR(300) = N'dbo.' + QUOTENAME(@TableName);
    DECLARE @KeyValue NVARCHAR(4000) = JSON_VALUE(@Payload, N'$.' + QUOTENAME(@KeyColumn, '"'));
    DECLARE @InsertColumns NVARCHAR(MAX);
    DECLARE @InsertValues NVARCHAR(MAX);
    DECLARE @UpdateSet NVARCHAR(MAX);

    SELECT
        @InsertColumns = STRING_AGG(CONVERT(NVARCHAR(MAX), QUOTENAME(c.name)), N',') WITHIN GROUP (ORDER BY c.column_id),
        @InsertValues = STRING_AGG(CONVERT(NVARCHAR(MAX), N'(SELECT [value] FROM OPENJSON(@Payload) WHERE [key] = N''' + REPLACE(c.name, N'''', N'''''') + N''')'), N',') WITHIN GROUP (ORDER BY c.column_id)
    FROM sys.columns c
    WHERE c.object_id = @ObjectId
      AND c.is_identity = 0
      AND c.is_computed = 0
      AND c.generated_always_type = 0
    AND EXISTS (SELECT 1 FROM OPENJSON(@Payload) j
            WHERE j.[key] COLLATE DATABASE_DEFAULT = c.name COLLATE DATABASE_DEFAULT);

    SELECT @UpdateSet = STRING_AGG(
        CONVERT(NVARCHAR(MAX), QUOTENAME(c.name) + N' = (SELECT [value] FROM OPENJSON(@Payload) WHERE [key] = N''' + REPLACE(c.name, N'''', N'''''') + N''')'),
        N',') WITHIN GROUP (ORDER BY c.column_id)
    FROM sys.columns c
    WHERE c.object_id = @ObjectId
      AND c.name <> @KeyColumn
      AND c.is_identity = 0
      AND c.is_computed = 0
      AND c.generated_always_type = 0
    AND EXISTS (SELECT 1 FROM OPENJSON(@Payload) j
            WHERE j.[key] COLLATE DATABASE_DEFAULT = c.name COLLATE DATABASE_DEFAULT);

    IF @KeyValue IS NOT NULL
    BEGIN
        DECLARE @Exists BIT = 0;
        DECLARE @ExistsSql NVARCHAR(MAX) = N'SELECT @Found = CASE WHEN EXISTS (SELECT 1 FROM ' + @QualifiedTable
            + N' WHERE ' + QUOTENAME(@KeyColumn) + N' = @Value) THEN 1 ELSE 0 END;';
        EXEC sys.sp_executesql @ExistsSql,
            N'@Value NVARCHAR(4000), @Found BIT OUTPUT', @Value = @KeyValue, @Found = @Exists OUTPUT;

        IF @Exists = 1
        BEGIN
            IF @UpdateSet IS NULL RETURN;
            DECLARE @UpdateSql NVARCHAR(MAX) = N'UPDATE ' + @QualifiedTable + N' SET ' + @UpdateSet
                + N' WHERE ' + QUOTENAME(@KeyColumn) + N' = @Value;';
            EXEC sys.sp_executesql @UpdateSql,
                N'@Payload NVARCHAR(MAX), @Value NVARCHAR(4000)', @Payload = @Payload, @Value = @KeyValue;
            RETURN;
        END
    END

    IF @InsertColumns IS NULL
        THROW 50004, 'No writable entity columns found in payload.', 1;

    DECLARE @InsertSql NVARCHAR(MAX) = N'INSERT INTO ' + @QualifiedTable + N' (' + @InsertColumns
        + N') SELECT ' + @InsertValues + N';';
    EXEC sys.sp_executesql @InsertSql, N'@Payload NVARCHAR(MAX)', @Payload = @Payload;
END;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE   PROCEDURE dbo.usp_TaiKhoan_Insert
    @TenDangNhap VARCHAR(50),
    @MatKhauHash VARCHAR(255),
    @Email VARCHAR(100) = NULL,
    @SoDienThoai VARCHAR(15),
    @VaiTro VARCHAR(20),
    @TrangThai BIT,
    @NgayTao DATETIME,
    @MaTaiKhoan BIGINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.TaiKhoan (TenDangNhap, MatKhauHash, Email, SoDienThoai, VaiTro, TrangThai, NgayTao)
    VALUES (@TenDangNhap, @MatKhauHash, @Email, @SoDienThoai, @VaiTro, @TrangThai, @NgayTao);

    SET @MaTaiKhoan = CONVERT(BIGINT, SCOPE_IDENTITY());
END;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE   PROCEDURE dbo.usp_TaiKhoan_Update
    @MaTaiKhoan BIGINT,
    @MatKhauHash VARCHAR(255),
    @Email VARCHAR(100) = NULL,
    @SoDienThoai VARCHAR(15),
    @VaiTro VARCHAR(20),
    @TrangThai BIT,
    @NgayTao DATETIME
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.TaiKhoan
    SET MatKhauHash = @MatKhauHash,
        Email = @Email,
        SoDienThoai = @SoDienThoai,
        VaiTro = @VaiTro,
        TrangThai = @TrangThai,
        NgayTao = @NgayTao
    WHERE MaTaiKhoan = @MaTaiKhoan;
END;
GO
