/* ======================================================================
   03_Functions_Triggers.sql (15 Functions, 5 Triggers)
   ====================================================================== */
USE QuanLyBenhVien;
GO

-- =========================================================================
-- PHẦN I: DANH SÁCH FUNCTIONS (15 HÀM)
-- =========================================================================

-- 1. Hàm tính hàng đợi (Trọng tâm)
CREATE OR ALTER FUNCTION fn_TinhHangDoiKham
(
    @MaBacSi VARCHAR(15), @NgayKham DATE
)
RETURNS @ResultTable TABLE (MaLichHen VARCHAR(15), ThoiGianDuKienBatDau DATETIME, PhutChoDoi INT)
AS
BEGIN
    DECLARE @ThoiGianHienTai DATETIME = GETDATE();
    DECLARE @MocKetThuc DATETIME = @ThoiGianHienTai;
    DECLARE @BatDauKham DATETIME, @SoPhutKham INT;
    
    SELECT TOP 1 @BatDauKham = pk.NgayKham, @SoPhutKham = lh.ThoiGianKhamDuKien
    FROM dbo.LichHen lh JOIN dbo.PhieuKham pk ON lh.MaLichHen = pk.MaLichHen
    WHERE lh.TrangThai = 'DangKham' AND lh.NgayKham = @NgayKham AND lh.MaBacSi = @MaBacSi;

    IF @BatDauKham IS NOT NULL
    BEGIN
        SET @MocKetThuc = DATEADD(MINUTE, @SoPhutKham, @BatDauKham);
        IF @MocKetThuc < @ThoiGianHienTai SET @MocKetThuc = @ThoiGianHienTai;
    END

    DECLARE @DanhSachCho TABLE (STT INT IDENTITY(1,1), MaLichHen VARCHAR(15), GioHen DATETIME, ThoiGianKhamDuKien INT);

    INSERT INTO @DanhSachCho (MaLichHen, GioHen, ThoiGianKhamDuKien)
    SELECT MaLichHen, CAST(NgayKham AS DATETIME) + CAST(GioKham AS DATETIME), ThoiGianKhamDuKien
    FROM dbo.LichHen WHERE TrangThai = 'DangChoKham' AND NgayKham = @NgayKham AND MaBacSi = @MaBacSi ORDER BY GioKham;

    DECLARE @i INT = 1;
    DECLARE @TongSoCa INT = (SELECT COUNT(*) FROM @DanhSachCho);

    WHILE @i <= @TongSoCa
    BEGIN
        DECLARE @MaLH VARCHAR(15), @GioHen DATETIME, @PhutKham INT;
        SELECT @MaLH = MaLichHen, @GioHen = GioHen, @PhutKham = ThoiGianKhamDuKien FROM @DanhSachCho WHERE STT = @i;
        DECLARE @GioBatDau DATETIME = @MocKetThuc;
        IF @GioBatDau < @GioHen SET @GioBatDau = @GioHen;
        IF @GioBatDau < @ThoiGianHienTai SET @GioBatDau = @ThoiGianHienTai;

        INSERT INTO @ResultTable (MaLichHen, ThoiGianDuKienBatDau, PhutChoDoi)
        VALUES (@MaLH, @GioBatDau, DATEDIFF(MINUTE, @ThoiGianHienTai, @GioBatDau));
        SET @MocKetThuc = DATEADD(MINUTE, @PhutKham, @GioBatDau);
        SET @i = @i + 1;
    END
    RETURN;
END;
GO

-- 2. Tính tiền thuốc
CREATE OR ALTER FUNCTION dbo.fn_TinhTongTienThuocTheoPhieuKham (@MaPhieuKham VARCHAR(15))
RETURNS DECIMAL(12, 0) AS
BEGIN
    DECLARE @Tong DECIMAL(12, 0) = 0;
    SELECT @Tong = ISNULL(SUM(CAST(dt.SoLuong AS DECIMAL(12, 0)) * t.DonGiaBan), 0)
    FROM dbo.DonThuoc dt JOIN dbo.Thuoc t ON dt.MaThuoc = t.MaThuoc WHERE dt.MaPhieuKham = @MaPhieuKham;
    RETURN @Tong;
END;
GO

-- 3. Bệnh nhân xem kết quả khám
CREATE OR ALTER FUNCTION dbo.fn_BenhNhan_XemKetQuaKham (@MaBenhNhan VARCHAR(15)) RETURNS TABLE AS RETURN
(
    SELECT pk.MaPhieuKham, pk.NgayKham, pk.ChanDoan, pk.LoiDanBacSi, STRING_AGG(CAST(d.TenDichVu + N': ' + ISNULL(kq.KetLuan, N'Chờ kết quả') AS NVARCHAR(MAX)), ' | ') AS DanhSachKetQuaCLS
    FROM dbo.PhieuKham pk LEFT JOIN dbo.KetQuaCLS kq ON pk.MaPhieuKham = kq.MaPhieuKham LEFT JOIN dbo.DichVuCLS d ON kq.MaDichVu = d.MaDichVu
    WHERE pk.MaBenhNhan = @MaBenhNhan GROUP BY pk.MaPhieuKham, pk.NgayKham, pk.ChanDoan, pk.LoiDanBacSi
);
GO

-- 4. Bệnh nhân xem Hóa đơn
CREATE OR ALTER FUNCTION dbo.fn_BenhNhan_TraCuuHoaDon (@MaBenhNhan VARCHAR(15)) RETURNS TABLE AS RETURN
(
    SELECT hd.MaHoaDon, hd.MaPhieuKham, pk.NgayKham, hd.TongTienDichVu, hd.BHYTChiTra, hd.TongThanhToan, hd.TrangThaiTT, hd.NgayThanhToan
    FROM dbo.HoaDon hd JOIN dbo.PhieuKham pk ON hd.MaPhieuKham = pk.MaPhieuKham WHERE pk.MaBenhNhan = @MaBenhNhan
);
GO

-- 5. Bệnh nhân xem lịch hẹn
CREATE OR ALTER FUNCTION dbo.fn_BenhNhan_XemLichHenSapToi (@MaBenhNhan VARCHAR(15)) RETURNS TABLE AS RETURN
(
    SELECT lh.MaLichHen, lh.NgayKham, lh.GioKham, lh.MaBacSi, lh.LoaiKham, lh.TrangThai AS TrangThaiLichHen
    FROM dbo.LichHen lh WHERE lh.MaBenhNhan = @MaBenhNhan AND lh.NgayKham >= CAST(GETDATE() AS DATE) AND lh.TrangThai NOT IN ('DaHuy', 'DaKham')
);
GO

-- 6. Lễ tân đếm số ca hẹn
CREATE OR ALTER FUNCTION dbo.fn_DemSoCaHenTheoBacSi (@NgayKham DATE) RETURNS TABLE AS RETURN
(
    SELECT lh.MaBacSi, COUNT(lh.MaLichHen) AS TongSoLichHen, SUM(CASE WHEN lh.TrangThai = 'DangChoKham' THEN 1 ELSE 0 END) AS SoCaDangCho, SUM(CASE WHEN lh.TrangThai = 'DaKham' THEN 1 ELSE 0 END) AS SoCaDaKham
    FROM dbo.LichHen lh WHERE lh.NgayKham = @NgayKham AND lh.TrangThai <> 'DaHuy' GROUP BY lh.MaBacSi
);
GO

-- 7. Bác sĩ tra lịch sử bệnh nhân
CREATE OR ALTER FUNCTION dbo.fn_LichSuKhamBenhNhan (@MaBenhNhan VARCHAR(15)) RETURNS TABLE AS RETURN
(
    SELECT pk.MaPhieuKham, pk.NgayKham, pk.ChanDoan, pk.LoiDanBacSi, STRING_AGG(CAST(t.TenThuoc + ' (' + CAST(dt.SoLuong AS VARCHAR) + ' ' + dt.DonViTinh + ')' AS NVARCHAR(MAX)), ', ') AS DonThuocDaKe
    FROM dbo.PhieuKham pk LEFT JOIN dbo.DonThuoc dt ON pk.MaPhieuKham = dt.MaPhieuKham LEFT JOIN dbo.Thuoc t ON dt.MaThuoc = t.MaThuoc
    WHERE pk.MaBenhNhan = @MaBenhNhan GROUP BY pk.MaPhieuKham, pk.NgayKham, pk.ChanDoan, pk.LoiDanBacSi
);
GO

-- 8. Dược sĩ xem tồn kho
CREATE OR ALTER FUNCTION dbo.fn_DanhSachThuocSapHet() RETURNS TABLE AS RETURN
(
    SELECT MaThuoc, TenThuoc, DonViTinh, TonKhoHienTai, NguongCanhBao, DonGiaBan FROM dbo.Thuoc WHERE TonKhoHienTai <= NguongCanhBao
);
GO

-- 9. KTV xem danh sách xét nghiệm
CREATE OR ALTER FUNCTION dbo.fn_DanhSachCLSChotThucHien (@MaBenhNhan VARCHAR(15)) RETURNS TABLE AS RETURN
(
    SELECT kq.MaKetQua, pk.MaPhieuKham, bn.HoTen AS TenBenhNhan, d.TenDichVu, kq.LoaiXetNghiem
    FROM dbo.KetQuaCLS kq JOIN dbo.DichVuCLS d ON kq.MaDichVu = d.MaDichVu JOIN dbo.PhieuKham pk ON kq.MaPhieuKham = pk.MaPhieuKham JOIN dbo.BenhNhan bn ON pk.MaBenhNhan = bn.MaBenhNhan
    WHERE pk.MaBenhNhan = @MaBenhNhan AND (kq.KetLuan IS NULL OR kq.KetLuan = '')
);
GO

-- 10. Điều dưỡng xem bệnh nhân
CREATE OR ALTER FUNCTION dbo.fn_DanhSachBenhNhanNoiTruTheoPhong (@MaPhong VARCHAR(15)) RETURNS TABLE AS RETURN
(
    SELECT p.MaPhong, p.TenPhong, gb.MaGiuong, gb.SoGiuong, nt.MaNoiTru, bn.MaBenhNhan, bn.HoTen AS TenBenhNhan, bn.GioiTinh, nt.NgayNhapVien
    FROM dbo.Phong p JOIN dbo.GiuongBenh gb ON p.MaPhong = gb.MaPhong JOIN dbo.NoiTru nt ON gb.MaGiuong = nt.MaGiuong JOIN dbo.PhieuKham pk ON nt.MaPhieuKham = pk.MaPhieuKham JOIN dbo.BenhNhan bn ON pk.MaBenhNhan = bn.MaBenhNhan
    WHERE p.MaPhong = @MaPhong AND nt.TrangThai = 'DangNam'
);
GO

-- 11. Lịch uống thuốc Nội trú
CREATE OR ALTER FUNCTION dbo.fn_LichUongThuocBenhNhanNoiTru (@MaNoiTru VARCHAR(15)) RETURNS TABLE AS RETURN
(
    SELECT nt.MaNoiTru, bn.HoTen AS TenBenhNhan, t.TenThuoc, dt.SoLuong, dt.DonViTinh, dt.LieuDung, dt.CachDung
    FROM dbo.NoiTru nt JOIN dbo.PhieuKham pk ON nt.MaPhieuKham = pk.MaPhieuKham JOIN dbo.DonThuoc dt ON pk.MaPhieuKham = dt.MaPhieuKham JOIN dbo.Thuoc t ON dt.MaThuoc = t.MaThuoc JOIN dbo.BenhNhan bn ON pk.MaBenhNhan = bn.MaBenhNhan
    WHERE nt.MaNoiTru = @MaNoiTru AND nt.TrangThai = 'DangNam'
);
GO

-- 12. Tổng chi phí phiếu khám
CREATE OR ALTER FUNCTION dbo.fn_TinhTongChiPhiPhieuKham (@MaPhieuKham VARCHAR(15)) RETURNS DECIMAL(12, 0) AS
BEGIN
    DECLARE @TienCLS DECIMAL(12, 0) = 0, @TienThuoc DECIMAL(12, 0) = 0;
    SELECT @TienCLS = ISNULL(SUM(d.DonGia), 0) FROM dbo.KetQuaCLS k JOIN dbo.DichVuCLS d ON k.MaDichVu = d.MaDichVu WHERE k.MaPhieuKham = @MaPhieuKham;
    SET @TienThuoc = dbo.fn_TinhTongTienThuocTheoPhieuKham(@MaPhieuKham);
    RETURN (@TienCLS + @TienThuoc);
END;
GO

-- 13. Thống kê bác sĩ
CREATE OR ALTER FUNCTION dbo.fn_BaoCaoDoanhThuTheoBacSi (@TuNgay DATE, @DenNgay DATE) RETURNS TABLE AS RETURN
(
    SELECT lh.MaBacSi, COUNT(DISTINCT pk.MaPhieuKham) AS SoLuongLuotKham, ISNULL(SUM(hd.TongThanhToan), 0) AS TongDoanhThu
    FROM dbo.LichHen lh JOIN dbo.PhieuKham pk ON lh.MaLichHen = pk.MaLichHen JOIN dbo.HoaDon hd ON pk.MaPhieuKham = hd.MaPhieuKham
    WHERE hd.TrangThaiTT = 'DaThanhToan' AND CAST(hd.NgayThanhToan AS DATE) BETWEEN @TuNgay AND @DenNgay GROUP BY lh.MaBacSi
);
GO

-- 14. Thống kê CLS
CREATE OR ALTER FUNCTION dbo.fn_ThongKeSuDungDichVuCLS (@TuNgay DATE, @DenNgay DATE) RETURNS TABLE AS RETURN
(
    SELECT d.MaDichVu, d.TenDichVu, d.DonGia, COUNT(kq.MaKetQua) AS SoLuotChiDinh, ISNULL(SUM(d.DonGia), 0) AS TongDoanhThuCLS
    FROM dbo.DichVuCLS d LEFT JOIN dbo.KetQuaCLS kq ON d.MaDichVu = kq.MaDichVu LEFT JOIN dbo.PhieuKham pk ON kq.MaPhieuKham = pk.MaPhieuKham
    WHERE pk.NgayKham IS NULL OR CAST(pk.NgayKham AS DATE) BETWEEN @TuNgay AND @DenNgay GROUP BY d.MaDichVu, d.TenDichVu, d.DonGia
);
GO

-- 15. Thống kê giường
CREATE OR ALTER FUNCTION dbo.fn_BaoCaoCongSuatGiuong() RETURNS TABLE AS RETURN
(
    SELECT p.MaPhong, p.TenPhong, COUNT(gb.MaGiuong) AS TongSoGiuong, SUM(CASE WHEN gb.TrangThai = 'DangSuDung' THEN 1 ELSE 0 END) AS SoGiuongDangDung, SUM(CASE WHEN gb.TrangThai = 'Trong' THEN 1 ELSE 0 END) AS SoGiuongTrong, CAST(SUM(CASE WHEN gb.TrangThai = 'DangSuDung' THEN 1.0 ELSE 0.0 END) / COUNT(gb.MaGiuong) * 100 AS DECIMAL(5, 2)) AS TyLeLapDienPercent
    FROM dbo.Phong p JOIN dbo.GiuongBenh gb ON p.MaPhong = gb.MaPhong GROUP BY p.MaPhong, p.TenPhong
);
GO


-- =========================================================================
-- PHẦN II: DANH SÁCH TRIGGERS (5 TRIGGERS)
-- =========================================================================

-- 1. Trigger Cập nhật giường
CREATE OR ALTER TRIGGER TRG_CapNhatTrangThaiGiuong ON NoiTru AFTER INSERT, UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM inserted i JOIN NoiTru nt ON i.MaGiuong = nt.MaGiuong WHERE i.TrangThai = 'DangNam' AND nt.TrangThai = 'DangNam' AND i.MaNoiTru <> nt.MaNoiTru)
    BEGIN
        RAISERROR (N'Giường này đã có người nằm!', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
    UPDATE GiuongBenh SET TrangThai = 'DangSuDung' WHERE MaGiuong IN (SELECT MaGiuong FROM inserted WHERE TrangThai = 'DangNam');
    UPDATE GiuongBenh SET TrangThai = 'Trong' WHERE MaGiuong IN (SELECT MaGiuong FROM inserted WHERE TrangThai IN ('DaXuatVien', 'ChuyenKhoa'));
END;
GO

-- 2. Trigger Thông báo CLS
CREATE OR ALTER TRIGGER trg_KetQuaCLS_Notification ON dbo.KetQuaCLS AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.ThongBao (MaTaiKhoan, TieuDe, NoiDung, LoaiThongBao)
    SELECT tk.MaTaiKhoan, N'Kết quả xét nghiệm mới', N'Đã có kết quả dịch vụ: ' + d.TenDichVu, 'KET_QUA_XN'
    FROM inserted i JOIN deleted d_old ON i.MaKetQua = d_old.MaKetQua JOIN dbo.PhieuKham pk ON i.MaPhieuKham = pk.MaPhieuKham JOIN dbo.BenhNhan bn ON pk.MaBenhNhan = bn.MaBenhNhan JOIN dbo.TaiKhoan tk ON bn.MaTaiKhoan = tk.MaTaiKhoan JOIN dbo.DichVuCLS d ON i.MaDichVu = d.MaDichVu
    WHERE i.KetLuan IS NOT NULL AND (d_old.KetLuan IS NULL OR d_old.KetLuan = '');
END;
GO

-- 3. Trigger Chặn xuất thuốc nếu chưa đóng tiền
CREATE OR ALTER TRIGGER dbo.trg_KiemTraThanhToanTruocKhiPhatThuoc ON dbo.DonThuoc AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF UPDATE(TrangThai)
    BEGIN
        IF EXISTS (SELECT 1 FROM inserted i JOIN deleted d ON i.MaDonThuoc = d.MaDonThuoc WHERE i.TrangThai IN ('DISPENSED', 'COMPLETED') AND ISNULL(d.TrangThai, '') NOT IN ('DISPENSED', 'COMPLETED') AND NOT EXISTS (SELECT 1 FROM dbo.HoaDon hd WHERE hd.MaPhieuKham = i.MaPhieuKham AND hd.TrangThaiTT = 'DaThanhToan'))
        BEGIN
            RAISERROR (N'Lỗi: Bệnh nhân chưa hoàn tất thanh toán hóa đơn. Không thể phát thuốc!', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END
    END
END;
GO

-- 4. Trigger Kiểm tra Tuổi Bệnh Nhân
CREATE OR ALTER TRIGGER TRG_KiemTraTuoiBenhNhan ON dbo.BenhNhan AFTER INSERT, UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM inserted WHERE NgaySinh > GETDATE())
    BEGIN
        RAISERROR (N'Lỗi: Ngày sinh của bệnh nhân không được lớn hơn ngày hiện tại!', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO

-- 5. Trigger Tự động cộng dồn tồn kho khi Nhập kho
CREATE OR ALTER TRIGGER TRG_TuDongCapNhatTonKhoKhiNhap ON dbo.ChiTietNhapKho AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    UPDATE t SET t.TonKhoHienTai = t.TonKhoHienTai + i.SoLuong
    FROM dbo.Thuoc t JOIN inserted i ON t.MaThuoc = i.MaThuoc;
END;
GO