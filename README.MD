# Xây dựng hệ thống nhận dạng giọng nói trên bộ công cụ Kaldi

## Hướng dẫn cài đặt thư viện Kaldi
Kaldi được hỗ trợ cả trên các hệ thống UNIX và Window nhưng trên Window ít được hỗ trợ cũng như tiềm ẩn nhiều lỗi hơn. Vậy nên ở đây chúng ta khuyến nghị sử dụng môi trường UNIX hơn. Để cài đặt Kaldi có nhiều cách, sử dụng trình đóng gói môi trường chạy Docker cho phép ta cài đặt nhanh Kaldi chỉ với vài bước đơn giản, không phụ thuộc hệ điều hành cũng như ít xảy ra lỗi (hầu như không có).
1. Yêu cầu tiên quyết
- Môi trường Window/MacOS/Linux.
- Có kiến thức về Docker.
2. Cài đặt Docker
- Hướng dẫn cài đặt Docker cho bất kỳ hệ điều hành nào có sẵn trên [tài liệu](https://docs.docker.com/) của Docker.
3. Chạy Kaldi trên Docker
- Images Kaldi có sẵn trên [Docker hub](https://hub.docker.com/) với 2 phiên bản dùng CPU và GPU. Trong hướng dẫn này, để đơn giản chúng ta sử dụng phiên bản CPU.
- Lưu ý khi chạy container chúng ta sẽ mount ổ đĩa bên ngoài máy chứa các tệp dữ liệu âm thanh với thư mục chứa các tệp âm thanh trong công thức của chúng ta. Đồng thời mở port 8080 để sau này export model ra một service.
- Chạy container Kaldi bằng câu lệnh sau:
```sh
docker run -it -v path/to/wav/folder:/opt/kaldi/egs/vietnamese2/s5/wav -p 8080:8080 --name=my-kaldi kaldiasr/kaldi:latest
```

4. Làm quen với Kaldi
- Thư viện Kaldi có cấu trúc bao gồm các thư mục con bên trong như `egs`, `src`, `tools`, `misc`, và `windows`,.. Thư mục `egs` chứa các ví dụ trong đó có các công thức sử dụng được xây dựng sẵn trên các bộ dữ liệu khác nhau đã được thử nghiệm trên Kaldi; thư mục `src` chứa mã nguồn của thư viện Kaldi; thư mục tools chứa các công cụ bên ngoài cần thiết cho các quá trình xây dựng model cũng như các thư viện toán học; thư mục `misc` chứa nguồn một số bài báo về kaldi, các kịch bản chuyển đổi từ HTK sang Kaldi; thư mục `window` chứa hướng dẫn dành cho Window. Chúng ta quan tâm nhất đến thư mục `egs`, nơi chúng ta sẽ xây dựng model của riêng mình. Bên trong thư mục `egs` sẽ có các thư mục con `s3`, `s4`, `s5`,.. chính là các phiên bản của các công thức. Các thành phần chính của một công thức thường bao gồm: tệp `run.sh` chứa kịch bản sẽ được thực thi cho toàn bộ quá trình train và test; tệp `path.sh` thêm các thư mục cần thiết vào path; tệp `cmd.sh`chỉ định các lệnh nào sẽ được thực thi tương ứng với chế độ sử dụng GPU hoặc không; thư mục `data` chứa dữ liệu cần thiêt cho quá trình xậy dựng mô hình âm thanh và mô hình ngôn ngữ; thư mục `local` chứa các kịch bản thường chỉ dành riêng cho công thức đó như các bước chuẩn bị dữ liệu, đánh giá; thư mục `conf` chứa các cấu hình trong việc tạo các đặc trưng, giải mã,..; các thư mục `utils` và `steps` được lấy liên kết đến ví dụ `wsj` là các tiện ích hữu dụng và các bước thường được dùng đến trong quá trình train và test.
## Hướng dẫn training Model nhận dạng giọng nói bằng Kaldi
- Để thực hiện training model nhận dạng giọng nói, đầu tiên clone source mà tác giả đã chuẩn bị:
```sh
cd /opt/kaldi/egs
git clone https://github.com/hoanghung123vn/project vietnamese2
cd vietnamese2/s5
```
Tất cả mã nguồn của quá trình train nằm trên [github](https://github.com/hoanghung123vn/project).
## Thực hiện test với Model đã được xây dựng


## Đóng gói Model dưới dạng một dịch vụ