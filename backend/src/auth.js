import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";

const SALT_ROUNDS = 10;
const TOKEN_TTL = "7d";

export function getJwtSecret() {
  const secret = process.env.JWT_SECRET?.trim();
  if (secret) return secret;
  if (process.env.NODE_ENV === "production") {
    throw new Error("JWT_SECRET é obrigatório em produção");
  }
  return "dev-only-jwt-secret-change-me";
}

export async function hashPassword(plain) {
  return bcrypt.hash(plain, SALT_ROUNDS);
}

export async function verifyPassword(plain, hash) {
  return bcrypt.compare(plain, hash);
}

export function signToken(payload) {
  return jwt.sign(payload, getJwtSecret(), { expiresIn: TOKEN_TTL });
}

export function verifyToken(token) {
  return jwt.verify(token, getJwtSecret());
}

/** Middleware: exige Authorization: Bearer <token> */
export function requireAuth(req, res, next) {
  const header = req.headers.authorization ?? "";
  const match = /^Bearer\s+(.+)$/i.exec(header);
  const token = match?.[1]?.trim();

  if (!token) {
    return res.status(401).json({ error: "não autenticado" });
  }

  try {
    const decoded = verifyToken(token);
    req.user = {
      id: decoded.sub,
      perfil: decoded.perfil,
      identificador: decoded.identificador,
      nome: decoded.nome,
    };
    next();
  } catch {
    return res.status(401).json({ error: "token inválido ou expirado" });
  }
}
