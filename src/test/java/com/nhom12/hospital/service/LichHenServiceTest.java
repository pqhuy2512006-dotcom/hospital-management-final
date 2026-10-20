package com.nhom12.hospital.service;

import com.nhom12.hospital.repository.BenhNhanRepository;
import com.nhom12.hospital.repository.KhoaRepository;
import com.nhom12.hospital.repository.LichHenRepository;
import com.nhom12.hospital.repository.NhanVienRepository;
import com.nhom12.hospital.repository.TaiKhoanRepository;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class LichHenServiceTest {

    private final LichHenRepository lichHenRepository = mock(LichHenRepository.class);
    private final LichHenService service = new LichHenService(
            lichHenRepository,
            mock(BenhNhanRepository.class),
            mock(KhoaRepository.class),
            mock(NhanVienRepository.class),
            mock(TaiKhoanRepository.class)
    );

    @Test
    void includesLastThirtyMinuteSlotEndingAtMidnight() {
        LocalDate date = LocalDate.now().plusDays(1);
        when(lichHenRepository.findByMaBacSiAndNgayKham("doctor-1", date)).thenReturn(List.of());

        List<String> slots = service.getAvailableSlots("doctor-1", date.toString(), "KhamThuong");

        assertEquals("23:30", slots.getLast());
        assertEquals(LocalTime.MIDNIGHT, LocalTime.parse(slots.getLast()).plusMinutes(30));
    }

    @Test
    void includesLastFortyFiveMinuteSlotEndingAtMidnight() {
        LocalDate date = LocalDate.now().plusDays(1);
        when(lichHenRepository.findByMaBacSiAndNgayKham("doctor-1", date)).thenReturn(List.of());

        List<String> slots = service.getAvailableSlots("doctor-1", date.toString(), "KhamDichVu");

        assertEquals("23:00", slots.getLast());
        LocalDateTime visitEnd = LocalDateTime.of(date, LocalTime.parse(slots.getLast())).plusMinutes(45);
        assertFalse(visitEnd.isAfter(LocalDateTime.of(date.plusDays(1), LocalTime.MIDNIGHT)));
    }
}
