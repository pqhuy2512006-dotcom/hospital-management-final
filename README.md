# Hospital Management

Hệ thống quản lý bệnh viện được xây dựng bằng Spring Boot, Spring JDBC, Spring Security và SQL Server. Các repository đọc dữ liệu qua database views và ghi qua stored procedures.

## Yêu cầu môi trường

Trên Windows, bạn cần chuẩn bị:

- JDK 21
- Apache Maven (project đã có Maven Wrapper nên không bắt buộc cài riêng)
- SQL Server Express hoặc SQL Server Developer
- SQL Server Management Studio (SSMS) để quản lý database

## Cấu hình dự án hiện tại

Project đang dùng SQL Server instance `SQLEXPRESS` và database:

- Database: `QuanLyBenhVien`
- User: `sa`
- Password: `YourPassword123@`

Chuỗi kết nối mặc định trong project là:

```properties
spring.datasource.url=jdbc:sqlserver://localhost\\SQLEXPRESS;databaseName=QuanLyBenhVien;encrypt=true;trustServerCertificate=true;
spring.datasource.username=sa
spring.datasource.password=YourPassword123@
```

File cấu hình:

- [src/main/resources/application.properties](src/main/resources/application.properties)

## Bước 1: Cài đặt Java 21

1. Cài JDK 21 trên máy Windows.
2. Kiểm tra bằng lệnh:

```powershell
java -version
```

Nếu chưa đúng, hãy thiết lập `JAVA_HOME`.

## Bước 2: Cài đặt và khởi động SQL Server

Nếu bạn đã cài SQL Server Express, kiểm tra service sau đang chạy:

- `SQL Server (SQLEXPRESS)`
- `SQL Server Browser`

Nếu chưa chạy, mở `services.msc` và start lên.

## Bước 3: Kết nối SQL Server bằng SSMS

Mở SSMS và kết nối với:

- Server name: `localhost\SQLEXPRESS`
- Authentication: `SQL Server Authentication`
- Login: `sa`
- Password: `YourPassword123@`

Nếu `sa` chưa hoạt động, hãy:

1. Kết nối bằng Windows Authentication
2. Vào `Security` -> `Logins`
3. Chọn `sa`
4. `Properties`
5. Ở tab `Status`, chọn `Enabled`
6. Ở tab `General`, đặt lại password là `YourPassword123@`
7. Nhấn `OK`
8. Restart SQL Server service

## Bước 4: Tạo database

Mở file:

- [database/projectQLBV.sql](database/projectQLBV.sql)

Chạy toàn bộ script trong SSMS để tạo database `QuanLyBenhVien`.

Nếu database đã được tạo trước đó, chạy thêm [database/AppointmentDuration.sql](database/AppointmentDuration.sql) để bổ sung thời lượng dự kiến cho lịch hẹn hiện có. Script tự gán 45 phút cho khám dịch vụ và 30 phút cho khám thường/tái khám.

Chạy [database/AppointmentStatus.sql](database/AppointmentStatus.sql) để gộp trạng thái lịch hẹn cũ `ChoXacNhan`/`DaXacNhan` thành `DaDatLich` và cập nhật constraint/default cho database hiện có.

Sau khi tạo schema cơ sở, chạy thêm [database/DoctorReferral.sql](database/DoctorReferral.sql) để tạo bảng lưu yêu cầu chuyển khoa/hội chẩn của bác sĩ.

Sau đó chạy thêm script tạo bảng nhật ký truy cập:

- [database/AuditLog.sql](database/AuditLog.sql)

Script này chỉ bổ sung bảng `AuditLog`, không xóa dữ liệu nghiệp vụ.

Để ứng dụng dùng database views cho thao tác đọc và stored procedures cho thao tác ghi, chạy tiếp theo thứ tự:

1. [database/AccountDatabaseObjects.sql](database/AccountDatabaseObjects.sql)
2. [database/EntityViews.sql](database/EntityViews.sql)
3. [database/EntityWriteProcedures.sql](database/EntityWriteProcedures.sql)

Các script trên dùng `CREATE OR ALTER` và không xóa dữ liệu bảng nghiệp vụ.

## Tài khoản mặc định của ứng dụng

Tài khoản ứng dụng để đăng nhập vào hệ thống qua giao diện web:

- Tên đăng nhập: `admin`
- Mật khẩu: `admin123`
- Vai trò: `QuanTri`

Dữ liệu mặc định này nằm trong bảng `TaiKhoan` và được seed qua file:

- [database/Data.sql](database/Data.sql)

Tài khoản ứng dụng khác với tài khoản SQL Server `sa`. Sau khi đăng nhập Admin, có thể cấp tài khoản nhân viên, đổi vai trò, khóa/mở khóa và đặt lại mật khẩu trong mục Cấu hình hệ thống.

## Bước 5: Chạy project trên Windows

Mở PowerShell trong thư mục dự án:

```powershell
cd "c:\Users\Nguyen Dinh Khanh\Documents\GitHub\hospital-management"
```

Sau đó chạy:

```powershell
.\mvnw.cmd spring-boot:run
```

Hoặc build và chạy JAR:

```powershell
.\mvnw.cmd clean package
java -jar target\hospital-management-0.0.1-SNAPSHOT.jar
```

## Bước 6: Mở ứng dụng

Sau khi Spring Boot khởi động thành công, truy cập:

```text
http://localhost:8080/login.html
```

Hoặc:

```text
http://localhost:8080
```

## Lưu ý quan trọng

- Dự án hiện đang dùng SQL Server instance `SQLEXPRESS`, không phải default instance `1433`.
- Nếu bạn đổi mật khẩu `sa`, hãy cập nhật lại file [src/main/resources/application.properties](src/main/resources/application.properties).
- Nếu bạn đang dùng SQL Server khác (instance khác tên, port khác), cần sửa URL datasource cho đúng.

## Các lỗi thường gặp

### 1. Login failed for user 'sa'

Nguyên nhân thường là:

- password `sa` sai
- login `sa` bị disabled
- SQL Server Authentication chưa được bật

Giải pháp:

- Kết nối bằng Windows Authentication
- Vào `Security -> Logins -> sa`
- Set password lại
- Enable login
- Restart SQL Server

### 2. Error 233: No process is on the other end of the pipe

Nguyên nhân thường là:

- SQL Server instance chưa chạy
- dùng sai instance / port
- SQL Browser bị tắt

Giải pháp:

- Kiểm tra service `SQL Server (SQLEXPRESS)`
- Kiểm tra `SQL Server Browser`
- Đảm bảo dùng đúng instance `localhost\SQLEXPRESS`

### 3. Whitelabel Error Page / 404

Đây thường là do bạn truy cập sai URL.

- Đúng: `http://localhost:8080/login.html`
- Sai: `http://localhost:8080/` hoặc URL không tồn tại

## Tài liệu quan trọng trong repo

- [database/projectQLBV.sql](database/projectQLBV.sql)
- [src/main/resources/application.properties](src/main/resources/application.properties)
- [src/main/resources/static/login.html](src/main/resources/static/login.html)

## Kết luận

Sau khi cài JDK 21, khởi động SQL Server, tạo database và chạy Maven wrapper, project sẽ chạy trên Windows bằng lệnh:

```powershell
.\mvnw.cmd spring-boot:run
```
