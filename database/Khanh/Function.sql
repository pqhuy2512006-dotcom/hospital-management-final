use QuanLyBenhVien
go

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

-- 12. Tổng chi phí phiếu khám
CREATE OR ALTER FUNCTION dbo.fn_TinhTongChiPhiPhieuKham (@MaPhieuKham VARCHAR(15)) RETURNS DECIMAL(12, 0) AS
BEGIN
    DECLARE @TienCLS DECIMAL(12, 0) = 0, @TienThuoc DECIMAL(12, 0) = 0;
    SELECT @TienCLS = ISNULL(SUM(d.DonGia), 0) FROM dbo.KetQuaCLS k JOIN dbo.DichVuCLS d ON k.MaDichVu = d.MaDichVu WHERE k.MaPhieuKham = @MaPhieuKham;
    SET @TienThuoc = dbo.fn_TinhTongTienThuocTheoPhieuKham(@MaPhieuKham);
    RETURN (@TienCLS + @TienThuoc);
END;
GO