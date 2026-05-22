const express = require('express');
const cors    = require('cors');
const db      = require('./database');
require('dotenv').config();

const app = express();

app.use(express.json());

// CORS: permite requisições do frontend (ajuste a origin em produção)
app.use(cors({
  origin: process.env.FRONTEND_ORIGIN || '*',
}));


app.get('/clientes', async (req, res) => {
  try {
    const [results] = await db.query('SELECT * FROM CLIENTE');
    res.json(results);
  } catch (err) {
    console.error('Erro em GET /clientes:', err.message);
    res.status(500).json({ erro: 'Erro ao buscar clientes.' });
  }
});

// ─── COMPUTADORES ─────────────────────────────────────────────────────────────

// Listar computadores disponíveis
app.get('/pcs-disponiveis', async (req, res) => {
  try {
    const [results] = await db.query(
      "SELECT * FROM COMPUTADOR WHERE STATUS = 'DISPONÍVEL'"
    );
    res.json(results);
  } catch (err) {
    console.error('Erro em GET /pcs-disponiveis:', err.message);
    res.status(500).json({ erro: 'Erro ao buscar computadores.' });
  }
});

// Listar todos os computadores (para o grid completo com status)
app.get('/computadores', async (req, res) => {
  try {
    const [results] = await db.query('SELECT * FROM COMPUTADOR');
    res.json(results);
  } catch (err) {
    console.error('Erro em GET /computadores:', err.message);
    res.status(500).json({ erro: 'Erro ao buscar computadores.' });
  }
});

// ─── SESSÕES ──────────────────────────────────────────────────────────────────

// Contagem de sessões ativas (alimenta o painel lateral)
app.get('/sessoes-ativas', async (req, res) => {
  try {
    const [result] = await db.query(
      "SELECT COUNT(*) AS total FROM SESSAO WHERE STATUS = 'ATIVA'"
    );
    res.json(result[0]);
  } catch (err) {
    console.error('Erro em GET /sessoes-ativas:', err.message);
    res.status(500).json({ erro: 'Erro ao buscar sessões ativas.' });
  }
});

// ─── SERVIDOR ─────────────────────────────────────────────────────────────────

const PORT = process.env.PORT || 8080;
app.listen(PORT, () => {
  console.log(`🚀 Servidor rodando em http://localhost:${PORT}`);
});
