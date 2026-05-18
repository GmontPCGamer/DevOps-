const express   = require('express')
const router    = express.Router()
const despachos = require('../data/despachos.data')

// GET /api/v1/despachos  → listar todos
router.get('/', (_req, res) => {
  res.json({ total: despachos.length, data: despachos })
})

// GET /api/v1/despachos/:id  → buscar por id
router.get('/:id', (req, res) => {
  const despacho = despachos.find(d => d.id === Number(req.params.id))
  if (!despacho) return res.status(404).json({ error: 'Despacho no encontrado' })
  res.json(despacho)
})

// GET /api/v1/despachos/venta/:ventaId  → despacho por ventaId
router.get('/venta/:ventaId', (req, res) => {
  const despacho = despachos.find(d => d.ventaId === Number(req.params.ventaId))
  if (!despacho) return res.status(404).json({ error: 'No hay despacho para esa venta' })
  res.json(despacho)
})

// POST /api/v1/despachos  → crear nuevo despacho
router.post('/', (req, res) => {
  const { ventaId, direccion, transportista } = req.body

  if (!ventaId || !direccion) {
    return res.status(400).json({ error: 'Campos requeridos: ventaId, direccion' })
  }

  const nuevoDespacho = {
    id          : despachos.length + 1,
    ventaId     : Number(ventaId),
    estado      : 'pendiente',
    direccion,
    transportista: transportista || null,
    fechaEnvio  : null,
    fechaEntrega: null
  }

  despachos.push(nuevoDespacho)
  res.status(201).json(nuevoDespacho)
})

// PATCH /api/v1/despachos/:id/estado  → actualizar estado
router.patch('/:id/estado', (req, res) => {
  const despacho = despachos.find(d => d.id === Number(req.params.id))
  if (!despacho) return res.status(404).json({ error: 'Despacho no encontrado' })

  const estadosValidos = ['pendiente', 'en_tránsito', 'entregado']
  const { estado } = req.body

  if (!estadosValidos.includes(estado)) {
    return res.status(400).json({ error: `Estado inválido. Válidos: ${estadosValidos.join(', ')}` })
  }

  despacho.estado = estado
  if (estado === 'en_tránsito') despacho.fechaEnvio   = new Date().toISOString().split('T')[0]
  if (estado === 'entregado')   despacho.fechaEntrega = new Date().toISOString().split('T')[0]

  res.json(despacho)
})

module.exports = router
