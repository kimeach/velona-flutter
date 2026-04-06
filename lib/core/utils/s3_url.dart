import '../constants/api_constants.dart';

class S3Url {
  static String video(int projectId) =>
      '${ApiConstants.s3Base}/$projectId/video.mp4';

  static String slide(int projectId) =>
      '${ApiConstants.s3Base}/$projectId/slide.html';

  static String thumbnail(int projectId) =>
      '${ApiConstants.s3Base}/$projectId/thumbnail.png';
}
