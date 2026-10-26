/* ======================================================================
   04_StoredProcedures.sql - Stored Procedures (16 SPs)
   Bao gồm 5 nghiệp vụ có áp dụng TRANSACTION và TRY...CATCH
   ====================================================================== */
USE QuanLyBenhVien;
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- 1. Lưu Giường
CREATE OR ALTER PROCEDURE dbo.sp_GiuongBenh_Save
    @MaGiuong VARCHAR(15) = NULL, @MaPhong VARCHAR(15) = NULL, @SoGiuong NVARCHAR(50), @DonGiaNgay DECIMAL(18, 2) = 250000
AS
BEGIN
    SET NOCOUNT ON;
    IF @MaGiuong IS NULL OR LTRIM(RTRIM(@MaGiuong)) = '' SET @MaGiuong = @MaPhong + '-' + REPLACE(@SoGiuong, ' ', '');
    IF EXISTS (SELECT 1 FROM GiuongBenh WHERE MaGiuong = @MaGiuong)
        UPDATE GiuongBenh SET SoGiuong = @SoGiuong, DonGiaNgay = @DonGiaNgay WHERE MaGiuong = @MaGiuong;
    ELSE
        INSERT INTO GiuongBenh (MaGiuong, SoGiuong, MaPhong, DonGiaNgay, TrangThai) VALUES (@MaGiuong, @SoGiuong, @MaPhong, @DonGiaNgay, 'Trong');
END;
GO

-- 2. Đảo trạng thái Giường bệnh (Có Transaction & Try Catch)
CREATE OR ALTER PROCEDURE dbo.sp_GiuongBenh_ToggleStatus @MaGiuong VARCHAR(15) AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE GiuongBenh SET TrangThai = CASE WHEN TrangThai = 'BaoTri' THEN 'Trong' WHEN TrangThai = 'Trong' THEN 'BaoTri' ELSE TrangThai END WHERE MaGiuong = @MaGiuong;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- 3. Lưu Khoa
CREATE OR ALTER PROCEDURE dbo.sp_Khoa_Save @MaKhoa VARCHAR(10), @TenKhoa NVARCHAR(100), @MoTa NVARCHAR(300) = NULL AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM Khoa WHERE MaKhoa = @MaKhoa) UPDATE Khoa SET TenKhoa = @TenKhoa, MoTa = @MoTa WHERE MaKhoa = @MaKhoa;
    ELSE INSERT INTO Khoa (MaKhoa, TenKhoa, MoTa, TrangThai) VALUES (@MaKhoa, @TenKhoa, @MoTa, 1);
END;
GO

-- 4. Đảo trạng thái hoạt động của Khoa (Có Transaction & Try Catch)
CREATE OR ALTER PROCEDURE dbo.sp_Khoa_ToggleStatus @MaKhoa VARCHAR(10) AS  
BEGIN  
    SET NOCOUNT ON;  
    BEGIN TRY
        BEGIN TRANSACTION;
        DECLARE @CurrentStatus BIT;  
        SELECT @CurrentStatus = ISNULL(TrangThai, 1) FROM Khoa WHERE MaKhoa = @MaKhoa;  
      
        IF @CurrentStatus = 1  
        BEGIN  
            UPDATE Khoa SET TrangThai = 0 WHERE MaKhoa = @MaKhoa;  
            UPDATE Phong SET TrangThai = 0 WHERE MaKhoa = @MaKhoa;  
            UPDATE g SET g.TrangThai = 'BaoTri' FROM GiuongBenh g INNER JOIN Phong p ON g.MaPhong = p.MaPhong WHERE p.MaKhoa = @MaKhoa AND g.TrangThai = 'Trong';  
      
            DECLARE @TenKhoa NVARCHAR(100);  
            SELECT @TenKhoa = TenKhoa FROM Khoa WHERE MaKhoa = @MaKhoa;  

            INSERT INTO ThongBao (MaTaiKhoan, TieuDe, NoiDung, LoaiThongBao, DaDoc, NgayTao)  
            SELECT bn.MaTaiKhoan, N'Thông báo hủy lịch hẹn', N'Lịch hẹn bị hủy do Khoa tạm ngưng.', 'LICH_HEN', 0, GETDATE()  
            FROM LichHen lh INNER JOIN BenhNhan bn ON lh.MaBenhNhan = bn.MaBenhNhan  
            WHERE lh.MaKhoa = @MaKhoa AND lh.NgayKham >= CAST(GETDATE() AS DATE) AND lh.TrangThai = 'DaDatLich' AND bn.MaTaiKhoan IS NOT NULL;  

            UPDATE LichHen SET TrangThai = 'DaHuy' WHERE MaKhoa = @MaKhoa AND NgayKham >= CAST(GETDATE() AS DATE) AND TrangThai = 'DaDatLich';  
        END  
        ELSE  
        BEGIN  
            UPDATE Khoa SET TrangThai = 1 WHERE MaKhoa = @MaKhoa;  
            UPDATE Phong SET TrangThai = 1 WHERE MaKhoa = @MaKhoa;  
            UPDATE g SET g.TrangThai = 'Trong' FROM GiuongBenh g INNER JOIN Phong p ON g.MaPhong = p.MaPhong WHERE p.MaKhoa = @MaKhoa AND g.TrangThai = 'BaoTri';  
        END  
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- 5. Lưu Phòng
CREATE OR ALTER PROCEDURE dbo.sp_Phong_Save @MaPhong VARCHAR(15), @TenPhong NVARCHAR(100), @LoaiPhong VARCHAR(20), @MaKhoa VARCHAR(10) AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM Phong WHERE MaPhong = @MaPhong) UPDATE Phong SET TenPhong = @TenPhong, LoaiPhong = @LoaiPhong, MaKhoa = @MaKhoa WHERE MaPhong = @MaPhong;
    ELSE INSERT INTO Phong (MaPhong, TenPhong, LoaiPhong, MaKhoa, TrangThai) VALUES (@MaPhong, @TenPhong, @LoaiPhong, @MaKhoa, 1);
END;
GO

-- 6. Đảo trạng thái Phòng (Có Transaction & Try Catch)
CREATE OR ALTER PROCEDURE dbo.sp_Phong_ToggleStatus @MaPhong VARCHAR(15) AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        DECLARE @CurrentStatus BIT;
        SELECT @CurrentStatus = ISNULL(TrangThai, 1) FROM Phong WHERE MaPhong = @MaPhong;

        IF @CurrentStatus = 1
        BEGIN
            UPDATE Phong SET TrangThai = 0 WHERE MaPhong = @MaPhong;
            UPDATE GiuongBenh SET TrangThai = 'BaoTri' WHERE MaPhong = @MaPhong AND TrangThai = 'Trong';
        END
        ELSE
        BEGIN
            UPDATE Phong SET TrangThai = 1 WHERE MaPhong = @MaPhong;
            UPDATE GiuongBenh SET TrangThai = 'Trong' WHERE MaPhong = @MaPhong AND TrangThai = 'BaoTri';
        END
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- 7. Tự động thông báo nhắc lịch
CREATE OR ALTER PROCEDURE dbo.sp_TaoThongBaoNhacLich AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.ThongBao (MaTaiKhoan, TieuDe, NoiDung, LoaiThongBao)
    SELECT tk.MaTaiKhoan, N'Nhắc nhở lịch hẹn khám bệnh', N'Bạn có lịch khám vào ngày mai lúc ' + CONVERT(VARCHAR(5), lh.GioKham, 108) + N'.', 'NHAC_LICH'
    FROM dbo.LichHen lh JOIN dbo.BenhNhan bn ON lh.MaBenhNhan = bn.MaBenhNhan JOIN dbo.TaiKhoan tk ON bn.MaTaiKhoan = tk.MaTaiKhoan
    WHERE lh.TrangThai = 'DaDatLich' AND CAST(lh.NgayKham AS DATE) = CAST(DATEADD(DAY, 1, GETDATE()) AS DATE) AND NOT EXISTS (SELECT 1 FROM dbo.ThongBao tb WHERE tb.MaTaiKhoan = tk.MaTaiKhoan AND tb.LoaiThongBao = 'NHAC_LICH' AND CAST(tb.NgayTao AS DATE) = CAST(GETDATE() AS DATE));
END;
GO

-- 8. Gửi Broadcast
CREATE OR ALTER PROCEDURE dbo.sp_ThongBao_Broadcast @TieuDe NVARCHAR(200), @NoiDung NVARCHAR(1000), @LoaiThongBao VARCHAR(50), @TargetRole VARCHAR(20) = 'ALL' AS
BEGIN
    SET NOCOUNT ON;
    IF @TargetRole IS NULL OR @TargetRole = '' SET @TargetRole = 'ALL';
    INSERT INTO dbo.ThongBao (MaTaiKhoan, TieuDe, NoiDung, LoaiThongBao, DaDoc, NgayTao)
    SELECT MaTaiKhoan, @TieuDe, @NoiDung, @LoaiThongBao, 0, GETDATE() FROM dbo.vw_TaiKhoan WHERE TrangThai = 1 AND (@TargetRole = 'ALL' OR (@TargetRole = 'STAFF' AND VaiTro <> 'BenhNhan') OR (VaiTro = @TargetRole));
END;
GO

-- 9. Tạo Thông báo
CREATE OR ALTER PROCEDURE dbo.sp_ThongBao_Create @MaTaiKhoan BIGINT, @TieuDe NVARCHAR(200), @NoiDung NVARCHAR(1000), @LoaiThongBao VARCHAR(50) AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.ThongBao (MaTaiKhoan, TieuDe, NoiDung, LoaiThongBao, DaDoc, NgayTao) VALUES (@MaTaiKhoan, @TieuDe, @NoiDung, @LoaiThongBao, 0, GETDATE());
END;
GO

-- 10. Đánh dấu đã đọc
CREATE OR ALTER PROCEDURE dbo.sp_ThongBao_MarkRead @MaThongBao INT, @MaTaiKhoan BIGINT AS
BEGIN
    SET NOCOUNT ON;
    UPDATE dbo.ThongBao SET DaDoc = 1 WHERE MaThongBao = @MaThongBao AND MaTaiKhoan = @MaTaiKhoan;
END;
GO

-- 11. Tiếp nhận Bệnh nhân (Có Transaction & Try Catch)
CREATE OR ALTER PROCEDURE sp_TiepNhanBenhNhan @MaLichHen VARCHAR(15), @MaPhieuKham VARCHAR(15), @MaBacSi VARCHAR(15), @MaKhoa VARCHAR(10) AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @GioHen DATETIME, @TrangThai VARCHAR(20), @MaBenhNhan VARCHAR(15);
    SELECT @GioHen = CAST(NgayKham AS DATETIME) + CAST(GioKham AS DATETIME), @TrangThai = TrangThai, @MaBenhNhan = MaBenhNhan FROM dbo.LichHen WHERE MaLichHen = @MaLichHen;

    IF @TrangThai <> 'DangChoKham' BEGIN RAISERROR(N'Lịch hẹn không hợp lệ.', 16, 1); RETURN; END
    IF EXISTS (SELECT 1 FROM dbo.LichHen WHERE MaBacSi = @MaBacSi AND TrangThai = 'DangKham') BEGIN RAISERROR(N'Bác sĩ đang bận.', 16, 1); RETURN; END
    IF DATEDIFF(MINUTE, @GioHen, GETDATE()) > 10 BEGIN UPDATE dbo.LichHen SET TrangThai = 'DaHuy' WHERE MaLichHen = @MaLichHen; RAISERROR(N'Bệnh nhân đến trễ.', 16, 1); RETURN; END

    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE dbo.LichHen SET TrangThai = 'DangKham' WHERE MaLichHen = @MaLichHen;
        INSERT INTO dbo.PhieuKham (MaPhieuKham, MaBenhNhan, MaBacSi, MaKhoa, MaLichHen, NgayKham) VALUES (@MaPhieuKham, @MaBenhNhan, @MaBacSi, @MaKhoa, @MaLichHen, GETDATE());
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- 12. Generic Delete
CREATE OR ALTER PROCEDURE dbo.usp_Entity_Delete @EntityName SYSNAME, @IdValue NVARCHAR(4000) AS
BEGIN
    SET NOCOUNT ON;
    IF @EntityName NOT IN (N'AuditLog', N'BenhNhan', N'ChiTietHoaDon', N'ChiTietKetQuaCLS', N'ChiTietNhapKho', N'DichVuCLS', N'DonThuoc', N'GiuongBenh', N'HoaDon', N'KetQuaCLS', N'Khoa', N'LichHen', N'LichTruc', N'NhanVien', N'NoiTru', N'PhieuKham', N'PhieuNhapKho', N'Thuoc', N'YeuCauChuyenKhoa') THROW 50002, 'Entity not allowed.', 1;
    DECLARE @ObjectId INT = OBJECT_ID(N'dbo.' + QUOTENAME(@EntityName), N'U'), @KeyColumn SYSNAME;
    SELECT @KeyColumn = c.name FROM sys.key_constraints kc JOIN sys.index_columns ic ON ic.object_id = kc.parent_object_id AND ic.index_id = kc.unique_index_id JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id WHERE kc.parent_object_id = @ObjectId AND kc.type = N'PK';
    IF @KeyColumn IS NULL THROW 50003, 'Entity table has no primary key.', 1;
    DECLARE @DeleteSql NVARCHAR(MAX) = N'DELETE FROM dbo.' + QUOTENAME(@EntityName) + N' WHERE ' + QUOTENAME(@KeyColumn) + N' = @Value;';
    EXEC sys.sp_executesql @DeleteSql, N'@Value NVARCHAR(4000)', @Value = @IdValue;
END;
GO

-- 13. Generic Save
CREATE OR ALTER PROCEDURE dbo.usp_Entity_Save
    @EntityName SYSNAME,
    @Payload NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    IF ISJSON(@Payload) <> 1
        THROW 50001, 'Invalid JSON.', 1;

    IF @EntityName NOT IN (
        N'AuditLog', N'BenhNhan', N'ChiTietHoaDon', N'ChiTietKetQuaCLS', N'ChiTietNhapKho',
        N'DichVuCLS', N'DonThuoc', N'GiuongBenh', N'HoaDon', N'KetQuaCLS', N'Khoa',
        N'LichHen', N'LichTruc', N'NhanVien', N'NoiTru', N'PhieuKham', N'PhieuNhapKho',
        N'Thuoc', N'YeuCauChuyenKhoa'
    )
        THROW 50002, 'Not allowed.', 1;

    DECLARE @ObjectId INT = OBJECT_ID(N'dbo.' + QUOTENAME(@EntityName), N'U');
    DECLARE @KeyColumn SYSNAME;

    SELECT @KeyColumn = c.name
    FROM sys.key_constraints kc
    JOIN sys.index_columns ic ON ic.object_id = kc.parent_object_id AND ic.index_id = kc.unique_index_id
    JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
    WHERE kc.parent_object_id = @ObjectId AND kc.type = N'PK';

    IF @KeyColumn IS NULL
        THROW 50003, 'No PK.', 1;

    DECLARE @QualifiedTable NVARCHAR(300) = N'dbo.' + QUOTENAME(@EntityName);
    DECLARE @KeyValue NVARCHAR(4000) = JSON_VALUE(@Payload, N'$.' + QUOTENAME(@KeyColumn, '"'));
    DECLARE @InsertCols NVARCHAR(MAX), @InsertVals NVARCHAR(MAX), @UpdateSet NVARCHAR(MAX);

    SELECT 
        @InsertCols = STRING_AGG(CONVERT(NVARCHAR(MAX), QUOTENAME(c.name)), N',') WITHIN GROUP (ORDER BY c.column_id),
        @InsertVals = STRING_AGG(CONVERT(NVARCHAR(MAX), N'(SELECT [value] FROM OPENJSON(@Payload) WHERE [key] = N''' + REPLACE(c.name, N'''', N'''''') + N''')'), N',') WITHIN GROUP (ORDER BY c.column_id),
        @UpdateSet  = STRING_AGG(CASE WHEN c.name <> @KeyColumn 
                                      THEN CONVERT(NVARCHAR(MAX), QUOTENAME(c.name) + N' = (SELECT [value] FROM OPENJSON(@Payload) WHERE [key] = N''' + REPLACE(c.name, N'''', N'''''') + N''')') 
                                 END, N',') WITHIN GROUP (ORDER BY c.column_id)
    FROM sys.columns c
    JOIN OPENJSON(@Payload) j ON j.[key] COLLATE DATABASE_DEFAULT = c.name COLLATE DATABASE_DEFAULT
    WHERE c.object_id = @ObjectId
      AND c.is_identity = 0
      AND c.is_computed = 0
      AND c.generated_always_type = 0;

    IF @KeyValue IS NOT NULL
    BEGIN
        DECLARE @Exists BIT = 0;
        DECLARE @CheckSql NVARCHAR(MAX) = N'SELECT @Found = CASE WHEN EXISTS (SELECT 1 FROM ' + @QualifiedTable + N' WHERE ' + QUOTENAME(@KeyColumn) + N' = @Value) THEN 1 ELSE 0 END;';
        EXEC sys.sp_executesql 
            @CheckSql,
            N'@Value NVARCHAR(4000), @Found BIT OUTPUT', @Value = @KeyValue, @Found = @Exists OUTPUT;

        IF @Exists = 1
        BEGIN
            IF @UpdateSet IS NOT NULL
            BEGIN
                DECLARE @UpdateSql NVARCHAR(MAX) = N'UPDATE ' + @QualifiedTable + N' SET ' + @UpdateSet + N' WHERE ' + QUOTENAME(@KeyColumn) + N' = @Value;';
                EXEC sys.sp_executesql 
                    @UpdateSql,
                    N'@Payload NVARCHAR(MAX), @Value NVARCHAR(4000)', @Payload = @Payload, @Value = @KeyValue;
            END
            RETURN;
        END
    END

    IF @InsertCols IS NULL
        THROW 50004, 'No writable columns.', 1;

    DECLARE @InsertSql NVARCHAR(MAX) = N'INSERT INTO ' + @QualifiedTable + N' (' + @InsertCols + N') SELECT ' + @InsertVals + N';';
    EXEC sys.sp_executesql 
        @InsertSql,
        N'@Payload NVARCHAR(MAX)', @Payload = @Payload;
END;
GO

-- 14. Insert TK
CREATE OR ALTER PROCEDURE dbo.usp_TaiKhoan_Insert @TenDangNhap VARCHAR(50), @MatKhauHash VARCHAR(255), @Email VARCHAR(100) = NULL, @SoDienThoai VARCHAR(15), @VaiTro VARCHAR(20), @TrangThai BIT, @NgayTao DATETIME, @MaTaiKhoan BIGINT OUTPUT AS
BEGIN
    SET NOCOUNT ON; INSERT INTO dbo.TaiKhoan (TenDangNhap, MatKhauHash, Email, SoDienThoai, VaiTro, TrangThai, NgayTao) VALUES (@TenDangNhap, @MatKhauHash, @Email, @SoDienThoai, @VaiTro, @TrangThai, @NgayTao); SET @MaTaiKhoan = CONVERT(BIGINT, SCOPE_IDENTITY());
END;
GO

-- 15. Update TK
CREATE OR ALTER PROCEDURE dbo.usp_TaiKhoan_Update @MaTaiKhoan BIGINT, @MatKhauHash VARCHAR(255), @Email VARCHAR(100) = NULL, @SoDienThoai VARCHAR(15), @VaiTro VARCHAR(20), @TrangThai BIT, @NgayTao DATETIME AS
BEGIN
    SET NOCOUNT ON; UPDATE dbo.TaiKhoan SET MatKhauHash = @MatKhauHash, Email = @Email, SoDienThoai = @SoDienThoai, VaiTro = @VaiTro, TrangThai = @TrangThai, NgayTao = @NgayTao WHERE MaTaiKhoan = @MaTaiKhoan;
END;
GO

-- 16. Thanh toán hóa đơn viện phí (Có Transaction & Try Catch)
CREATE OR ALTER PROCEDURE dbo.sp_ThanhToanHoaDon
    @MaHoaDon VARCHAR(15), @HinhThucThanhToan VARCHAR(30), @MaNhanVienThu VARCHAR(15)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE dbo.HoaDon SET TrangThaiTT = 'DaThanhToan', HinhThucThanhToan = @HinhThucThanhToan, NhanVienThu = @MaNhanVienThu, NgayThanhToan = GETDATE() WHERE MaHoaDon = @MaHoaDon AND TrangThaiTT = 'ChuaThanhToan';
        IF @@ROWCOUNT = 0 THROW 50005, N'Hóa đơn không tồn tại hoặc đã thanh toán.', 1;

        DECLARE @MaPhieuKham VARCHAR(15);
        SELECT @MaPhieuKham = MaPhieuKham FROM dbo.HoaDon WHERE MaHoaDon = @MaHoaDon;

        UPDATE g SET g.TrangThai = 'Trong' FROM dbo.GiuongBenh g JOIN dbo.NoiTru nt ON g.MaGiuong = nt.MaGiuong WHERE nt.MaPhieuKham = @MaPhieuKham AND nt.TrangThai = 'DaXuatVien';
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO