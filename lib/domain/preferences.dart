import 'package:json_annotation/json_annotation.dart';
import 'package:realearn_companion/domain/connection.dart';

part 'preferences.g.dart';

@JsonSerializable(nullable: true)
class RecentConnection {
  final String host;
  final String httpPort;
  final String httpsPort;
  final String sessionId;
  final String certContent;

  RecentConnection(
      {this.host,
      this.httpPort,
      this.httpsPort,
      this.sessionId,
      this.certContent});

  factory RecentConnection.fromJson(Map<String, dynamic> json) =>
      _$RecentConnectionFromJson(json);

  Map<String, dynamic> toJson() => _$RecentConnectionToJson(this);

  factory RecentConnection.fromPalette(ConnectionDataPalette palette) {
    return RecentConnection(
      host: palette.host,
      httpPort: palette.httpPort,
      httpsPort: palette.httpsPort,
      sessionId: palette.sessionId,
      certContent: palette.certContent,
    );
  }

  ConnectionDataPalette toPalette() {
    return ConnectionDataPalette(
      host: host,
      httpPort: httpPort,
      httpsPort: httpsPort,
      sessionId: sessionId,
      // Recent connections are only saved as recent connection if we already
      // managed to successfully connect. So there's no possibility for typos.
      isGenerated: true,
      certContent: certContent,
    );
  }
}
