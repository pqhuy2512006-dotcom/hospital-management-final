use QuanLyBenhVien
go

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