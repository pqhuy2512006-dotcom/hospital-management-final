USE QuanLyBenhVien;
GO

-- =========================================================================
-- 1. HÀM TÍNH HÀNG ĐỢI VÀ THỜI GIAN CHỜ (Dùng vòng lặp WHILE thay cho Cursor)
-- =========================================================================
CREATE OR ALTER FUNCTION fn_TinhHangDoiKham
(
    @MaBacSi VARCHAR(15),
    @NgayKham DATE
)
RETURNS @ResultTable TABLE 
(
    MaLichHen VARCHAR(15),
    ThoiGianDuKienBatDau DATETIME,
    PhutChoDoi INT
)
AS
BEGIN
    DECLARE @ThoiGianHienTai DATETIME = GETDATE();
    DECLARE @MocKetThuc DATETIME = @ThoiGianHienTai;

    -- BƯỚC 1: Xử lý ca đang khám (nếu có) để lấy giờ dự kiến xong
    DECLARE @BatDauKham DATETIME, @SoPhutKham INT;
    
    SELECT TOP 1 
        @BatDauKham = pk.NgayKham,
        @SoPhutKham = lh.ThoiGianKhamDuKien
    FROM dbo.LichHen lh
    JOIN dbo.PhieuKham pk ON lh.MaLichHen = pk.MaLichHen
    WHERE lh.TrangThai = 'DangKham' 
      AND lh.NgayKham = @NgayKham
      AND lh.MaBacSi = @MaBacSi;

    -- Nếu có người đang khám, cộng thêm thời gian khám vào mốc bắt đầu
    IF @BatDauKham IS NOT NULL
    BEGIN
        SET @MocKetThuc = DATEADD(MINUTE, @SoPhutKham, @BatDauKham);
        
        -- Nếu giờ dự kiến xong nằm ở quá khứ thì lấy luôn giờ hiện tại
        IF @MocKetThuc < @ThoiGianHienTai
            SET @MocKetThuc = @ThoiGianHienTai;
    END

    -- BƯỚC 2: Đưa các ca đang chờ vào bảng tạm có đánh số thứ tự 1, 2, 3...
    DECLARE @DanhSachCho TABLE 
    (
        STT INT IDENTITY(1,1),
        MaLichHen VARCHAR(15),
        GioHen DATETIME,
        ThoiGianKhamDuKien INT
    );

    INSERT INTO @DanhSachCho (MaLichHen, GioHen, ThoiGianKhamDuKien)
    SELECT 
        MaLichHen,
        CAST(NgayKham AS DATETIME) + CAST(GioKham AS DATETIME),
        ThoiGianKhamDuKien
    FROM dbo.LichHen
    WHERE TrangThai = 'DangChoKham'
      AND NgayKham = @NgayKham
      AND MaBacSi = @MaBacSi
    ORDER BY GioKham;

    -- BƯỚC 3: Dùng vòng lặp WHILE duyệt từng người theo STT
    DECLARE @i INT = 1;
    DECLARE @TongSoCa INT = (SELECT COUNT(*) FROM @DanhSachCho);

    WHILE @i <= @TongSoCa
    BEGIN
        DECLARE @MaLH VARCHAR(15), @GioHen DATETIME, @PhutKham INT;
        
        SELECT @MaLH = MaLichHen, @GioHen = GioHen, @PhutKham = ThoiGianKhamDuKien
        FROM @DanhSachCho
        WHERE STT = @i;

        -- Thời gian bắt đầu là mốc xong của người trước
        DECLARE @GioBatDau DATETIME = @MocKetThuc;

        -- Không khám sớm hơn giờ bệnh nhân đã hẹn
        IF @GioBatDau < @GioHen
            SET @GioBatDau = @GioHen;

        -- Không lấy mốc thời gian quá khứ
        IF @GioBatDau < @ThoiGianHienTai
            SET @GioBatDau = @ThoiGianHienTai;

        -- Tính số phút phải chờ và thêm vào bảng kết quả
        INSERT INTO @ResultTable (MaLichHen, ThoiGianDuKienBatDau, PhutChoDoi)
        VALUES (@MaLH, @GioBatDau, DATEDIFF(MINUTE, @ThoiGianHienTai, @GioBatDau));

        -- Mốc kết thúc ca này làm mốc bắt đầu cho ca kế tiếp
        SET @MocKetThuc = DATEADD(MINUTE, @PhutKham, @GioBatDau);

        SET @i = @i + 1;
    END

    RETURN;
END;
GO

-- =========================================================================
-- 2. HÀM TÍNH TỔNG TIỀN THUỐC THEO PHIẾU KHÁM
-- =========================================================================

CREATE OR ALTER FUNCTION dbo.fn_TinhTongTienThuocTheoPhieuKham
(
    @MaPhieuKham VARCHAR(15)
)
RETURNS DECIMAL(12, 0)
AS
BEGIN
    DECLARE @TongTienThuoc DECIMAL(12, 0) = 0;

    SELECT @TongTienThuoc = ISNULL(SUM(CAST(dt.SoLuong AS DECIMAL(12, 0)) * t.DonGiaBan), 0)
    FROM dbo.DonThuoc dt
    JOIN dbo.Thuoc t ON dt.MaThuoc = t.MaThuoc
    WHERE dt.MaPhieuKham = @MaPhieuKham;

    RETURN @TongTienThuoc;
END;
GO


-- =========================================================================
-- 3. TRIGGER CẬP NHẬT TRẠNG THÁI GIƯỜNG
-- =========================================================================
CREATE OR ALTER TRIGGER TRG_CapNhatTrangThaiGiuong
ON NoiTru
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Kiểm tra trùng giường: Giường này có ai khác đang nằm không?
    IF EXISTS (
        SELECT 1 
        FROM inserted i
        JOIN NoiTru nt ON i.MaGiuong = nt.MaGiuong
        WHERE i.TrangThai = 'DangNam' 
          AND nt.TrangThai = 'DangNam'
          AND i.MaNoiTru <> nt.MaNoiTru
    )
    BEGIN
        RAISERROR (N'Giường này đã có người nằm!', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- 2. Cập nhật 'DangSuDung' cho giường vừa có người vào
    UPDATE GiuongBenh
    SET TrangThai = 'DangSuDung'
    WHERE MaGiuong IN (SELECT MaGiuong FROM inserted WHERE TrangThai = 'DangNam');

    -- 3. Trả về 'Trong' cho giường khi bệnh nhân xuất viện hoặc chuyển khoa
    UPDATE GiuongBenh
    SET TrangThai = 'Trong'
    WHERE MaGiuong IN (SELECT MaGiuong FROM inserted WHERE TrangThai IN ('DaXuatVien', 'ChuyenKhoa'));
END;
GO

-- =========================================================================
-- 4. TRIGGER TẠO THÔNG BÁO KHI CÓ KẾT QUẢ CẬN LÂM SÀNG
-- =========================================================================
CREATE OR ALTER TRIGGER trg_KetQuaCLS_Notification 
ON dbo.KetQuaCLS
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Chỉ tạo thông báo khi cột KetLuan được cập nhật giá trị mới
    INSERT INTO dbo.ThongBao (MaTaiKhoan, TieuDe, NoiDung, LoaiThongBao)
    SELECT 
        tk.MaTaiKhoan,
        N'Kết quả xét nghiệm mới',
        N'Đã có kết quả dịch vụ: ' + d.TenDichVu,
        'KET_QUA_XN'
    FROM inserted i
    JOIN deleted d_old ON i.MaKetQua = d_old.MaKetQua
    JOIN dbo.PhieuKham pk ON i.MaPhieuKham = pk.MaPhieuKham
    JOIN dbo.BenhNhan bn ON pk.MaBenhNhan = bn.MaBenhNhan
    JOIN dbo.TaiKhoan tk ON bn.MaTaiKhoan = tk.MaTaiKhoan
    JOIN dbo.DichVuCLS d ON i.MaDichVu = d.MaDichVu
    WHERE i.KetLuan IS NOT NULL 
      AND (d_old.KetLuan IS NULL OR d_old.KetLuan = '');
END;
GO

-------------------------------------------------------------------------
-- 5. TRIGGER KIỂM TRA THANH TOÁN TRƯỚC KHI PHÁT THUỐC
-------------------------------------------------------------------------

CREATE OR ALTER TRIGGER dbo.trg_KiemTraThanhToanTruocKhiPhatThuoc
ON dbo.DonThuoc
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra khi dược sĩ cập nhật trạng thái đơn thuốc sang 'DISPENSED'
    IF UPDATE(TrangThai)
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM inserted i
            JOIN deleted d ON i.MaDonThuoc = d.MaDonThuoc
            WHERE i.TrangThai IN ('DISPENSED', 'COMPLETED')
              AND ISNULL(d.TrangThai, '') NOT IN ('DISPENSED', 'COMPLETED')
              AND NOT EXISTS (
                  -- Kiểm tra xem phiếu khám này đã có hóa đơn thanh toán thành công chưa
                  SELECT 1 
                  FROM dbo.HoaDon hd
                  WHERE hd.MaPhieuKham = i.MaPhieuKham
                    AND hd.TrangThaiTT = 'DaThanhToan'
              )
        )
        BEGIN
            RAISERROR (N'Lỗi: Bệnh nhân chưa hoàn tất thanh toán hóa đơn tại quầy Thu ngân. Không thể phát thuốc!', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END
    END
END;
GO
