require('dotenv').config();
const express = require('express');
const jwt = require('jsonwebtoken');
const { Pool } = require('pg');
const path = require('path');

const app = express();
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, 'public')));

// ─── Conexión PostgreSQL RDS ───────────────────────────────────────────────
const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  ssl: { rejectUnauthorized: false }
});

// Verificar conexión al iniciar
pool.connect((err, client, release) => {
  if (err) {
    console.error('❌ Error conectando a RDS:', err.message);
  } else {
    console.log('✅ Conexión exitosa a AWS RDS PostgreSQL');
    release();
  }
});

// ─── Middleware: verificar token JWT ──────────────────────────────────────
function authMiddleware(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Acceso denegado. Token requerido.' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;
    next();
  } catch (err) {
    return res.status(403).json({ error: 'Token inválido o expirado.' });
  }
}

// ─── RUTAS PÚBLICAS ────────────────────────────────────────────────────────

// Página principal → sirve index.html
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Login → genera token JWT
app.post('/login', (req, res) => {
  const { username, password } = req.body;

  if (!username || !password) {
    return res.status(400).json({ error: 'Usuario y contraseña requeridos.' });
  }

  if (username === 'admin' && password === process.env.ADMIN_PASSWORD) {
    const token = jwt.sign(
      { user: username, rol: 'administrador' },
      process.env.JWT_SECRET,
      { expiresIn: '2h' }
    );
    console.log(`🔐 Login exitoso: ${username} - ${new Date().toISOString()}`);
    return res.json({
      mensaje: 'Autenticación exitosa',
      token,
      usuario: username,
      expira: '2 horas'
    });
  }

  console.warn(`⚠️  Intento de login fallido: ${username} - ${new Date().toISOString()}`);
  return res.status(401).json({ error: 'Credenciales inválidas.' });
});

// ─── RUTAS PROTEGIDAS (requieren token) ───────────────────────────────────

// Dashboard → verifica conexión RDS
app.get('/dashboard', authMiddleware, async (req, res) => {
  try {
    const result = await pool.query('SELECT NOW() AS hora_servidor, version() AS version_pg');
    res.json({
      mensaje: '✅ Conexión RDS activa',
      usuario: req.user.user,
      hora_servidor: result.rows[0].hora_servidor,
      version_postgresql: result.rows[0].version_pg
    });
  } catch (err) {
    console.error('❌ Error en query RDS:', err.message);
    res.status(500).json({ error: 'Error conectando a la base de datos.', detalle: err.message });
  }
});

// Crear tabla de prueba en RDS
app.post('/init-db', authMiddleware, async (req, res) => {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS acme_log (
        id SERIAL PRIMARY KEY,
        evento VARCHAR(255),
        usuario VARCHAR(100),
        fecha TIMESTAMP DEFAULT NOW()
      )
    `);
    await pool.query(
      'INSERT INTO acme_log (evento, usuario) VALUES ($1, $2)',
      ['Sistema inicializado', req.user.user]
    );
    res.json({ mensaje: '✅ Tabla acme_log creada e inicializada en RDS.' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Ver logs desde RDS
app.get('/logs', authMiddleware, async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM acme_log ORDER BY fecha DESC LIMIT 20');
    res.json({ logs: result.rows, total: result.rowCount });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Health check
app.get('/health', (req, res) => {
  res.json({ estado: 'OK', servicio: 'ACME ERP Frontend', timestamp: new Date() });
});

// ─── INICIO SERVIDOR ───────────────────────────────────────────────────────
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 ACME ERP corriendo en http://localhost:${PORT}`);
  console.log(`📦 BD: ${process.env.DB_HOST}`);
  console.log(`🪣 S3: ${process.env.AWS_BUCKET}`);
});
