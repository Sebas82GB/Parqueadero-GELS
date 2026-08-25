export class RefreshToken {
  constructor({ id, usuarioId, tokenHash, expiresAt, revokedAt, createdAt }) {
    this.id = id;
    this.usuarioId = usuarioId;
    this.tokenHash = tokenHash;
    this.expiresAt = expiresAt;
    this.revokedAt = revokedAt;
    this.createdAt = createdAt;
  }

  static toDomain(record) {
    return new RefreshToken({
      id: record.id,
      usuarioId: record.usuarioId,
      tokenHash: record.tokenHash,
      expiresAt: record.expiresAt,
      revokedAt: record.revokedAt,
      createdAt: record.createdAt,
    });
  }

  static toPersistence({ usuarioId, tokenHash, expiresAt, revokedAt } = {}) {
    const data = {};
    if (usuarioId !== undefined) data.usuarioId = usuarioId;
    if (tokenHash !== undefined) data.tokenHash = tokenHash;
    if (expiresAt !== undefined) data.expiresAt = expiresAt;
    if (revokedAt !== undefined) data.revokedAt = revokedAt;
    return data;
  }
}
