abstract class DbModel {
  static String tableName = 'set_me';

  String getTableName();

  Map<String, dynamic> toMap();
}