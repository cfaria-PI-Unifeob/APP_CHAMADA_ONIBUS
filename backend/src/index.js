import express from "express";
import cors from "cors";
import OpenAI from "openai";

import { requireAuth, signToken } from "./auth.js";
import {
  initDb,
  insertChamada,
  isDbEnabled,
  listChamadas,
  pingDb,
} from "./db.js";
import {
  authStorageHint,
  initUsers,
  loginUser,
  registerUser,
} from "./users.js";

const app = express();

const PORT = Number(process.env.PORT) || 3000;

app.use(express.json());

const corsOrigins = process.env.CORS_ORIGIN
  ?.split(",")
  .map((s) => s.trim())
  .filter(Boolean);

app.use(
  cors({
    origin: corsOrigins && corsOrigins.length > 0 ? corsOrigins : true,
    credentials: true,
  }),
);

await initDb();
await initUsers();

/**
 * ROTA PRINCIPAL
 */
app.get("/", (_req, res) => {
  res.send("API APP_CHAMADA_ONIBUS funcionando 🚀");
});

/**
 * MOCK LOCAL
 */
const mockChamadas = [
  {
    id: "1",
    turma: "ADS 3º",
    data: "2026-05-13",
    presentes: 28,
  },
  {
    id: "2",
    turma: "SI 2º",
    data: "2026-05-12",
    presentes: 22,
  },
];

/**
 * HEALTH CHECK
 */
app.get("/health", async (_req, res) => {
  const payload = {
    ok: true,
    service: "api-chamada",
    time: new Date().toISOString(),
    database: isDbEnabled() ? "unknown" : "disabled",
  };

  if (isDbEnabled()) {
    try {
      await pingDb();
      payload.database = "ok";
    } catch (e) {
      payload.database = "error";
      payload.databaseError = String(e?.message ?? e);
      payload.ok = false;
    }
  }

  res.json(payload);
});

/**
 * AUTENTICAÇÃO
 */
app.post("/api/auth/register", async (req, res) => {
  const body = req.body ?? {};
  const perfil = body.perfil === "motorista" ? "motorista" : "aluno";

  try {
    const user = await registerUser({
      perfil,
      identificador: body.identificador,
      senha: body.senha,
      nome: body.nome,
      email: body.email,
      telefone: body.telefone,
    });

    const token = signToken({
      sub: user.id,
      perfil: user.perfil,
      identificador: user.identificador,
      nome: user.nome,
    });

    return res.status(201).json({
      token,
      user: {
        id: user.id,
        perfil: user.perfil,
        identificador: user.identificador,
        nome: user.nome,
        email: user.email,
        telefone: user.telefone,
      },
      storage: authStorageHint(),
    });
  } catch (e) {
    const msg = String(e?.message ?? e);
    const status =
      msg.includes("já cadastrado") || msg.includes("inválid") ? 400 : 500;
    return res.status(status).json({ error: msg });
  }
});

app.post("/api/auth/login", async (req, res) => {
  const body = req.body ?? {};
  const perfil = body.perfil === "motorista" ? "motorista" : "aluno";

  try {
    const user = await loginUser({
      perfil,
      identificador: body.identificador,
      senha: body.senha,
    });

    const token = signToken({
      sub: user.id,
      perfil: user.perfil,
      identificador: user.identificador,
      nome: user.nome,
    });

    return res.json({
      token,
      user: {
        id: user.id,
        perfil: user.perfil,
        identificador: user.identificador,
        nome: user.nome,
        email: user.email,
        telefone: user.telefone,
      },
      storage: authStorageHint(),
    });
  } catch (e) {
    const msg = String(e?.message ?? e);
    const status = msg.includes("credenciais") ? 401 : 500;
    return res.status(status).json({ error: msg });
  }
});

app.get("/api/auth/me", requireAuth, (req, res) => {
  res.json({ user: req.user });
});

/**
 * LISTAR CHAMADAS
 */
app.get("/api/chamadas", requireAuth, async (_req, res) => {
  try {
    if (isDbEnabled()) {
      const rows = await listChamadas();

      return res.json({
        items: rows ?? [],
      });
    }

    res.json({
      items: mockChamadas,
    });
  } catch (e) {
    res.status(500).json({
      error: String(e?.message ?? e),
    });
  }
});

/**
 * CRIAR CHAMADA
 */
app.post("/api/chamadas", requireAuth, async (req, res) => {
  const { turma, presentes } = req.body ?? {};

  if (!turma) {
    return res.status(400).json({
      error: "campo turma é obrigatório",
    });
  }

  const id = String(Date.now());

  const data = new Date()
    .toISOString()
    .slice(0, 10);

  const n = Number(presentes) || 0;

  const row = {
    id,
    turma,
    data,
    presentes: n,
  };

  try {
    if (isDbEnabled()) {
      await insertChamada(row);
    }

    res.status(201).json(row);
  } catch (e) {
    res.status(500).json({
      error: String(e?.message ?? e),
    });
  }
});

/**
 * CHAT IA
 */
app.post("/api/ia/chat", async (req, res) => {
  const { messages, context } = req.body ?? {};

  if (!Array.isArray(messages) || messages.length === 0) {
    return res.status(400).json({
      error: "messages (array não vazio) é obrigatório",
    });
  }

  const safeMessages = messages
    .filter(
      (m) =>
        m &&
        (m.role === "user" || m.role === "assistant"),
    )
    .map((m) => ({
      role: m.role,
      content: String(m.content ?? "").slice(0, 12000),
    }))
    .filter((m) => m.content.length > 0)
    .slice(-24);

  if (safeMessages.length === 0) {
    return res.status(400).json({
      error: "nenhuma mensagem válida",
    });
  }

  const ctx =
    context != null
      ? String(context).slice(0, 14000)
      : "";

  const system = [
    "Você é assistente do app Chamada (transporte escolar/faculdade no Brasil).",
    "Responda em português do Brasil, de forma clara e objetiva.",
    ctx
      ? `Dados de contexto do app (texto/relatório):\n${ctx}`
      : "",
  ]
    .filter(Boolean)
    .join("\n\n");

  const apiKey = process.env.GROQ_API_KEY?.trim();

  const modelName =
    process.env.GROQ_MODEL || "llama-3.3-70b-versatile";

  if (!apiKey) {
    const last =
      safeMessages[safeMessages.length - 1]?.content ?? "";

    return res.json({
      reply:
        "[Sem GROQ_API_KEY no servidor] " +
        "Defina GROQ_API_KEY no Render para ativar IA real.\n\n" +
        "Mensagem recebida:\n" +
        last.slice(0, 500),
      mock: true,
    });
  }

  try {
    const client = new OpenAI({
      apiKey,
      baseURL: "https://api.groq.com/openai/v1",
    });

    const completion = await client.chat.completions.create({
      model: modelName,
      messages: [
        { role: "system", content: system },
        ...safeMessages.map((m) => ({
          role: m.role,
          content: m.content,
        })),
      ],
      temperature: 0.7,
      max_tokens: 1024,
    });

    const reply = completion.choices?.[0]?.message?.content;

    if (!reply) {
      return res.status(502).json({
        error: "resposta vazia da IA",
      });
    }

    return res.json({
      reply,
      mock: false,
    });
  } catch (e) {
    return res.status(500).json({
      error: String(e?.message ?? e),
    });
  }
});

/**
 * 404
 */
app.use((_req, res) => {
  res.status(404).json({
    error: "não encontrado",
  });
});

/**
 * START SERVER
 */
app.listen(PORT, "0.0.0.0", () => {
  console.log(
    `API ouvindo em http://0.0.0.0:${PORT}`,
  );
});