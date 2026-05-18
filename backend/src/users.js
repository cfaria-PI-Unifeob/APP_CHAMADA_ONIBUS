import { randomUUID } from "node:crypto";

import { hashPassword, verifyPassword } from "./auth.js";
import { getPool, isDbEnabled } from "./db.js";

/** @type {Map<string, { id: string, perfil: string, identificador: string, senha_hash: string, nome: string, email: string, telefone: string | null }>} */
const memoryUsers = new Map();

function memoryKey(perfil, identificador) {
  return `${perfil}:${identificador.trim().toLowerCase()}`;
}

export async function initUsers() {
  const pool = getPool();
  if (!pool) return;

  await pool.query(`
    CREATE TABLE IF NOT EXISTS usuarios (
      id TEXT PRIMARY KEY,
      perfil TEXT NOT NULL CHECK (perfil IN ('aluno', 'motorista')),
      identificador TEXT NOT NULL,
      senha_hash TEXT NOT NULL,
      nome TEXT NOT NULL,
      email TEXT NOT NULL,
      telefone TEXT,
      criado_em TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      UNIQUE (perfil, identificador)
    );
  `);
}

/**
 * @param {{ perfil: string, identificador: string, senha: string, nome: string, email: string, telefone?: string | null }} data
 */
export async function registerUser(data) {
  const perfil = data.perfil === "motorista" ? "motorista" : "aluno";
  const identificador = String(data.identificador ?? "").trim();
  const nome = String(data.nome ?? "").trim();
  const email = String(data.email ?? "").trim().toLowerCase();
  const telefone = data.telefone ? String(data.telefone).trim() : null;
  const senha = String(data.senha ?? "");

  if (!identificador) throw new Error("identificador é obrigatório");
  if (senha.length < 6) throw new Error("senha deve ter no mínimo 6 caracteres");
  if (nome.length < 3) throw new Error("nome inválido");
  if (!email.includes("@")) throw new Error("e-mail inválido");
  if (perfil === "motorista" && (!telefone || telefone.length < 8)) {
    throw new Error("telefone é obrigatório para motorista");
  }

  const senha_hash = await hashPassword(senha);
  const id = randomUUID();

  const pool = getPool();
  if (pool) {
    try {
      await pool.query(
        `INSERT INTO usuarios (id, perfil, identificador, senha_hash, nome, email, telefone)
         VALUES ($1, $2, $3, $4, $5, $6, $7)`,
        [id, perfil, identificador, senha_hash, nome, email, telefone],
      );
    } catch (e) {
      if (e?.code === "23505") {
        throw new Error("usuário já cadastrado com este identificador");
      }
      throw e;
    }
    return { id, perfil, identificador, nome, email, telefone };
  }

  const key = memoryKey(perfil, identificador);
  if (memoryUsers.has(key)) {
    throw new Error("usuário já cadastrado com este identificador");
  }

  const user = {
    id,
    perfil,
    identificador,
    senha_hash,
    nome,
    email,
    telefone,
  };
  memoryUsers.set(key, user);
  return {
    id: user.id,
    perfil: user.perfil,
    identificador: user.identificador,
    nome: user.nome,
    email: user.email,
    telefone: user.telefone,
  };
}

/**
 * @param {{ perfil: string, identificador: string, senha: string }} creds
 */
export async function loginUser(creds) {
  const perfil = creds.perfil === "motorista" ? "motorista" : "aluno";
  const identificador = String(creds.identificador ?? "").trim();
  const senha = String(creds.senha ?? "");

  if (!identificador || !senha) {
    throw new Error("identificador e senha são obrigatórios");
  }

  const pool = getPool();
  let row = null;

  if (pool) {
    const r = await pool.query(
      `SELECT id, perfil, identificador, senha_hash, nome, email, telefone
       FROM usuarios
       WHERE perfil = $1 AND identificador = $2
       LIMIT 1`,
      [perfil, identificador],
    );
    row = r.rows[0] ?? null;
  } else {
    row = memoryUsers.get(memoryKey(perfil, identificador)) ?? null;
  }

  if (!row) {
    throw new Error("credenciais inválidas");
  }

  const ok = await verifyPassword(senha, row.senha_hash);
  if (!ok) {
    throw new Error("credenciais inválidas");
  }

  return {
    id: row.id,
    perfil: row.perfil,
    identificador: row.identificador,
    nome: row.nome,
    email: row.email,
    telefone: row.telefone ?? null,
  };
}

export function authStorageHint() {
  if (isDbEnabled()) return "postgres";
  return "memory";
}
