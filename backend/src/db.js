import pg from "pg";

let pool = null;

export function getPool() {
  return pool;
}

export function isDbEnabled() {
  return Boolean(process.env.DATABASE_URL?.trim());
}

export async function initDb() {
  if (!isDbEnabled()) {
    console.log("[db] DATABASE_URL ausente — /api/chamadas usa lista fixa em memória.");
    return;
  }

  pool = new pg.Pool({
    connectionString: process.env.DATABASE_URL.trim(),
    max: 10,
    idleTimeoutMillis: 30_000,
    connectionTimeoutMillis: 10_000,
  });

  await pool.query(`
    CREATE TABLE IF NOT EXISTS chamadas (
      id TEXT PRIMARY KEY,
      turma TEXT NOT NULL,
      data DATE NOT NULL,
      presentes INTEGER NOT NULL DEFAULT 0
    );
  `);

  console.log("[db] Postgres conectado (ex.: Neon). Tabela chamadas pronta.");
}

export async function pingDb() {
  if (!pool) return { ok: false, reason: "disabled" };
  await pool.query("SELECT 1");
  return { ok: true };
}

/** @returns {Promise<Array<{id: string, turma: string, data: string, presentes: number}>>} */
export async function listChamadas() {
  if (!pool) return null;
  const r = await pool.query(
    `SELECT id, turma, data::text AS data, presentes
     FROM chamadas
     ORDER BY data DESC, id DESC
     LIMIT 200`,
  );
  return r.rows.map((row) => ({
    id: String(row.id),
    turma: row.turma,
    data: String(row.data).slice(0, 10),
    presentes: Number(row.presentes) || 0,
  }));
}

/**
 * @param {{ id: string, turma: string, data: string, presentes: number }} row
 */
export async function insertChamada(row) {
  if (!pool) throw new Error("database não configurado");
  await pool.query(
    `INSERT INTO chamadas (id, turma, data, presentes)
     VALUES ($1, $2, $3::date, $4)`,
    [row.id, row.turma, row.data, row.presentes],
  );
}
