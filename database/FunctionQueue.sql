USE QuanLyBenhVien;
GO

-- =========================================================================
-- HÀM TÍNH TOÁN HÀNG ĐỢI VÀ THỜI GIAN CHỜ DỰ KIẾN (Bao gồm giới hạn khám lố)
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
    DECLARE @CurrentTime DATETIME = GETDATE();
    DECLARE @RunningEndTime DATETIME = @CurrentTime;
    
    -- 1. Xử lý ca đang khám ('DangKham') để tìm mốc xuất phát của hàng đợi
    DECLARE @DangKham_MaLichHen VARCHAR(15);
    DECLARE @DangKham_BatDau DATETIME;
    DECLARE @DangKham_ThoiGianDuKien INT;
    DECLARE @DangKham_Scheduled DATETIME;
    
    SELECT TOP 1 
        @DangKham_MaLichHen = lh.MaLichHen,
        @DangKham_BatDau = pk.NgayKham,
        @DangKham_ThoiGianDuKien = lh.ThoiGianKhamDuKien,
        @DangKham_Scheduled = CAST(lh.NgayKham AS DATETIME) + CAST(lh.GioKham AS DATETIME)
    FROM dbo.LichHen lh
    JOIN dbo.PhieuKham pk ON lh.MaLichHen = pk.MaLichHen
    WHERE lh.TrangThai = 'DangKham' 
      AND lh.NgayKham = @NgayKham
      AND lh.MaBacSi = @MaBacSi
    ORDER BY lh.GioKham;
    
    IF @DangKham_MaLichHen IS NOT NULL
    BEGIN
        -- Tính mốc thời gian kết thúc lý tưởng của ca đang khám
        DECLARE @CalculatedEnd DATETIME = DATEADD(MINUTE, @DangKham_ThoiGianDuKien, @DangKham_BatDau);
        
        -- Tính mốc TỐI ĐA được phép kết thúc (Giờ hẹn + Thời lượng + 10 phút lố)
        DECLARE @MaxAllowedEnd DATETIME = DATEADD(MINUTE, @DangKham_ThoiGianDuKien + 10, @DangKham_Scheduled);
        
        -- Nếu bác sĩ khám lố quá mức trần, ép thời gian tính toán về mức trần
        -- (Để đảm bảo thuật toán không cộng dồn thời gian trễ vô tận cho người sau)
        IF @CalculatedEnd > @MaxAllowedEnd
            SET @CalculatedEnd = @MaxAllowedEnd;
            
        -- Nếu thời gian kết thúc dự kiến đã nằm trong quá khứ (tức là ca này đáng ra phải xong rồi)
        -- Thì mốc bắt đầu của người tiếp theo sớm nhất là "Bây giờ"
        IF @CalculatedEnd < @CurrentTime
            SET @CalculatedEnd = @CurrentTime; 
            
        SET @RunningEndTime = @CalculatedEnd;
    END

    -- 2. Dùng con trỏ (Cursor) duyệt qua danh sách bệnh nhân đang đợi ('DaDatLich')
    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT MaLichHen, 
               CAST(NgayKham AS DATETIME) + CAST(GioKham AS DATETIME) AS GioHenScheduled, 
               ThoiGianKhamDuKien
        FROM dbo.LichHen
        WHERE TrangThai = 'DangChoKham'
          AND NgayKham = @NgayKham
          AND MaBacSi = @MaBacSi
        ORDER BY GioKham;
        
    OPEN cur;
    DECLARE @Id VARCHAR(15), @Sched DATETIME, @Dur INT;
    
    FETCH NEXT FROM cur INTO @Id, @Sched, @Dur;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Thời gian bắt đầu dự kiến của người này
        DECLARE @ExpectedStart DATETIME = @RunningEndTime;
        
        -- QUY TẮC QUAN TRỌNG: Không được gọi bệnh nhân vào khám sớm hơn giờ hẹn gốc
        IF @ExpectedStart < @Sched
            SET @ExpectedStart = @Sched;
            
        -- Thực tế: Không thể báo thời gian bắt đầu nằm ở quá khứ
        IF @ExpectedStart < @CurrentTime
            SET @ExpectedStart = @CurrentTime;
            
        -- Tính số phút chờ đợi
        DECLARE @WaitMins INT = DATEDIFF(MINUTE, @CurrentTime, @ExpectedStart);
        
        -- Lưu kết quả
        INSERT INTO @ResultTable(MaLichHen, ThoiGianDuKienBatDau, PhutChoDoi)
        VALUES (@Id, @ExpectedStart, @WaitMins);
        
        -- Cập nhật RunningEndTime (cộng thêm thời lượng khám của người này) để tính cho người đứng sau
        SET @RunningEndTime = DATEADD(MINUTE, @Dur, @ExpectedStart);
        
        FETCH NEXT FROM cur INTO @Id, @Sched, @Dur;
    END
    
    CLOSE cur;
    DEALLOCATE cur;
    
    RETURN;
END;
GO
