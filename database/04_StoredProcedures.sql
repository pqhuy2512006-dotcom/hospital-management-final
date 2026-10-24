USE QuanLyBenhVien;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- 1. Thêm mới hoặc cập nhật Giường bệnh
CREATE OR ALTER PROCEDURE dbo.sp_GiuongBenh_Save
    @MaGiuong VARCHAR(15) = NULL,
    @MaPhong VARCHAR(15) = NULL,
    @SoGiuong NVARCHAR(50),
    @DonGiaNgay DECIMAL(18, 2) = 250000
AS
BEGIN
    SET NOCOUNT ON;

    -- Tự sinh mã giường nếu chưa có
    IF @MaGiuong IS NULL OR LTRIM(RTRIM(@MaGiuong)) = ''
    BEGIN
        SET @MaGiuong = @MaPhong + '-' + REPLACE(@SoGiuong, ' ', '');
    END

    -- Kiểm tra tồn tại: có thì UPDATE, chưa có thì INSERT
    IF EXISTS (SELECT 1 FROM GiuongBenh WHERE MaGiuong = @MaGiuong)
    BEGIN
        UPDATE GiuongBenh
        SET SoGiuong = @SoGiuong,
            DonGiaNgay = @DonGiaNgay
        WHERE MaGiuong = @MaGiuong;
    END
    ELSE
    BEGIN
        INSERT INTO GiuongBenh (MaGiuong, SoGiuong, MaPhong, DonGiaNgay, TrangThai)
        VALUES (@MaGiuong, @SoGiuong, @MaPhong, @DonGiaNgay, 'Trong');
    END
END;
GO

-- 2. Đảo trạng thái Giường bệnh (Bảo trì <-> Trống)
CREATE OR ALTER PROCEDURE dbo.sp_GiuongBenh_ToggleStatus
    @MaGiuong VARCHAR(15)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE GiuongBenh
    SET TrangThai = CASE 
        WHEN TrangThai = 'BaoTri' THEN 'Trong'
        WHEN TrangThai = 'Trong'  THEN 'BaoTri'
        ELSE TrangThai 
    END
    WHERE MaGiuong = @MaGiuong;
END;
GO

-- 3. Thêm mới hoặc cập nhật Khoa
CREATE OR ALTER PROCEDURE dbo.sp_Khoa_Save
    @MaKhoa VARCHAR(10),
    @TenKhoa NVARCHAR(100),
    @MoTa NVARCHAR(300) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM Khoa WHERE MaKhoa = @MaKhoa)
    BEGIN
        UPDATE Khoa 
        SET TenKhoa = @TenKhoa, 
            MoTa = @MoTa
        WHERE MaKhoa = @MaKhoa;
    END
    ELSE
    BEGIN
        INSERT INTO Khoa (MaKhoa, TenKhoa, MoTa, TrangThai)
        VALUES (@MaKhoa, @TenKhoa, @MoTa, 1);
    END
END;
GO

-- 4. Đảo trạng thái hoạt động của Khoa
CREATE OR ALTER PROCEDURE dbo.sp_Khoa_ToggleStatus  
    @MaKhoa VARCHAR(10)  
AS  
BEGIN  
    SET NOCOUNT ON;  

    DECLARE @CurrentStatus BIT;  
    SELECT @CurrentStatus = ISNULL(TrangThai, 1) FROM Khoa WHERE MaKhoa = @MaKhoa;  
  
    IF @CurrentStatus = 1  
    BEGIN  
        -- 1. Đổi Khoa sang tạm ngưng (0) và khóa Phòng thuộc Khoa
        UPDATE Khoa SET TrangThai = 0 WHERE MaKhoa = @MaKhoa;  
        UPDATE Phong SET TrangThai = 0 WHERE MaKhoa = @MaKhoa;  
  
        -- 2. Chuyển các giường Trống sang Bảo trì
        UPDATE g  
        SET g.TrangThai = 'BaoTri'  
        FROM GiuongBenh g  
        INNER JOIN Phong p ON g.MaPhong = p.MaPhong  
        WHERE p.MaKhoa = @MaKhoa AND g.TrangThai = 'Trong';  
  
        -- 3. Tạo thông báo hủy lịch cho bệnh nhân
        DECLARE @TenKhoa NVARCHAR(100);  
        SELECT @TenKhoa = TenKhoa FROM Khoa WHERE MaKhoa = @MaKhoa;  

        INSERT INTO ThongBao (MaTaiKhoan, TieuDe, NoiDung, LoaiThongBao, DaDoc, NgayTao)  
        SELECT   
            bn.MaTaiKhoan,  
            N'Thông báo hủy lịch hẹn do Khoa tạm ngưng tiếp nhận',  
            N'Lịch hẹn ngày ' + CONVERT(VARCHAR, lh.NgayKham, 103) + N' tại ' + @TenKhoa + N' đã được tự động hủy do Khoa tạm ngưng hoạt động. Quý khách vui lòng đặt lại lịch tại khoa khác hoặc liên hệ bộ phận Tiếp đón.',  
            'LICH_HEN',  
            0,  
            GETDATE()  
        FROM LichHen lh  
        INNER JOIN BenhNhan bn ON lh.MaBenhNhan = bn.MaBenhNhan  
        WHERE lh.MaKhoa = @MaKhoa   
          AND lh.NgayKham >= CAST(GETDATE() AS DATE)  
          AND lh.TrangThai = 'DaDatLich'
          AND bn.MaTaiKhoan IS NOT NULL;  

        -- 4. Hủy các lịch hẹn tương lai chưa khám
        UPDATE LichHen   
        SET TrangThai = 'DaHuy'   
        WHERE MaKhoa = @MaKhoa   
          AND NgayKham >= CAST(GETDATE() AS DATE)  
          AND TrangThai = 'DaDatLich';  
    END  
    ELSE  
    BEGIN  
        -- Mở lại hoạt động Khoa và Phòng
        UPDATE Khoa SET TrangThai = 1 WHERE MaKhoa = @MaKhoa;  
        UPDATE Phong SET TrangThai = 1 WHERE MaKhoa = @MaKhoa;  
  
        -- Mở lại các giường Bảo trì về trạng thái Trống
        UPDATE g  
        SET g.TrangThai = 'Trong'  
        FROM GiuongBenh g  
        INNER JOIN Phong p ON g.MaPhong = p.MaPhong  
        WHERE p.MaKhoa = @MaKhoa AND g.TrangThai = 'BaoTri';  
    END  
END;
GO

-- 5. Thêm mới hoặc cập nhật Phòng
CREATE OR ALTER PROCEDURE dbo.sp_Phong_Save
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
        SET TenPhong = @TenPhong, 
            LoaiPhong = @LoaiPhong, 
            MaKhoa = @MaKhoa
        WHERE MaPhong = @MaPhong;
    END
    ELSE
    BEGIN
        INSERT INTO Phong (MaPhong, TenPhong, LoaiPhong, MaKhoa, TrangThai)
        VALUES (@MaPhong, @TenPhong, @LoaiPhong, @MaKhoa, 1);
    END
END;
GO

-- 6. Đảo trạng thái Phòng
CREATE OR ALTER PROCEDURE dbo.sp_Phong_ToggleStatus
    @MaPhong VARCHAR(15)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CurrentStatus BIT;
    SELECT @CurrentStatus = ISNULL(TrangThai, 1) FROM Phong WHERE MaPhong = @MaPhong;

    IF @CurrentStatus = 1
    BEGIN
        -- Đang mở -> Chuyển sang tắt (0) và chuyển các giường Trống sang Bảo trì
        UPDATE Phong SET TrangThai = 0 WHERE MaPhong = @MaPhong;
        UPDATE GiuongBenh SET TrangThai = 'BaoTri' WHERE MaPhong = @MaPhong AND TrangThai = 'Trong';
    END
    ELSE
    BEGIN
        -- Đang tắt -> Mở lại (1) và chuyển các giường Bảo trì về Trống
        UPDATE Phong SET TrangThai = 1 WHERE MaPhong = @MaPhong;
        UPDATE GiuongBenh SET TrangThai = 'Trong' WHERE MaPhong = @MaPhong AND TrangThai = 'BaoTri';
    END
END;
GO

-- 7. Tự động tạo thông báo nhắc lịch khám ngày mai
CREATE OR ALTER PROCEDURE dbo.sp_TaoThongBaoNhacLich
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.ThongBao (MaTaiKhoan, TieuDe, NoiDung, LoaiThongBao)
    SELECT 
        tk.MaTaiKhoan,
        N'Nhắc nhở lịch hẹn khám bệnh',
        N'Bạn có lịch khám vào ngày mai lúc ' + CONVERT(VARCHAR(5), lh.GioKham, 108) + N'. Vui lòng có mặt đúng giờ để được phục vụ tốt nhất.',
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

-- 8. Gửi thông báo hàng loạt (Broadcast)
CREATE OR ALTER PROCEDURE dbo.sp_ThongBao_Broadcast
    @TieuDe NVARCHAR(200),
    @NoiDung NVARCHAR(1000),
    @LoaiThongBao VARCHAR(50),
    @TargetRole VARCHAR(20) = 'ALL'
AS
BEGIN
    SET NOCOUNT ON;

    IF @TargetRole IS NULL OR @TargetRole = ''
        SET @TargetRole = 'ALL';

    INSERT INTO dbo.ThongBao (MaTaiKhoan, TieuDe, NoiDung, LoaiThongBao, DaDoc, NgayTao)
    SELECT MaTaiKhoan, @TieuDe, @NoiDung, @LoaiThongBao, 0, GETDATE()
    FROM dbo.vw_TaiKhoan
    WHERE TrangThai = 1
      AND (
          @TargetRole = 'ALL'
          OR (@TargetRole = 'STAFF' AND VaiTro <> 'BenhNhan')
          OR (VaiTro = @TargetRole)
      );

    SELECT @@ROWCOUNT AS SoNguoiNhan;
END;
GO

-- 9. Tạo một thông báo cho tài khoản
CREATE OR ALTER PROCEDURE dbo.sp_ThongBao_Create
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

-- 10. Đánh dấu thông báo đã đọc
CREATE OR ALTER PROCEDURE dbo.sp_ThongBao_MarkRead
    @MaThongBao INT,
    @MaTaiKhoan BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dbo.ThongBao
    SET DaDoc = 1
    WHERE MaThongBao = @MaThongBao AND MaTaiKhoan = @MaTaiKhoan;
END;
GO

-- 11. Tiếp nhận bệnh nhân vào khám
CREATE OR ALTER PROCEDURE sp_TiepNhanBenhNhan
    @MaLichHen VARCHAR(15),
    @MaPhieuKham VARCHAR(15),
    @MaBacSi VARCHAR(15),
    @MaKhoa VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @GioHen DATETIME;
    DECLARE @TrangThai VARCHAR(20);
    DECLARE @MaBenhNhan VARCHAR(15);

    -- Lấy thông tin lịch hẹn
    SELECT 
        @GioHen = CAST(NgayKham AS DATETIME) + CAST(GioKham AS DATETIME),
        @TrangThai = TrangThai,
        @MaBenhNhan = MaBenhNhan
    FROM dbo.LichHen
    WHERE MaLichHen = @MaLichHen;

    IF @TrangThai <> 'DangChoKham'
    BEGIN
        RAISERROR(N'Lịch hẹn không ở trạng thái hợp lệ để tiếp nhận.', 16, 1);
        RETURN;
    END

    -- Kiểm tra bác sĩ có ca nào đang khám dở không
    IF EXISTS (SELECT 1 FROM dbo.LichHen WHERE MaBacSi = @MaBacSi AND TrangThai = 'DangKham')
    BEGIN
        RAISERROR(N'Bác sĩ đang có một ca bệnh đang khám. Vui lòng hoàn tất trước khi gọi ca mới!', 16, 1);
        RETURN;
    END

    -- Nếu trễ quá 10 phút thì hủy lịch
    IF DATEDIFF(MINUTE, @GioHen, GETDATE()) > 10
    BEGIN
        UPDATE dbo.LichHen
        SET TrangThai = 'DaHuy'
        WHERE MaLichHen = @MaLichHen;

        RAISERROR(N'Bệnh nhân đã đến trễ quá 10 phút. Lịch hẹn đã bị tự động hủy!', 16, 1);
        RETURN;
    END

    -- Tạo phiếu khám và cập nhật trạng thái
    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE dbo.LichHen
        SET TrangThai = 'DangKham'
        WHERE MaLichHen = @MaLichHen;

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

-- 12. Xóa dữ liệu bảng tổng quát (Generic Delete)
CREATE OR ALTER PROCEDURE dbo.usp_Entity_Delete
    @EntityName SYSNAME,
    @IdValue NVARCHAR(4000)
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra danh sách bảng cho phép
    IF @EntityName NOT IN (
        N'AuditLog', N'BenhNhan', N'ChiTietHoaDon', N'ChiTietKetQuaCLS', N'ChiTietNhapKho',
        N'DichVuCLS', N'DonThuoc', N'GiuongBenh', N'HoaDon', N'KetQuaCLS', N'Khoa',
        N'LichHen', N'LichTruc', N'NhanVien', N'NoiTru', N'PhieuKham', N'PhieuNhapKho',
        N'Thuoc', N'YeuCauChuyenKhoa'
    )
        THROW 50002, 'Entity is not allowed for generic persistence.', 1;

    -- Tìm cột khóa chính (PK)
    DECLARE @ObjectId INT = OBJECT_ID(N'dbo.' + QUOTENAME(@EntityName), N'U');
    DECLARE @KeyColumn SYSNAME;

    SELECT @KeyColumn = c.name
    FROM sys.key_constraints kc
    JOIN sys.index_columns ic ON ic.object_id = kc.parent_object_id AND ic.index_id = kc.unique_index_id
    JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
    WHERE kc.parent_object_id = @ObjectId AND kc.type = N'PK';

    IF @KeyColumn IS NULL
        THROW 50003, 'Entity table has no primary key.', 1;

    -- Thực thi lệnh xóa
    DECLARE @DeleteSql NVARCHAR(MAX) = N'DELETE FROM dbo.' + QUOTENAME(@EntityName)
        + N' WHERE ' + QUOTENAME(@KeyColumn) + N' = @Value;';
    EXEC sys.sp_executesql @DeleteSql, N'@Value NVARCHAR(4000)', @Value = @IdValue;
END;
GO

-- 13. Lưu dữ liệu bảng tổng quát từ JSON (Generic Save - Rút gọn tối ưu)
CREATE OR ALTER PROCEDURE dbo.usp_Entity_Save
    @EntityName SYSNAME,
    @Payload NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Kiểm tra JSON hợp lệ
    IF ISJSON(@Payload) <> 1
        THROW 50001, 'Entity payload must be valid JSON.', 1;

    -- 2. Danh sách bảng cho phép (Bảo mật SQL Injection)
    IF @EntityName NOT IN (
        N'AuditLog', N'BenhNhan', N'ChiTietHoaDon', N'ChiTietKetQuaCLS', N'ChiTietNhapKho',
        N'DichVuCLS', N'DonThuoc', N'GiuongBenh', N'HoaDon', N'KetQuaCLS', N'Khoa',
        N'LichHen', N'LichTruc', N'NhanVien', N'NoiTru', N'PhieuKham', N'PhieuNhapKho',
        N'Thuoc', N'YeuCauChuyenKhoa'
    )
        THROW 50002, 'Entity is not allowed for generic persistence.', 1;

    -- 3. Tìm cột Khóa chính (Primary Key) của bảng
    DECLARE @ObjectId INT = OBJECT_ID(N'dbo.' + QUOTENAME(@EntityName), N'U');
    DECLARE @KeyColumn SYSNAME;

    SELECT @KeyColumn = c.name
    FROM sys.key_constraints kc
    JOIN sys.index_columns ic ON ic.object_id = kc.parent_object_id AND ic.index_id = kc.unique_index_id
    JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
    WHERE kc.parent_object_id = @ObjectId AND kc.type = N'PK';

    IF @KeyColumn IS NULL
        THROW 50003, 'Entity table has no primary key.', 1;

    -- 4. Tạo đồng thời các cột INSERT và UPDATE trong 1 lệnh duy nhất
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

    -- 5. Nếu có khóa chính và bản ghi đã tồn tại -> UPDATE
    IF @KeyValue IS NOT NULL
    BEGIN
        DECLARE @Exists BIT = 0;
        EXEC sys.sp_executesql 
            N'SELECT @Found = CASE WHEN EXISTS (SELECT 1 FROM ' + @QualifiedTable + N' WHERE ' + QUOTENAME(@KeyColumn) + N' = @Value) THEN 1 ELSE 0 END;',
            N'@Value NVARCHAR(4000), @Found BIT OUTPUT', @Value = @KeyValue, @Found = @Exists OUTPUT;

        IF @Exists = 1
        BEGIN
            IF @UpdateSet IS NOT NULL
                EXEC sys.sp_executesql 
                    N'UPDATE ' + @QualifiedTable + N' SET ' + @UpdateSet + N' WHERE ' + QUOTENAME(@KeyColumn) + N' = @Value;',
                    N'@Payload NVARCHAR(MAX), @Value NVARCHAR(4000)', @Payload = @Payload, @Value = @KeyValue;
            RETURN;
        END
    END

    -- 6. Nếu chưa tồn tại -> INSERT
    IF @InsertCols IS NULL
        THROW 50004, 'No writable entity columns found in payload.', 1;

    EXEC sys.sp_executesql 
        N'INSERT INTO ' + @QualifiedTable + N' (' + @InsertCols + N') SELECT ' + @InsertVals + N';',
        N'@Payload NVARCHAR(MAX)', @Payload = @Payload;
END;
GO

-- 14. Thêm mới Tài khoản
CREATE OR ALTER PROCEDURE dbo.usp_TaiKhoan_Insert
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

-- 15. Cập nhật thông tin Tài khoản
CREATE OR ALTER PROCEDURE dbo.usp_TaiKhoan_Update
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
