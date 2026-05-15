require('dotenv').config()
const express = require('express')
const cors = require('cors')

const ventasRouter    = require('./routes/ventas.routes')
const despachosRouter = require('./routes/despachos.routes')

const app  = express()
const PORT = process.env.PORT || 3000

// ── Middlewares ────────────────────────────────────────────────────────────────
app.use(cors())
app.use(express.json())

// ── Health check ───────────────────────────────────────────────────────────────
app.get('/health', (_req, res) => {
  res.json({
    status : 'ok',
    service: 'api-innovatech',
    version: '1.0.0',
    timestamp: new Date().toISOString()
  })
})

// ── Rutas ──────────────────────────────────────────────────────────────────────
app.use('/api/v1/ventas',    ventasRouter)
app.use('/api/v1/despachos', despachosRouter)

// ── 404 handler ────────────────────────────────────────────────────────────────
app.use((_req, res) => {
  res.status(404).json({ error: 'Ruta no encontrada' })
})

// ── Error handler global ───────────────────────────────────────────────────────
app.use((err, _req, res, _next) => {
  console.error('[ERROR]', err.message)
  res.status(500).json({ error: 'Error interno del servidor' })
})

// ── Iniciar servidor ───────────────────────────────────────────────────────────
app.listen(PORT, () => {
  console.log(`✅  API Innovatech corriendo en http://localhost:${PORT}`)
  console.log(`🔗  Entorno: ${process.env.NODE_ENV || 'development'}`)
})
