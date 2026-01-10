import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// 会话级加解密工具：
/// 使用与后端一致的 AES-256-GCM 算法，
/// 密文格式：Base64( 12字节IV || cipherBytes || 16字节Tag )。
class ConversationCrypto {
  static const int _ivLength = 12;
  static const int _tagLength = 16;

  final AesGcm _algorithm = AesGcm.with256bits();
  final SecretKey _secretKey;

  ConversationCrypto._(this._secretKey);

  /// 从后端返回的 Base64 conversationKey 创建实例（32 字节随机 key）。
  factory ConversationCrypto.fromBase64Key(String base64Key) {
    final keyBytes = base64Decode(base64Key);
    if (keyBytes.length != 32) {
      throw ArgumentError('conversationKey length must be 32 bytes');
    }
    return ConversationCrypto._(SecretKey(keyBytes));
  }

  /// 加密一条明文消息，返回 Base64(iv || cipher || tag)。
  Future<String> encryptContent(String plaintext) async {
    final plainBytes = utf8.encode(plaintext);
    final nonce = await _algorithm.newNonce(); // 12 字节 IV

    final secretBox = await _algorithm.encrypt(
      plainBytes,
      secretKey: _secretKey,
      nonce: nonce,
    );

    final cipherBytes = secretBox.cipherText;
    final tagBytes = secretBox.mac.bytes;

    final allLength = nonce.length + cipherBytes.length + tagBytes.length;
    final allBytes = Uint8List(allLength);
    allBytes.setRange(0, nonce.length, nonce);
    allBytes.setRange(nonce.length, nonce.length + cipherBytes.length, cipherBytes);
    allBytes.setRange(
      nonce.length + cipherBytes.length,
      allLength,
      tagBytes,
    );

    return base64Encode(allBytes);
  }

  /// 解密一条消息内容（Base64(iv || cipher || tag)）。
  Future<String> decryptContent(String base64IvAndCipher) async {
    final allBytes = base64Decode(base64IvAndCipher);
    if (allBytes.length <= _ivLength + _tagLength) {
      throw ArgumentError('cipher text too short');
    }

    final iv = allBytes.sublist(0, _ivLength);
    final cipherAndTag = allBytes.sublist(_ivLength);
    final cipherBytes =
        cipherAndTag.sublist(0, cipherAndTag.length - _tagLength);
    final tagBytes =
        cipherAndTag.sublist(cipherAndTag.length - _tagLength);

    final secretBox = SecretBox(
      cipherBytes,
      nonce: iv,
      mac: Mac(tagBytes),
    );

    final clearBytes =
        await _algorithm.decrypt(secretBox, secretKey: _secretKey);
    return utf8.decode(clearBytes);
  }
}
