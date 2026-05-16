import express from "express";
import cors from "cors";
import { GoogleGenerativeAI } from "@google/generative-ai";

import {
  initDb,
  insertChamada,
  isDbEnabled,
  listChamadas,
  pingDb,
} from "./db.js";

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
 * LISTAR CHAMADAS
 */
app.get("/api/chamadas", async (_req, res) => {
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
app.post("/api/chamadas", async (req, res) => {
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

  const apiKey = process.env.GEMINI_API_KEY?.trim();

  const modelName =
    process.env.GEMINI_MODEL || "gemini-1.5-flash";

  /**
   * MODO MOCK
   */
  if (!apiKey) {
    const last =
      safeMessages[safeMessages.length - 1]
        ?.content ?? "";

    return res.json({
      reply:
        "[Sem GEMINI_API_KEY no servidor] " +
        "Defina GEMINI_API_KEY no Render (Google AI Studio) para ativar IA real.\n\n" +
        "Mensagem recebida:\n" +
        last.slice(0, 500),
      mock: true,
    });
  }

  try {
    const genAI = new GoogleGenerativeAI(apiKey);

    const geminiModel = genAI.getGenerativeModel({
      model: modelName,
      systemInstruction: system,
    });

    const history = safeMessages
      .slice(0, -1)
      .map((m) => ({
        role:
          m.role === "assistant"
            ? "model"
            : "user",
        parts: [
          {
            text: m.content,
          },
        ],
      }));

    const last = safeMessages[safeMessages.length - 1];

    let result;

    if (last && last.role === "user") {
      const chat = geminiModel.startChat({
        history,
      });

      result = await chat.sendMessage(last.content);
    } else {
      const bloco = safeMessages
        .map(
          (m) =>
            `${m.role}: ${m.content}`,
        )
        .join("\n\n");

      result = await geminiModel.generateContent(
        `Continue conforme o contexto.\n\n${bloco}`,
      );
    }

    const reply = result.response.text();

    if (!reply) {
      return res.status(502).json({
        error: "resposta vazia do modelo",
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