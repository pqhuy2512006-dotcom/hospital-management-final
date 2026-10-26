use QuanLyBenhVien
go

-- 3. Trigger Chặn xuất thuốc nếu chưa đóng tiền
CREATE OR ALTER TRIGGER dbo.trg_KiemTraThanhToanTruocKhiPhatThuoc ON dbo.DonThuoc AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    IF UPDATE(TrangThai)
    BEGIN
        IF EXISTS (
             SELECT 1 
             FROM inserted i JOIN deleted d ON i.MaDonThuoc = d.MaDonThuoc 
             WHERE i.TrangThai IN ('DISPENSED', 'COMPLETED') AND ISNULL(d.TrangThai, '') 
             NOT IN ('DISPENSED', 'COMPLETED') 
             AND NOT EXISTS (
                SELECT 1 FROM dbo.HoaDon hd 
                WHERE hd.MaPhieuKham = i.MaPhieuKham AND hd.TrangThaiTT = 'DaThanhToan'
                )
             )
        BEGIN
            RAISERROR (N'Lỗi: Bệnh nhân chưa hoàn tất thanh toán hóa đơn. Không thể phát thuốc!', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END
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