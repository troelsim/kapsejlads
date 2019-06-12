import 'package:kapsejlads/main.dart';
import 'package:test/test.dart';

void main(){
  group("formatTime", (){
    test("positive number of seconds formatted as hh:mm:ss", (){
      expect(formatTime(30), "00:00:30");
      expect(formatTime(1), "00:00:01");
      expect(formatTime(90), "00:01:30");
      expect(formatTime(600), "00:10:00");
      expect(formatTime(3600), "01:00:00");
      expect(formatTime(3690), "01:01:30");
    });

    test("negative number of seconds formatted as -hh:mm:ss", (){
      expect(formatTime(-1), "-00:00:01");
      expect(formatTime(-90), "-00:01:30");
      expect(formatTime(-3690), "-01:01:30");
    });
  });

}
